#!/usr/bin/env python3
"""
GTD Dashboard Cache Worker
Maintains a cache file with dashboard statistics to speed up rendering.
"""

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional

# Configuration
CACHE_FILE = Path.home() / "Documents" / "gtd" / ".dashboard_cache.json"
CACHE_TTL = 30  # Cache is valid for 30 seconds
UPDATE_INTERVAL = 10  # Update cache every 10 seconds
LOG_FILE = Path("/tmp/dashboard-cache-worker.log")

# GTD paths (will be loaded from config)
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
INBOX_PATH = GTD_BASE_DIR / "0-inbox"
TASKS_PATH = GTD_BASE_DIR / "tasks"
PROJECTS_PATH = GTD_BASE_DIR / "1-projects"
AREAS_PATH = GTD_BASE_DIR / "2-areas"
WAITING_PATH = GTD_BASE_DIR / "4-waiting"
SOMEDAY_PATH = GTD_BASE_DIR / "5-someday"
SUGGESTIONS_DIR = GTD_BASE_DIR / "suggestions"
DAILY_LOG_DIR = Path.home() / "Documents" / "daily_logs"


def log(message: str):
    """Write to log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] {message}\n")


def load_gtd_config() -> Dict[str, str]:
    """Load GTD configuration to get paths."""
    config_paths = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / ".gtd_config",
    ]
    
    config = {}
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path, "r") as f:
                for line in f:
                    line = line.strip()
                    if "=" in line and not line.startswith("#"):
                        key, value = line.split("=", 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        config[key] = value
            break
    
    return config


def get_frontmatter_value(file_path: Path, key: str) -> str:
    """Extract frontmatter value from markdown file."""
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
            # Look for frontmatter section
            if content.startswith("---"):
                lines = content.split("\n")
                in_frontmatter = False
                for line in lines:
                    if line.strip() == "---":
                        if in_frontmatter:
                            break
                        in_frontmatter = True
                        continue
                    if in_frontmatter and line.startswith(f"{key}:"):
                        return line.split(":", 1)[1].strip()
    except Exception:
        pass
    return ""


def count_files(directory: Path, pattern: str = "*.md") -> int:
    """Count files matching pattern in directory."""
    if not directory.exists() or not directory.is_dir():
        return 0
    try:
        return len(list(directory.glob(pattern)))
    except Exception:
        return 0


def count_active_tasks(directory: Path) -> int:
    """Count active tasks in directory."""
    if not directory.exists() or not directory.is_dir():
        return 0
    
    count = 0
    try:
        for task_file in directory.rglob("*.md"):
            if task_file.name == "README.md":
                continue
            status = get_frontmatter_value(task_file, "status")
            if status == "active":
                count += 1
    except Exception:
        pass
    
    return count


def get_favorited_tasks() -> List[str]:
    """Get list of favorited task file paths."""
    favorited = []
    
    # Check tasks directory
    if TASKS_PATH.exists():
        for task_file in TASKS_PATH.glob("*.md"):
            favorite = get_frontmatter_value(task_file, "favorite")
            status = get_frontmatter_value(task_file, "status")
            if favorite == "true" and status == "active":
                favorited.append(str(task_file))
    
    # Check project directories
    if PROJECTS_PATH.exists():
        for task_file in PROJECTS_PATH.rglob("*.md"):
            if task_file.name == "README.md":
                continue
            favorite = get_frontmatter_value(task_file, "favorite")
            status = get_frontmatter_value(task_file, "status")
            if favorite == "true" and status == "active":
                favorited.append(str(task_file))
    
    return favorited[:3]  # Limit to 3


def get_favorited_projects() -> List[str]:
    """Get list of favorited project directory paths."""
    favorited = []
    
    if PROJECTS_PATH.exists():
        # Collect all favorited projects first (sorted for consistency)
        for project_dir in sorted(PROJECTS_PATH.iterdir()):
            if not project_dir.is_dir():
                continue
            readme = project_dir / "README.md"
            if readme.exists():
                favorite = get_frontmatter_value(readme, "favorite")
                status = get_frontmatter_value(readme, "status")
                # If no status field, assume active (default for projects)
                if not status:
                    status = "active"
                if favorite == "true" and status == "active":
                    favorited.append(str(project_dir))
    
    # Return first 2 (limit for display)
    return favorited[:2]


def count_suggestions() -> Dict[str, int]:
    """Count pending suggestions by confidence level."""
    result = {
        "total": 0,
        "high": 0,
        "medium": 0,
        "low": 0
    }
    
    if not SUGGESTIONS_DIR.exists():
        return result
    
    try:
        for suggestion_file in SUGGESTIONS_DIR.glob("*.json"):
            try:
                with open(suggestion_file, "r") as f:
                    data = json.load(f)
                    if data.get("status") == "pending":
                        result["total"] += 1
                        confidence = data.get("confidence", 0)
                        if confidence >= 0.85:
                            result["high"] += 1
                        elif confidence >= 0.70:
                            result["medium"] += 1
                        else:
                            result["low"] += 1
            except Exception:
                continue
    except Exception:
        pass
    
    return result


def get_today_entries() -> int:
    """Count today's log entries."""
    today = datetime.now().strftime("%Y-%m-%d")
    today_log = DAILY_LOG_DIR / f"{today}.md"
    
    if not today_log.exists():
        return 0
    
    try:
        with open(today_log, "r") as f:
            content = f.read()
            # Count lines matching time pattern (HH:MM -)
            import re
            pattern = r"^\d{2}:\d{2} -"
            matches = re.findall(pattern, content, re.MULTILINE)
            return len(matches)
    except Exception:
        return 0


def get_streak() -> int:
    """Get current logging streak."""
    try:
        # Try to use gtd-log-stats if available
        import subprocess
        result = subprocess.run(
            ["gtd-log-stats", "streak"],
            capture_output=True,
            text=True,
            timeout=3
        )
        if result.returncode == 0:
            return int(result.stdout.strip() or "0")
    except Exception:
        pass
    return 0


def update_cache() -> Dict[str, Any]:
    """Update the dashboard cache with current statistics."""
    log("Updating dashboard cache...")
    
    cache = {
        "timestamp": datetime.now().isoformat(),
        "inbox_count": count_files(INBOX_PATH),
        "tasks_count": count_files(TASKS_PATH),
        "active_tasks_count": count_active_tasks(TASKS_PATH),
        "project_tasks_count": count_active_tasks(PROJECTS_PATH),
        "total_active_tasks": 0,  # Will be calculated
        "projects_count": len([d for d in PROJECTS_PATH.iterdir() if d.is_dir()]) if PROJECTS_PATH.exists() else 0,
        "areas_count": count_files(AREAS_PATH),
        "waiting_count": count_files(WAITING_PATH),
        "someday_count": count_files(SOMEDAY_PATH),
        "suggestions": count_suggestions(),
        "today_entries": get_today_entries(),
        "streak": get_streak(),
        "favorited_tasks": get_favorited_tasks(),
        "favorited_projects": get_favorited_projects(),
    }
    
    # Calculate total active tasks
    cache["total_active_tasks"] = cache["active_tasks_count"] + cache["project_tasks_count"]
    
    # Write cache file
    try:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f, indent=2)
        log(f"Cache updated successfully: {cache['inbox_count']} inbox, {cache['total_active_tasks']} active tasks")
    except Exception as e:
        log(f"Error writing cache: {e}")
    
    return cache


def main():
    """Main worker loop."""
    import signal
    
    def signal_handler(signum, frame):
        log("Received shutdown signal, exiting...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    log("Dashboard cache worker starting...")
    log(f"Cache file: {CACHE_FILE}")
    log(f"Update interval: {UPDATE_INTERVAL} seconds")
    
    # Load GTD config to update paths
    config = load_gtd_config()
    global GTD_BASE_DIR, INBOX_PATH, TASKS_PATH, PROJECTS_PATH, AREAS_PATH
    global WAITING_PATH, SOMEDAY_PATH, SUGGESTIONS_DIR, DAILY_LOG_DIR
    
    if "GTD_BASE_DIR" in config:
        GTD_BASE_DIR = Path(config["GTD_BASE_DIR"].replace("$HOME", str(Path.home())))
        INBOX_PATH = GTD_BASE_DIR / "0-inbox"
        TASKS_PATH = GTD_BASE_DIR / "tasks"
        PROJECTS_PATH = GTD_BASE_DIR / "1-projects"
        AREAS_PATH = GTD_BASE_DIR / "2-areas"
        WAITING_PATH = GTD_BASE_DIR / "4-waiting"
        SOMEDAY_PATH = GTD_BASE_DIR / "5-someday"
        SUGGESTIONS_DIR = GTD_BASE_DIR / "suggestions"
    
    if "DAILY_LOG_DIR" in config:
        DAILY_LOG_DIR = Path(config["DAILY_LOG_DIR"].replace("$HOME", str(Path.home())))
    
    # Initial cache update
    update_cache()
    
    # Continuous updates
    while True:
        try:
            time.sleep(UPDATE_INTERVAL)
            update_cache()
        except KeyboardInterrupt:
            log("Interrupted by user")
            break
        except Exception as e:
            log(f"Error in worker loop: {e}")
            time.sleep(UPDATE_INTERVAL)


if __name__ == "__main__":
    main()


