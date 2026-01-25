#!/usr/bin/env python3
"""
GTD Coordination System - Prevents duplicate operations between frontend TUI and background workers

This module provides coordination mechanisms to prevent duplicate task creation,
project processing, and other GTD operations when both the interactive TUI and
background workers might process the same data.

Key coordination strategies:
1. Operation locking (file-based locks)
2. Content fingerprinting (detect already-processed content)
3. Source tracking (track who created what)
4. Deduplication checks (prevent duplicate tasks)
"""

import json
import time
import hashlib
from pathlib import Path
from typing import Optional, Dict, List, Set, Any
from datetime import datetime, timezone
import fcntl
import os

# GTD coordination directories
GTD_BASE = Path.home() / "Documents" / "gtd"
COORDINATION_DIR = GTD_BASE / ".coordination"
LOCKS_DIR = COORDINATION_DIR / "locks"
PROCESSED_DIR = COORDINATION_DIR / "processed"
SOURCES_DIR = COORDINATION_DIR / "sources"

# Ensure directories exist
COORDINATION_DIR.mkdir(parents=True, exist_ok=True)
LOCKS_DIR.mkdir(exist_ok=True)
PROCESSED_DIR.mkdir(exist_ok=True)
SOURCES_DIR.mkdir(exist_ok=True)

class GTDCoordination:
    """Coordination system for preventing conflicts between TUI and background workers."""
    
    def __init__(self, source: str = "unknown"):
        """Initialize coordination system.
        
        Args:
            source: Identifier for the system making calls ("tui", "worker", "advice", etc.)
        """
        self.source = source
        self.active_locks = []
    
    def create_content_fingerprint(self, content: str, content_type: str = "general") -> str:
        """Create a unique fingerprint for content to detect duplicates.
        
        Args:
            content: The content to fingerprint
            content_type: Type of content (daily_log, meeting_notes, project, etc.)
            
        Returns:
            Unique fingerprint string
        """
        # Normalize content for consistent fingerprinting
        normalized = content.strip().lower()
        content_hash = hashlib.sha256(normalized.encode()).hexdigest()[:16]
        return f"{content_type}_{content_hash}"
    
    def is_content_processed(self, content: str, operation: str, content_type: str = "general") -> bool:
        """Check if content has already been processed for a specific operation.
        
        Args:
            content: Content to check
            operation: Operation type (task_creation, project_breakdown, etc.)
            content_type: Type of content
            
        Returns:
            True if already processed, False otherwise
        """
        fingerprint = self.create_content_fingerprint(content, content_type)
        processed_file = PROCESSED_DIR / f"{operation}_{fingerprint}.json"
        
        if processed_file.exists():
            # Check if processing was recent (within last hour for safety)
            try:
                with open(processed_file) as f:
                    data = json.load(f)
                processed_time = datetime.fromisoformat(data.get("processed_at", ""))
                age_hours = (datetime.now(timezone.utc) - processed_time).total_seconds() / 3600
                
                # If processed within last hour, consider it duplicate
                if age_hours < 1.0:
                    print(f"🛑 Content already processed by {data.get('source', 'unknown')} "
                          f"{age_hours:.1f} hours ago")
                    return True
            except Exception as e:
                print(f"⚠️  Error checking processed content: {e}")
        
        return False
    
    def mark_content_processed(self, content: str, operation: str, content_type: str = "general", 
                             results: Optional[Dict] = None):
        """Mark content as processed to prevent duplicate operations.
        
        Args:
            content: Content that was processed
            operation: Operation that was performed
            content_type: Type of content
            results: Optional results/metadata from processing
        """
        fingerprint = self.create_content_fingerprint(content, content_type)
        processed_file = PROCESSED_DIR / f"{operation}_{fingerprint}.json"
        
        data = {
            "fingerprint": fingerprint,
            "operation": operation,
            "content_type": content_type,
            "source": self.source,
            "processed_at": datetime.now(timezone.utc).isoformat(),
            "content_preview": content[:200] + "..." if len(content) > 200 else content,
            "results": results or {}
        }
        
        try:
            with open(processed_file, 'w') as f:
                json.dump(data, f, indent=2)
        except Exception as e:
            print(f"⚠️  Error marking content as processed: {e}")
    
    def acquire_operation_lock(self, operation: str, resource: str = "global", 
                             timeout: float = 30.0) -> bool:
        """Acquire an exclusive lock for an operation on a resource.
        
        Args:
            operation: Operation name (task_creation, log_processing, etc.)
            resource: Resource identifier (daily_log_2025-01-24, project_xyz, etc.)
            timeout: Maximum time to wait for lock
            
        Returns:
            True if lock acquired, False if timeout
        """
        lock_name = f"{operation}_{resource}"
        lock_file = LOCKS_DIR / f"{lock_name}.lock"
        
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            try:
                # Try to create lock file exclusively
                fd = os.open(lock_file, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
                
                # Write lock info
                lock_info = {
                    "operation": operation,
                    "resource": resource,
                    "source": self.source,
                    "acquired_at": datetime.now(timezone.utc).isoformat(),
                    "pid": os.getpid()
                }
                os.write(fd, json.dumps(lock_info).encode())
                os.close(fd)
                
                # Track active lock for cleanup
                self.active_locks.append(lock_file)
                
                print(f"🔒 Lock acquired: {operation} on {resource}")
                return True
                
            except FileExistsError:
                # Lock exists, check if it's stale
                if self._is_stale_lock(lock_file):
                    self._remove_stale_lock(lock_file)
                    continue
                    
                # Wait a bit and retry
                time.sleep(0.1)
            except Exception as e:
                print(f"⚠️  Error acquiring lock {lock_name}: {e}")
                return False
        
        print(f"⏰ Timeout acquiring lock: {operation} on {resource}")
        return False
    
    def release_operation_lock(self, operation: str, resource: str = "global"):
        """Release an operation lock.
        
        Args:
            operation: Operation name
            resource: Resource identifier
        """
        lock_name = f"{operation}_{resource}"
        lock_file = LOCKS_DIR / f"{lock_name}.lock"
        
        try:
            if lock_file.exists():
                lock_file.unlink()
                if lock_file in self.active_locks:
                    self.active_locks.remove(lock_file)
                print(f"🔓 Lock released: {operation} on {resource}")
        except Exception as e:
            print(f"⚠️  Error releasing lock {lock_name}: {e}")
    
    def _is_stale_lock(self, lock_file: Path, max_age_minutes: int = 60) -> bool:
        """Check if a lock file is stale (older than max_age_minutes)."""
        try:
            if not lock_file.exists():
                return True
                
            # Check file age
            file_age = time.time() - lock_file.stat().st_mtime
            if file_age > max_age_minutes * 60:
                return True
            
            # Check if process is still running
            with open(lock_file) as f:
                lock_info = json.load(f)
                pid = lock_info.get("pid")
                if pid:
                    try:
                        os.kill(pid, 0)  # Check if process exists
                    except OSError:
                        return True  # Process doesn't exist
            
            return False
        except Exception:
            return True  # If we can't check, assume stale
    
    def _remove_stale_lock(self, lock_file: Path):
        """Remove a stale lock file."""
        try:
            lock_file.unlink()
            print(f"🧹 Removed stale lock: {lock_file.name}")
        except Exception as e:
            print(f"⚠️  Error removing stale lock: {e}")
    
    def cleanup_locks(self):
        """Clean up all active locks held by this instance."""
        for lock_file in self.active_locks.copy():
            try:
                if lock_file.exists():
                    lock_file.unlink()
                self.active_locks.remove(lock_file)
            except Exception as e:
                print(f"⚠️  Error cleaning up lock {lock_file}: {e}")
    
    def check_task_duplicates(self, title: str, project: Optional[str] = None, 
                            context: str = "computer") -> List[Dict]:
        """Check for existing tasks with similar titles to prevent duplicates.
        
        Args:
            title: Task title to check
            project: Project name (optional)
            context: Task context
            
        Returns:
            List of similar existing tasks
        """
        # This would integrate with the actual GTD task storage
        # For now, return empty list - implement based on your task storage
        return []
    
    def __enter__(self):
        """Context manager entry."""
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit - cleanup locks."""
        self.cleanup_locks()


# Convenience functions for common coordination patterns

def with_operation_lock(operation: str, resource: str = "global", source: str = "unknown"):
    """Decorator for functions that need operation locking."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            with GTDCoordination(source) as coord:
                if coord.acquire_operation_lock(operation, resource):
                    try:
                        return func(*args, **kwargs)
                    finally:
                        coord.release_operation_lock(operation, resource)
                else:
                    raise Exception(f"Could not acquire lock for {operation} on {resource}")
        return wrapper
    return decorator


def prevent_duplicate_processing(operation: str, content_type: str = "general", source: str = "unknown"):
    """Decorator to prevent duplicate content processing."""
    def decorator(func):
        def wrapper(*args, **kwargs):
            # Extract content from first argument (assuming it's content)
            content = args[0] if args else ""
            
            with GTDCoordination(source) as coord:
                if coord.is_content_processed(content, operation, content_type):
                    print(f"⏭️  Skipping duplicate processing: {operation}")
                    return {"status": "skipped", "reason": "already_processed"}
                
                try:
                    result = func(*args, **kwargs)
                    coord.mark_content_processed(content, operation, content_type, result)
                    return result
                except Exception as e:
                    print(f"❌ Error in {operation}: {e}")
                    raise
        return wrapper
    return decorator


# Example usage functions

@prevent_duplicate_processing("auto_task_creation", "daily_log", "worker")
def safe_auto_task_creation_from_log(log_content: str, date: str = None):
    """Safe version of auto task creation that prevents duplicates."""
    # Your actual task creation logic here
    print(f"🔄 Processing daily log for task creation: {len(log_content)} chars")
    # ... implementation ...
    return {"tasks_created": 0, "status": "completed"}


@with_operation_lock("project_breakdown", source="tui")
def safe_project_breakdown(project_name: str):
    """Safe project breakdown with locking."""
    # Your actual project breakdown logic here
    print(f"🔄 Breaking down project: {project_name}")
    # ... implementation ...
    return {"status": "completed", "tasks_created": 0}


if __name__ == "__main__":
    # Test the coordination system
    print("🧪 Testing GTD Coordination System")
    
    with GTDCoordination("test") as coord:
        # Test content fingerprinting
        content = "Today I had a meeting with John about the new project. Need to follow up by Friday."
        fp = coord.create_content_fingerprint(content, "meeting_notes")
        print(f"Fingerprint: {fp}")
        
        # Test processing tracking
        is_processed = coord.is_content_processed(content, "task_creation", "meeting_notes")
        print(f"Already processed: {is_processed}")
        
        # Test locking
        if coord.acquire_operation_lock("test_operation", "test_resource"):
            print("Lock acquired successfully")
            coord.release_operation_lock("test_operation", "test_resource")
        
        print("✅ Coordination system test completed")