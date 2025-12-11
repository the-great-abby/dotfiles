#!/usr/bin/env python3
"""
GTD Vector Filewatcher
Monitors directories and automatically queues files for vectorization.

This watches for new/modified files in configured directories (including symlinks)
and automatically queues them for vectorization.
"""

import os
import sys
import json
import time
import hashlib
from pathlib import Path
from typing import Dict, Set, Optional
from datetime import datetime

try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler, FileSystemEvent
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))

try:
    from gtd_vectorization import queue_vectorization
    from gtd_vector_db import read_database_config
except ImportError as e:
    print(f"Error importing vectorization modules: {e}")
    print("Make sure you're running from the correct directory")
    sys.exit(1)


class VectorizationEventHandler(FileSystemEventHandler):
    """Handles file system events and queues files for vectorization."""
    
    def __init__(self, config: Dict):
        self.config = config
        self.processed_files: Set[str] = set()  # Track processed files to avoid duplicates
        self.debounce_time = config.get("debounce_seconds", 2)  # Wait 2 seconds after file change
        self.file_timers: Dict[str, float] = {}  # Track when files were last modified
        self.supported_extensions = {".md", ".txt", ".markdown"}
        self.ignored_patterns = config.get("ignored_patterns", [
            "*.jsonl", "*.log", "*.tmp", "*~", ".*",  # Queue files, logs, temp files
        ])
        self.content_type_mapping = config.get("content_type_mapping", {})
        self.base_dirs = config.get("base_dirs", [])
        
    def _should_process(self, file_path: Path) -> bool:
        """Check if file should be processed."""
        # Check extension
        if file_path.suffix.lower() not in self.supported_extensions:
            return False
        
        # Check ignored patterns
        filename = file_path.name
        for pattern in self.ignored_patterns:
            if pattern.startswith("*."):
                ext = pattern[1:]
                if filename.endswith(ext):
                    return False
            elif pattern.startswith("*"):
                if filename.endswith(pattern[1:]):
                    return False
            elif filename == pattern or filename.startswith(pattern):
                return False
        
        # Ignore hidden files
        if filename.startswith("."):
            return False
        
        # Check if file exists and is readable
        if not file_path.exists() or not file_path.is_file():
            return False
        
        return True
    
    def _get_content_type(self, file_path: Path) -> str:
        """Determine content type from file path."""
        file_path_str = str(file_path)
        
        # Check mapping first
        for pattern, content_type in self.content_type_mapping.items():
            if pattern in file_path_str:
                return content_type
        
        # Default based on directory
        if "daily_log" in file_path_str or "daily_logs" in file_path_str:
            return "daily_log"
        elif "task" in file_path_str or "/tasks/" in file_path_str:
            return "task"
        elif "project" in file_path_str or "/projects/" in file_path_str:
            return "project"
        elif "zettel" in file_path_str or "notes" in file_path_str:
            return "note"
        else:
            return "document"
    
    def _get_content_id(self, file_path: Path) -> str:
        """Generate content ID from file path."""
        # Use relative path from base directory or full path hash
        for base_dir in self.base_dirs:
            try:
                base_path = Path(base_dir).resolve()
                file_path_resolved = file_path.resolve()
                if str(file_path_resolved).startswith(str(base_path)):
                    rel_path = file_path_resolved.relative_to(base_path)
                    # Use relative path as ID (replace / with -)
                    return str(rel_path).replace("/", "-").replace("\\", "-")
            except (ValueError, OSError):
                continue
        
        # Fallback: use hash of path
        path_str = str(file_path.resolve())
        return hashlib.md5(path_str.encode()).hexdigest()[:16]
    
    def _queue_file(self, file_path: Path):
        """Queue a file for vectorization."""
        if not self._should_process(file_path):
            return
        
        try:
            # Read file content
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            if not content.strip():
                return  # Skip empty files
            
            # Determine content type and ID
            content_type = self._get_content_type(file_path)
            content_id = self._get_content_id(file_path)
            
            # Create metadata
            metadata = {
                "file_path": str(file_path),
                "file_name": file_path.name,
                "file_size": file_path.stat().st_size,
                "modified_time": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
            }
            
            # Queue for vectorization
            print(f"📄 Queuing: {content_type}:{content_id} ({file_path.name})")
            status = queue_vectorization(
                content_type=content_type,
                content_id=content_id,
                content_text=content,
                metadata=metadata
            )
            
            if status.startswith("queued"):
                print(f"   ✅ {status}")
            else:
                print(f"   ⚠️  {status}")
                
        except Exception as e:
            print(f"   ❌ Error processing {file_path}: {e}")
    
    def on_modified(self, event: FileSystemEvent):
        """Handle file modification events."""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        self._schedule_processing(file_path)
    
    def on_created(self, event: FileSystemEvent):
        """Handle file creation events."""
        if event.is_directory:
            return
        
        file_path = Path(event.src_path)
        self._schedule_processing(file_path)
    
    def _schedule_processing(self, file_path: Path):
        """Schedule file processing with debounce."""
        path_str = str(file_path.resolve())
        current_time = time.time()
        
        # Update timer
        self.file_timers[path_str] = current_time
        
        # Process after debounce delay
        def process_after_delay():
            time.sleep(self.debounce_time)
            # Check if file was modified again during debounce
            if path_str in self.file_timers:
                timer_time = self.file_timers[path_str]
                if current_time >= timer_time:  # No new modifications
                    if file_path.exists():
                        self._queue_file(file_path)
                    del self.file_timers[path_str]
        
        import threading
        thread = threading.Thread(target=process_after_delay, daemon=True)
        thread.start()


def load_config() -> Dict:
    """Load configuration from config files."""
    config_paths = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_database",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config_database",
        Path.home() / ".gtd_config_database",
    ]
    
    db_config = read_database_config()
    
    # Default directories to watch
    gtd_base = os.getenv("GTD_BASE_DIR", str(Path.home() / "Documents" / "gtd"))
    daily_log_dir = os.getenv("DAILY_LOG_DIR", str(Path.home() / "Documents" / "daily_logs"))
    
    watch_dirs = [gtd_base, daily_log_dir]
    
    # Check for symlinks in a watch directory
    watch_dir_config = os.getenv("VECTOR_WATCH_DIRS", "")
    if watch_dir_config:
        watch_dirs.extend([d.strip() for d in watch_dir_config.split(",") if d.strip()])
    
    config = {
        "watch_directories": watch_dirs,
        "base_dirs": watch_dirs,  # For generating content IDs
        "debounce_seconds": 2,
        "ignored_patterns": [
            "*.jsonl", "*.log", "*.tmp", "*~", ".*",
            "deep_analysis_queue.jsonl",
            "vectorization_queue.jsonl",
        ],
        "content_type_mapping": {
            "daily_logs": "daily_log",
            "tasks": "task",
            "projects": "project",
            "zettel": "note",
            "notes": "note",
        },
        "recursive": True,
    }
    
    return config


def expand_symlinks(directories: list) -> list:
    """Expand directories, following symlinks."""
    expanded = []
    seen = set()
    
    for directory in directories:
        if not directory:
            continue
        
        dir_path = Path(directory).expanduser().resolve()
        
        if not dir_path.exists():
            print(f"⚠️  Directory does not exist: {directory}")
            continue
        
        # Add the directory itself
        dir_str = str(dir_path)
        if dir_str not in seen:
            expanded.append(dir_str)
            seen.add(dir_str)
        
        # If recursive, also follow symlinks within the directory
        if dir_path.is_dir():
            try:
                # Find symlinks within directory
                for item in dir_path.rglob("*"):
                    if item.is_symlink() and item.is_dir():
                        target = item.resolve()
                        target_str = str(target)
                        if target_str not in seen and target.is_dir():
                            expanded.append(target_str)
                            seen.add(target_str)
                            print(f"🔗 Following symlink: {item.name} → {target_str}")
            except (PermissionError, OSError) as e:
                print(f"⚠️  Error scanning {dir_path}: {e}")
    
    return expanded


def main():
    """Main filewatcher loop."""
    if not WATCHDOG_AVAILABLE:
        print("❌ Error: watchdog library not installed")
        print("   Install with: pip install watchdog")
        print("   Or in virtualenv: $HOME/code/dotfiles/mcp/venv/bin/pip install watchdog")
        sys.exit(1)
    
    config = load_config()
    
    # Check if vectorization is enabled
    db_config = read_database_config()
    if not db_config.get("vectorization_enabled", True):
        print("⚠️  Vectorization is disabled in config")
        print("   Set GTD_VECTORIZATION_ENABLED=true to enable")
        sys.exit(1)
    
    # Expand directories (including symlinks)
    watch_dirs = expand_symlinks(config["watch_directories"])
    
    if not watch_dirs:
        print("❌ No directories to watch")
        print("   Set VECTOR_WATCH_DIRS or check GTD_BASE_DIR and DAILY_LOG_DIR")
        sys.exit(1)
    
    print("📁 GTD Vector Filewatcher")
    print("=" * 60)
    print("")
    print("Watching directories:")
    for directory in watch_dirs:
        print(f"  📂 {directory}")
    print("")
    print("File types: .md, .txt, .markdown")
    print("Press Ctrl+C to stop")
    print("")
    
    # Create event handler
    event_handler = VectorizationEventHandler(config)
    
    # Create observer
    observer = Observer()
    
    # Schedule watching for each directory
    for directory in watch_dirs:
        dir_path = Path(directory)
        if dir_path.exists() and dir_path.is_dir():
            observer.schedule(event_handler, str(dir_path), recursive=config.get("recursive", True))
            print(f"✅ Watching: {directory}")
        else:
            print(f"⚠️  Skipping (doesn't exist): {directory}")
    
    # Start observing
    observer.start()
    
    try:
        # Keep running
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("")
        print("Stopping filewatcher...")
        observer.stop()
    
    observer.join()
    print("✅ Filewatcher stopped")


if __name__ == "__main__":
    main()
