#!/usr/bin/env python3
"""
GTD Vector Initial Scan
Scans all existing files in configured directories and queues them for vectorization.

This is useful for:
- Initial setup when starting vectorization
- Repopulating the queue after it's been cleared
- Re-queuing files that may have been missed
"""

import os
import sys
from pathlib import Path
from typing import Dict, List

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))

# Ensure we can import pika (for RabbitMQ)
# If running from system Python without pika, warn user
try:
    import pika
except ImportError:
    # Check if we're in a virtualenv that might have pika
    venv_python = Path(__file__).parent / "venv" / "bin" / "python3"
    if venv_python.exists():
        print("⚠️  Warning: pika not found in current Python environment")
        print(f"   This script should be run via: {venv_python} {Path(__file__)}")
        print("   Or use the wrapper: gtd-vector-scan-existing")
        print("")
        print("   Attempting to continue (will fall back to file queue if RabbitMQ enabled)...")
    else:
        print("⚠️  Warning: pika not installed. RabbitMQ queuing will not work.")
        print("   Install with: pip install pika")
        print("   Or use virtualenv: ~/code/dotfiles/mcp/venv/bin/pip install pika")

try:
    from gtd_vectorization import queue_vectorization
    from gtd_vector_db import read_database_config
except ImportError as e:
    print(f"Error importing vectorization modules: {e}")
    print("Make sure you're running from the correct directory")
    sys.exit(1)

# Import config loading from filewatcher (if available)
# Otherwise define it here
try:
    # Try to import from filewatcher module
    sys.path.insert(0, str(Path(__file__).parent))
    from gtd_vector_filewatcher import load_config, expand_symlinks
except (ImportError, ModuleNotFoundError):
    # Fallback: define config loading here
    def load_config() -> Dict:
        """Load configuration from config files."""
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
            "base_dirs": watch_dirs,
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


class FileScanner:
    """Scans existing files and queues them for vectorization."""
    
    def __init__(self, config: Dict):
        self.config = config
        self.supported_extensions = {".md", ".txt", ".markdown"}
        self.ignored_patterns = config.get("ignored_patterns", [])
        self.content_type_mapping = config.get("content_type_mapping", {})
        self.base_dirs = config.get("base_dirs", [])
        self.queued_count = 0
        self.skipped_count = 0
        self.error_count = 0
    
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
        import hashlib
        
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
    
    def _queue_file(self, file_path: Path) -> bool:
        """Queue a file for vectorization."""
        if not self._should_process(file_path):
            return False
        
        try:
            # Read file content
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            if not content.strip():
                self.skipped_count += 1
                return False  # Skip empty files
            
            # Determine content type and ID
            content_type = self._get_content_type(file_path)
            content_id = self._get_content_id(file_path)
            
            # Create metadata
            from datetime import datetime
            metadata = {
                "file_path": str(file_path),
                "file_name": file_path.name,
                "file_size": file_path.stat().st_size,
                "modified_time": datetime.fromtimestamp(file_path.stat().st_mtime).isoformat(),
            }
            
            # Queue for vectorization
            status = queue_vectorization(
                content_type=content_type,
                content_id=content_id,
                content_text=content,
                metadata=metadata
            )
            
            if status.startswith("queued"):
                self.queued_count += 1
                # Show where it was queued (RabbitMQ vs file)
                queue_type = "RabbitMQ" if status == "queued_to_rabbitmq" else "file queue"
                print(f"📄 Queued to {queue_type}: {content_type}:{content_id} ({file_path.name})")
                return True
            else:
                self.error_count += 1
                print(f"⚠️  Failed to queue {file_path.name}: {status}")
                return False
                
        except Exception as e:
            self.error_count += 1
            print(f"❌ Error processing {file_path}: {e}")
            return False
    
    def scan_directory(self, directory: Path, recursive: bool = True) -> List[Path]:
        """Scan a directory for files to process."""
        files = []
        
        if not directory.exists() or not directory.is_dir():
            return files
        
        try:
            if recursive:
                pattern = "**/*"
            else:
                pattern = "*"
            
            for item in directory.glob(pattern):
                if item.is_file() and self._should_process(item):
                    files.append(item)
        except (PermissionError, OSError) as e:
            print(f"⚠️  Error scanning {directory}: {e}")
        
        return files
    
    def scan_all(self, directories: List[str]) -> None:
        """Scan all directories and queue files."""
        all_files = []
        
        print("🔍 Scanning directories for files...")
        print("")
        
        for directory_str in directories:
            directory = Path(directory_str)
            if not directory.exists():
                print(f"⚠️  Skipping (doesn't exist): {directory}")
                continue
            
            print(f"📂 Scanning: {directory}")
            files = self.scan_directory(directory, recursive=self.config.get("recursive", True))
            all_files.extend(files)
            print(f"   Found {len(files)} file(s)")
        
        print("")
        print(f"📋 Total files found: {len(all_files)}")
        print("")
        print("📤 Queuing files for vectorization...")
        print("")
        
        # Queue all files
        for file_path in all_files:
            self._queue_file(file_path)
        
        # Print summary
        print("")
        print("=" * 60)
        print("📊 Scan Summary")
        print("=" * 60)
        print(f"✅ Queued: {self.queued_count}")
        print(f"⏭️  Skipped: {self.skipped_count}")
        print(f"❌ Errors: {self.error_count}")
        print(f"📁 Total: {len(all_files)}")
        print("")


def main():
    """Main scan function."""
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
        print("❌ No directories to scan")
        print("   Set VECTOR_WATCH_DIRS or check GTD_BASE_DIR and DAILY_LOG_DIR")
        sys.exit(1)
    
    print("📁 GTD Vector Initial Scan")
    print("=" * 60)
    print("")
    print("Scanning directories:")
    for directory in watch_dirs:
        print(f"  📂 {directory}")
    print("")
    print("File types: .md, .txt, .markdown")
    print("")
    
    # Create scanner and scan
    scanner = FileScanner(config)
    scanner.scan_all(watch_dirs)
    
    print("✅ Scan complete!")
    print("")
    print("💡 Tip: Start the vectorization worker to process queued files:")
    print("   make worker-vector-start")
    print("   # or")
    print("   gtd-vector-worker")


if __name__ == "__main__":
    main()
