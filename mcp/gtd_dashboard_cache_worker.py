#!/usr/bin/env python3
"""
GTD Dashboard Cache Worker
Maintains a cache file with dashboard statistics to speed up rendering.
"""

import json
import os
import sys
import time
import errno
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


def scan_tasks_and_projects_comprehensive() -> Dict[str, Any]:
    """
    Comprehensive scan of tasks and projects - collects all data in one pass.
    Returns a dictionary with all task/project statistics.
    """
    result = {
        "tasks_active_count": 0,
        "projects_active_count": 0,
        "favorited_tasks": [],
        "favorited_projects": [],
        "overdue_tasks": [],
        "blocked_tasks": [],
        "project_info": {}  # project_name -> {active_tasks, blocked_tasks, favorite, status, last_activity}
    }
    
    today = datetime.now().strftime("%Y-%m-%d")
    today_dt = datetime.now()
    max_files = 10000  # Safety limit
    
    # Scan TASKS_PATH
    if TASKS_PATH.exists() and TASKS_PATH.is_dir():
        files_checked = 0
        try:
            for task_file in TASKS_PATH.glob("*.md"):  # Only top-level for tasks
                files_checked += 1
                if files_checked > max_files:
                    break
                
                try:
                    status = get_frontmatter_value(task_file, "status")
                    favorite = get_frontmatter_value(task_file, "favorite")
                    due = get_frontmatter_value(task_file, "due")
                    blocked_by = get_frontmatter_value(task_file, "blocked_by")
                    
                    if status == "active":
                        result["tasks_active_count"] += 1
                        
                        # Check if favorite
                        if favorite == "true":
                            result["favorited_tasks"].append(str(task_file))
                        
                        # Check if overdue
                        if due:
                            due_date = due.split("T")[0] if "T" in due else due
                            if due_date < today:
                                task_name = task_file.stem
                                try:
                                    with open(task_file, "r", encoding="utf-8") as f:
                                        first_line = f.readline().strip()
                                        if first_line.startswith("# "):
                                            task_name = first_line[2:].strip()
                                except Exception:
                                    pass
                                
                                result["overdue_tasks"].append({
                                    "file": str(task_file),
                                    "name": task_name,
                                    "due": due,
                                    "path": task_file.name
                                })
                        
                        # Check if blocked
                        if blocked_by and blocked_by.lower() in ["true", "yes", "1"]:
                            task_name = task_file.stem
                            try:
                                with open(task_file, "r", encoding="utf-8") as f:
                                    first_line = f.readline().strip()
                                    if first_line.startswith("# "):
                                        task_name = first_line[2:].strip()
                            except Exception:
                                pass
                            
                            result["blocked_tasks"].append({
                                "file": str(task_file),
                                "name": task_name,
                                "path": task_file.name
                            })
                except Exception:
                    continue
        except Exception as e:
            log(f"  WARNING: Error scanning TASKS_PATH: {e}")
    
    # Scan PROJECTS_PATH (recursive for tasks, top-level for project info)
    if PROJECTS_PATH.exists() and PROJECTS_PATH.is_dir():
        files_checked = 0
        projects_checked = 0
        max_projects = 500
        
        try:
            # First pass: collect project-level info
            for project_dir in sorted(PROJECTS_PATH.iterdir()):
                projects_checked += 1
                if projects_checked > max_projects:
                    break
                
                if not project_dir.is_dir():
                    continue
                
                project_name = project_dir.name
                readme = project_dir / "README.md"
                
                project_data = {
                    "active_tasks": 0,
                    "blocked_tasks": 0,
                    "favorite": False,
                    "status": "active",
                    "last_activity": None
                }
                
                if readme.exists():
                    try:
                        project_data["favorite"] = get_frontmatter_value(readme, "favorite") == "true"
                        project_data["status"] = get_frontmatter_value(readme, "status") or "active"
                        project_data["last_activity"] = get_frontmatter_value(readme, "last_activity")
                    except Exception:
                        pass
                
                result["project_info"][project_name] = project_data
                
                # Check if favorited and active
                if project_data["favorite"] and project_data["status"] == "active":
                    result["favorited_projects"].append(str(project_dir))
            
            # Second pass: scan task files in projects
            for task_file in PROJECTS_PATH.rglob("*.md"):
                files_checked += 1
                if files_checked > max_files:
                    log(f"  WARNING: Reached file limit ({max_files}) in PROJECTS_PATH, stopping scan")
                    break
                
                if task_file.name == "README.md":
                    continue
                
                try:
                    # Determine which project this task belongs to
                    # Walk up the directory tree to find the project root
                    current_dir = task_file.parent
                    project_name = None
                    
                    while current_dir != PROJECTS_PATH and current_dir != PROJECTS_PATH.parent:
                        if current_dir.parent == PROJECTS_PATH:
                            project_name = current_dir.name
                            break
                        current_dir = current_dir.parent
                    
                    # Skip if we couldn't find a project (shouldn't happen, but safety check)
                    if not project_name or project_name not in result["project_info"]:
                        continue
                    
                    status = get_frontmatter_value(task_file, "status")
                    favorite = get_frontmatter_value(task_file, "favorite")
                    due = get_frontmatter_value(task_file, "due")
                    blocked_by = get_frontmatter_value(task_file, "blocked_by")
                    
                    if status == "active":
                        result["projects_active_count"] += 1
                        
                        # Update project info
                        if project_name in result["project_info"]:
                            result["project_info"][project_name]["active_tasks"] += 1
                            if blocked_by and blocked_by.lower() in ["true", "yes", "1"]:
                                result["project_info"][project_name]["blocked_tasks"] += 1
                        
                        # Check if favorite
                        if favorite == "true":
                            result["favorited_tasks"].append(str(task_file))
                        
                        # Check if overdue
                        if due:
                            due_date = due.split("T")[0] if "T" in due else due
                            if due_date < today:
                                task_name = task_file.stem
                                try:
                                    with open(task_file, "r", encoding="utf-8") as f:
                                        first_line = f.readline().strip()
                                        if first_line.startswith("# "):
                                            task_name = first_line[2:].strip()
                                except Exception:
                                    pass
                                
                                result["overdue_tasks"].append({
                                    "file": str(task_file),
                                    "name": task_name,
                                    "due": due,
                                    "path": str(task_file.relative_to(PROJECTS_PATH))
                                })
                        
                        # Check if blocked
                        if blocked_by and blocked_by.lower() in ["true", "yes", "1"]:
                            task_name = task_file.stem
                            try:
                                with open(task_file, "r", encoding="utf-8") as f:
                                    first_line = f.readline().strip()
                                    if first_line.startswith("# "):
                                        task_name = first_line[2:].strip()
                            except Exception:
                                pass
                            
                            result["blocked_tasks"].append({
                                "file": str(task_file),
                                "name": task_name,
                                "path": str(task_file.relative_to(PROJECTS_PATH))
                            })
                except Exception:
                    continue
        except Exception as e:
            log(f"  WARNING: Error scanning PROJECTS_PATH: {e}")
    
    # Limit lists to reasonable sizes
    result["favorited_tasks"] = result["favorited_tasks"][:3]
    result["favorited_projects"] = result["favorited_projects"][:2]
    result["overdue_tasks"] = result["overdue_tasks"][:10]
    result["blocked_tasks"] = result["blocked_tasks"][:10]
    
    return result


def count_active_tasks(directory: Path) -> int:
    """Count active tasks in directory - DEPRECATED: Use scan_tasks_and_projects_comprehensive() instead."""
    # This is kept for backward compatibility but should use the comprehensive scan
    if directory == TASKS_PATH:
        # For tasks, we can still do a quick count
        if not directory.exists() or not directory.is_dir():
            return 0
        count = 0
        try:
            for task_file in directory.glob("*.md"):
                status = get_frontmatter_value(task_file, "status")
                if status == "active":
                    count += 1
        except Exception:
            pass
        return count
    else:
        # For projects, we need the comprehensive scan
        # This is a fallback - ideally this shouldn't be called
        return 0


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
    """Count pending suggestions by confidence level with timeout protection."""
    result = {
        "total": 0,
        "high": 0,
        "medium": 0,
        "low": 0
    }
    
    if not SUGGESTIONS_DIR.exists():
        return result
    
    files_checked = 0
    max_files = 1000  # Safety limit for JSON files
    timeout_count = 0
    max_timeouts = 10  # Stop processing if too many timeouts (filesystem issue)
    
    try:
        # Quick test to see if directory is accessible
        try:
            test_access = list(SUGGESTIONS_DIR.iterdir())
            if len(test_access) == 0:
                return result
        except OSError as e:
            if e.errno == errno.ETIMEDOUT:
                log(f"  WARNING: Suggestions directory access timed out, skipping suggestions count")
            else:
                log(f"  WARNING: Cannot access suggestions directory: {e}")
            return result
        
        # Materialize the list first to avoid iterator issues
        json_files = list(SUGGESTIONS_DIR.glob("*.json"))
        
        if len(json_files) > max_files:
            log(f"  WARNING: Too many suggestion files ({len(json_files)}), limiting to {max_files}")
            json_files = json_files[:max_files]
        
        for suggestion_file in json_files:
            files_checked += 1
            
            # If we've hit too many timeouts, likely a filesystem issue - bail out
            if timeout_count >= max_timeouts:
                log(f"  WARNING: Too many timeout errors ({timeout_count}), stopping suggestions scan (filesystem may be slow/unresponsive)")
                break
            
            try:
                # Check file size first - skip very large files
                # This can timeout if filesystem is slow
                try:
                    file_size = suggestion_file.stat().st_size
                except OSError as e:
                    if e.errno == errno.ETIMEDOUT:
                        timeout_count += 1
                        log(f"  WARNING: Timeout reading {suggestion_file.name} (stat) - filesystem may be slow")
                    else:
                        log(f"  WARNING: Error accessing {suggestion_file.name}: {e}")
                    continue
                
                if file_size > 10 * 1024 * 1024:  # Skip files > 10MB
                    log(f"  WARNING: Skipping large suggestion file: {suggestion_file.name} ({file_size} bytes)")
                    continue
                
                # Open and read file - this can also timeout
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
                except OSError as e:
                    if e.errno == errno.ETIMEDOUT:
                        timeout_count += 1
                        log(f"  WARNING: Timeout reading {suggestion_file.name} - filesystem may be slow")
                    else:
                        log(f"  WARNING: Error reading {suggestion_file.name}: {e}")
                    continue
            except json.JSONDecodeError:
                # Skip corrupted JSON files
                continue
            except Exception as e:
                # Check if it's a timeout error
                if isinstance(e, OSError) and e.errno == errno.ETIMEDOUT:
                    timeout_count += 1
                    log(f"  WARNING: Timeout error reading {suggestion_file.name}: {e}")
                else:
                    log(f"  WARNING: Error reading {suggestion_file.name}: {e}")
                continue
    except Exception as e:
        log(f"  ERROR in count_suggestions(): {e}")
    
    if timeout_count > 0:
        log(f"  NOTE: Encountered {timeout_count} timeout(s) while reading suggestions (filesystem may be slow or network-mounted)")
    
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


def get_overdue_tasks() -> List[Dict[str, Any]]:
    """Get list of overdue tasks ready for review with timeout protection."""
    overdue = []
    today = datetime.now().strftime("%Y-%m-%d")
    
    search_paths = [TASKS_PATH, PROJECTS_PATH]
    max_files = 5000  # Limit files to scan
    
    for path in search_paths:
        if not path.exists() or not path.is_dir():
            continue
        
        files_checked = 0
        try:
            for task_file in path.rglob("*.md"):
                files_checked += 1
                if files_checked > max_files:
                    break
                
                if task_file.name == "README.md":
                    continue
                
                try:
                    status = get_frontmatter_value(task_file, "status")
                    if status in ["done", "archived"]:
                        continue
                    
                    due = get_frontmatter_value(task_file, "due")
                    if due:
                        # Extract date part (handle ISO format with time)
                        due_date = due.split("T")[0] if "T" in due else due
                        if due_date < today:
                            task_name = task_file.stem
                            # Try to get title from file (limit read to first 1KB)
                            try:
                                with open(task_file, "r", encoding="utf-8") as f:
                                    first_line = f.readline().strip()
                                    if first_line.startswith("# "):
                                        task_name = first_line[2:].strip()
                            except Exception:
                                pass
                            
                            overdue.append({
                                "file": str(task_file),
                                "name": task_name,
                                "due": due,
                                "path": str(task_file.relative_to(path.parent)) if path.parent in task_file.parents else str(task_file)
                            })
                            
                            # Stop once we have enough
                            if len(overdue) >= 10:
                                return overdue[:10]
                except Exception:
                    continue
        except Exception as e:
            log(f"  WARNING: Error scanning {path} for overdue tasks: {e}")
            continue
    
    return overdue[:10]  # Limit to 10 for display


def get_blocked_tasks() -> List[Dict[str, Any]]:
    """Get list of blocked tasks ready for review with timeout protection."""
    blocked = []
    
    search_paths = [TASKS_PATH, PROJECTS_PATH]
    max_files = 5000  # Limit files to scan
    
    for path in search_paths:
        if not path.exists() or not path.is_dir():
            continue
        
        files_checked = 0
        try:
            for task_file in path.rglob("*.md"):
                files_checked += 1
                if files_checked > max_files:
                    break
                
                if task_file.name == "README.md":
                    continue
                
                try:
                    status = get_frontmatter_value(task_file, "status")
                    if status != "active":
                        continue
                    
                    blocked_by = get_frontmatter_value(task_file, "blocked_by")
                    if blocked_by and blocked_by.lower() in ["true", "yes", "1"]:
                        task_name = task_file.stem
                        # Try to get title from file (limit read to first line)
                        try:
                            with open(task_file, "r", encoding="utf-8") as f:
                                first_line = f.readline().strip()
                                if first_line.startswith("# "):
                                    task_name = first_line[2:].strip()
                        except Exception:
                            pass
                        
                        blocked.append({
                            "file": str(task_file),
                            "name": task_name,
                            "path": str(task_file.relative_to(path.parent)) if path.parent in task_file.parents else str(task_file)
                        })
                        
                        # Stop once we have enough
                        if len(blocked) >= 10:
                            return blocked[:10]
                except Exception:
                    continue
        except Exception as e:
            log(f"  WARNING: Error scanning {path} for blocked tasks: {e}")
            continue
    
    return blocked[:10]  # Limit to 10 for display


def get_inbox_items() -> List[Dict[str, Any]]:
    """Get list of inbox items ready for processing."""
    inbox_items = []
    
    if not INBOX_PATH.exists() or not INBOX_PATH.is_dir():
        return inbox_items
    
    try:
        for item_file in INBOX_PATH.glob("*.md"):
            item_name = item_file.stem
            # Try to get title from file
            try:
                with open(item_file, "r", encoding="utf-8") as f:
                    first_line = f.readline().strip()
                    if first_line.startswith("# "):
                        item_name = first_line[2:].strip()
            except Exception:
                pass
            
            inbox_items.append({
                "file": str(item_file),
                "name": item_name,
                "path": item_file.name
            })
    except Exception:
        pass
    
    return inbox_items[:10]  # Limit to 10 for display


def get_waiting_items() -> List[Dict[str, Any]]:
    """Get list of waiting-for items ready for follow-up."""
    waiting_items = []
    
    if not WAITING_PATH.exists() or not WAITING_PATH.is_dir():
        return waiting_items
    
    try:
        for item_file in WAITING_PATH.glob("*.md"):
            item_name = item_file.stem
            # Try to get title from file
            try:
                with open(item_file, "r", encoding="utf-8") as f:
                    first_line = f.readline().strip()
                    if first_line.startswith("# "):
                        item_name = first_line[2:].strip()
            except Exception:
                pass
            
            waiting_items.append({
                "file": str(item_file),
                "name": item_name,
                "path": item_file.name
            })
    except Exception:
        pass
    
    return waiting_items[:10]  # Limit to 10 for display


def get_stalled_projects_from_scan(project_info: Dict[str, Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Get list of stalled projects from comprehensive scan data (optimized)."""
    stalled = []
    today_dt = datetime.now()
    
    for project_name, project_data in project_info.items():
        if project_data["status"] in ["done", "archived"]:
            continue
        
        last_activity = project_data.get("last_activity")
        if last_activity and last_activity != "unknown":
            try:
                # Parse date
                if "T" in last_activity:
                    last_date = datetime.fromisoformat(last_activity.split("T")[0])
                else:
                    last_date = datetime.strptime(last_activity, "%Y-%m-%d")
                
                days_inactive = (today_dt - last_date).days
                
                if days_inactive >= 14:
                    # Consider stalled if no activity in 14+ days AND (blocked tasks OR no active tasks)
                    if project_data["blocked_tasks"] > 0 or project_data["active_tasks"] == 0:
                        stalled.append({
                            "name": project_name,
                            "path": str(PROJECTS_PATH / project_name),
                            "days_inactive": days_inactive,
                            "blocked_tasks": project_data["blocked_tasks"],
                            "active_tasks": project_data["active_tasks"]
                        })
                        
                        # Stop once we have enough
                        if len(stalled) >= 10:
                            return stalled[:10]
            except Exception:
                continue
    
    return stalled[:10]  # Limit to 10 for display


def get_stalled_projects() -> List[Dict[str, Any]]:
    """Get list of stalled projects ready for review with timeout protection."""
    stalled = []
    today = datetime.now()
    
    if not PROJECTS_PATH.exists() or not PROJECTS_PATH.is_dir():
        return stalled
    
    max_projects = 500  # Limit number of projects to check
    projects_checked = 0
    
    try:
        for project_dir in PROJECTS_PATH.iterdir():
            projects_checked += 1
            if projects_checked > max_projects:
                log(f"  WARNING: Reached project limit ({max_projects}), stopping scan")
                break
            
            if not project_dir.is_dir():
                continue
            
            readme = project_dir / "README.md"
            if not readme.exists():
                continue
            
            try:
                status = get_frontmatter_value(readme, "status")
                if status in ["done", "archived"]:
                    continue
                
                # Check last activity
                last_activity = get_frontmatter_value(readme, "last_activity")
                if last_activity and last_activity != "unknown":
                    try:
                        # Parse date
                        if "T" in last_activity:
                            last_date = datetime.fromisoformat(last_activity.split("T")[0])
                        else:
                            last_date = datetime.strptime(last_activity, "%Y-%m-%d")
                        
                        days_inactive = (today - last_date).days
                        
                        if days_inactive >= 14:
                            # Check if project has blocked tasks or no active tasks
                            # Limit task scan to prevent slowdown
                            active_tasks = 0
                            blocked_tasks = 0
                            task_files_checked = 0
                            max_task_files = 1000
                            
                            for task_file in project_dir.rglob("*.md"):
                                task_files_checked += 1
                                if task_files_checked > max_task_files:
                                    break
                                
                                if task_file.name == "README.md":
                                    continue
                                
                                try:
                                    task_status = get_frontmatter_value(task_file, "status")
                                    if task_status == "active":
                                        active_tasks += 1
                                        blocked_by = get_frontmatter_value(task_file, "blocked_by")
                                        if blocked_by and blocked_by.lower() in ["true", "yes", "1"]:
                                            blocked_tasks += 1
                                except Exception:
                                    continue
                            
                            # Consider stalled if no activity in 14+ days AND (blocked tasks OR no active tasks)
                            if blocked_tasks > 0 or active_tasks == 0:
                                project_name = project_dir.name
                                stalled.append({
                                    "name": project_name,
                                    "path": str(project_dir),
                                    "days_inactive": days_inactive,
                                    "blocked_tasks": blocked_tasks,
                                    "active_tasks": active_tasks
                                })
                                
                                # Stop once we have enough
                                if len(stalled) >= 10:
                                    return stalled[:10]
                    except Exception:
                        continue
            except Exception:
                continue
    except Exception as e:
        log(f"  WARNING: Error scanning projects for stalled: {e}")
        pass
    
    return stalled[:10]  # Limit to 10 for display


def get_ai_suggestions() -> List[Dict[str, Any]]:
    """Get list of AI suggestions ready for review."""
    suggestions = []
    
    if not SUGGESTIONS_DIR.exists():
        return suggestions
    
    try:
        for suggestion_file in SUGGESTIONS_DIR.glob("*.json"):
            try:
                with open(suggestion_file, "r") as f:
                    data = json.load(f)
                    if data.get("status") == "pending":
                        suggestions.append({
                            "file": str(suggestion_file),
                            "name": suggestion_file.stem,
                            "confidence": data.get("confidence", 0),
                            "type": data.get("type", "unknown")
                        })
            except Exception:
                continue
    except Exception:
        pass
    
    return suggestions[:10]  # Limit to 10 for display


def get_advice_results() -> List[Dict[str, Any]]:
    """Get list of completed advice results ready for review."""
    results = []
    advice_results_dir = GTD_BASE_DIR / "advice_results"
    
    if not advice_results_dir.exists():
        return results
    
    try:
        for result_file in advice_results_dir.glob("*.json"):
            try:
                with open(result_file, "r") as f:
                    data = json.load(f)
                    if data.get("status") == "completed":
                        results.append({
                            "file": str(result_file),
                            "name": result_file.stem,
                            "timestamp": data.get("timestamp", "")
                        })
            except Exception:
                continue
    except Exception:
        pass
    
    return results[:10]  # Limit to 10 for display


def get_project_suggestions() -> List[Dict[str, Any]]:
    """Get list of project suggestion results ready for review."""
    suggestions = []
    task_org_results_dir = GTD_BASE_DIR / "task_organization_results"
    
    if not task_org_results_dir.exists():
        return suggestions
    
    try:
        for suggestion_file in task_org_results_dir.glob("project_suggestions_*.json"):
            suggestions.append({
                "file": str(suggestion_file),
                "name": suggestion_file.stem,
                "timestamp": suggestion_file.stat().st_mtime
            })
    except Exception:
        pass
    
    return suggestions[:10]  # Limit to 10 for display


def get_background_worker_status() -> Dict[str, Any]:
    """Check status of all background workers."""
    import subprocess
    
    workers = [
        ("Deep Analysis", "gtd_deep_analysis_worker.py", ""),
        ("Vector", "gtd_vector_worker.py", ""),
        ("Advice", "gtd_advice_worker.py", "gtd-advice-worker.*daemon"),
        ("Task Org", "gtd_task_organize_worker.py", ""),
        ("Badge", "gtd_badge_suggestion_worker.py", ""),
        ("Brain Sync", "gtd_second_brain_sync_worker.py", ""),
        ("Dashboard Cache", "gtd_dashboard_cache_worker.py", ""),
    ]
    
    worker_status = {}
    running_count = 0
    not_running_count = 0
    wrong_version_count = 0
    
    for worker_name, pattern, wrong_pattern in workers:
        status = "stopped"
        is_wrong_version = False
        
        # Special case: Dashboard Cache worker checking itself
        # If we're able to run this check, the worker must be running
        # (we're executing inside the worker process)
        if worker_name == "Dashboard Cache":
            # We're inside the dashboard cache worker, so it's definitely running
            status = "running"
            running_count += 1
        else:
            # Check for other workers normally
            try:
                result = subprocess.run(
                    ["pgrep", "-f", pattern],
                    capture_output=True,
                    text=True,
                    timeout=1
                )
                if result.returncode == 0 and result.stdout.strip():
                    pid = result.stdout.strip().split()[0]
                    # Verify process is actually running
                    check_result = subprocess.run(
                        ["ps", "-p", pid],
                        capture_output=True,
                        timeout=1
                    )
                    if check_result.returncode == 0:
                        status = "running"
                        running_count += 1
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, Exception):
                pass
        
        # Check for wrong version (if pattern specified)
        if not status == "running" and wrong_pattern:
            try:
                result = subprocess.run(
                    ["pgrep", "-f", wrong_pattern],
                    capture_output=True,
                    text=True,
                    timeout=1
                )
                if result.returncode == 0 and result.stdout.strip():
                    pid = result.stdout.strip().split()[0]
                    check_result = subprocess.run(
                        ["ps", "-p", pid],
                        capture_output=True,
                        timeout=1
                    )
                    if check_result.returncode == 0:
                        status = "wrong_version"
                        is_wrong_version = True
                        wrong_version_count += 1
            except (subprocess.TimeoutExpired, subprocess.SubprocessError, Exception):
                pass
        
        if status == "stopped":
            not_running_count += 1
        
        worker_status[worker_name] = {
            "status": status,
            "is_wrong_version": is_wrong_version
        }
    
    return {
        "workers": worker_status,
        "summary": {
            "running": running_count,
            "stopped": not_running_count,
            "wrong_version": wrong_version_count,
            "total": len(workers)
        }
    }


def get_gcalcli_status() -> Dict[str, Any]:
    """Check gcalcli connection status."""
    import subprocess
    import shutil
    import os
    
    status_info = {
        "installed": False,
        "connected": False,
        "error": None
    }
    
    # Check if gcalcli is installed
    # First try shutil.which (checks PATH)
    gcalcli_path = shutil.which("gcalcli")
    
    # If not found in PATH, check common homebrew locations
    if not gcalcli_path:
        homebrew_paths = [
            "/opt/homebrew/bin/gcalcli",  # Apple Silicon
            "/usr/local/bin/gcalcli",     # Intel
        ]
        for path in homebrew_paths:
            if os.path.exists(path) and os.access(path, os.X_OK):
                gcalcli_path = path
                break
    
    if not gcalcli_path:
        status_info["error"] = "not_installed"
        return status_info
    
    status_info["installed"] = True
    
    # Test connection by trying to list calendars (with timeout)
    # Use the full path we found
    # We test with 'list' first, then try 'agenda' as a more comprehensive auth test
    try:
        # First test: list calendars (quick check)
        result = subprocess.run(
            [gcalcli_path, "list"],
            capture_output=True,
            text=True,
            timeout=5  # 5 second timeout
        )
        
        # Check both stdout and stderr for errors (gcalcli sometimes outputs errors to stdout)
        output_text = (result.stdout or "") + " " + (result.stderr or "")
        output_lower = output_text.lower()
        
        # Check for authentication errors in list output
        auth_error_keywords = [
            "invalid_grant", "token has been expired", "token has been revoked",
            "authentication", "oauth", "credentials", "refresherror", "401", "403",
            "unauthorized", "access denied", "permission denied", "invalid_client",
            "access_denied", "invalid_request", "httperror", "http error"
        ]
        
        # Also check for Python tracebacks which might indicate auth issues
        has_traceback = "traceback" in output_lower or "file \"" in output_lower
        
        has_auth_error = any(keyword in output_lower for keyword in auth_error_keywords)
        
        # If there's a traceback, it might be an auth issue - check more carefully
        if has_traceback and not has_auth_error:
            # Traceback without explicit auth error - could still be auth related
            # Test with agenda to see if it's a real auth issue
            pass
        
        if result.returncode == 0 and result.stdout.strip() and not has_auth_error and not has_traceback:
            # List worked, but let's also test with agenda to be more thorough
            # (agenda requires actual API access, not just cached data)
            try:
                agenda_result = subprocess.run(
                    [gcalcli_path, "agenda", "today"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                agenda_output = (agenda_result.stdout or "") + " " + (agenda_result.stderr or "")
                agenda_lower = agenda_output.lower()
                
                # Check for auth errors or tracebacks in agenda output
                agenda_has_auth_error = any(keyword in agenda_lower for keyword in auth_error_keywords)
                agenda_has_traceback = "traceback" in agenda_lower or "file \"" in agenda_lower
                
                if agenda_has_auth_error or (agenda_has_traceback and agenda_result.returncode != 0):
                    # Authentication issue detected
                    status_info["connected"] = False
                    status_info["error"] = "not_authenticated"
                elif agenda_result.returncode == 0:
                    # Both list and agenda worked - fully authenticated
                    status_info["connected"] = True
                else:
                    # Agenda failed but might be other reasons (no events, etc.)
                    # If it's not an auth error, consider it connected
                    status_info["connected"] = True
            except (subprocess.TimeoutExpired, Exception):
                # Agenda test failed/timed out, but list worked
                # Assume connected (agenda might just be slow or have no events)
                status_info["connected"] = True
        elif has_auth_error:
            # Authentication error detected
            status_info["connected"] = False
            status_info["error"] = "not_authenticated"
        else:
            # Command failed or returned no output
            status_info["connected"] = False
            # Check for authentication errors (comprehensive list)
            if has_auth_error:
                status_info["error"] = "not_authenticated"
            elif "network" in output_lower or "connection" in output_lower or "timeout" in output_lower:
                status_info["error"] = "network_error"
            elif result.stderr or result.stdout:
                status_info["error"] = "unknown_error"
            else:
                status_info["error"] = "no_output"
    except subprocess.TimeoutExpired:
        status_info["connected"] = False
        status_info["error"] = "timeout"
    except (subprocess.SubprocessError, Exception) as e:
        status_info["connected"] = False
        status_info["error"] = f"error: {str(e)}"
    
    return status_info


def get_configured_calendars() -> List[str]:
    """Get list of configured calendar names."""
    calendars = []
    config = load_gtd_config()
    
    # Check for GTD_CALENDARS array in config file
    config_paths = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_calendar",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config_calendar",
        Path.home() / ".gtd_config_calendar",
    ]
    
    for config_path in config_paths:
        if config_path.exists():
            try:
                with open(config_path, "r") as f:
                    for line in f:
                        line = line.strip()
                        # Look for GTD_CALENDARS entries: "rw:CalendarName:Display Name" or "ro:CalendarName:Display Name"
                        if line.startswith('"') and ("rw:" in line or "ro:" in line):
                            # Extract calendar name (between rw:/ro: and next : or ")
                            if "rw:" in line:
                                cal_part = line.split("rw:")[1]
                            else:
                                cal_part = line.split("ro:")[1]
                            # Get calendar name (before next : or ")
                            cal_name = cal_part.split(":")[0].strip('"').strip()
                            if cal_name:
                                calendars.append(cal_name)
            except Exception:
                pass
            break
    
    # Fallback to default calendar from config
    if not calendars:
        default_cal = config.get("GTD_GOOGLE_CALENDAR_NAME") or config.get("GOOGLE_CALENDAR_NAME")
        if default_cal:
            calendars.append(default_cal)
    
    # If still no calendars, use "GTD" as default
    if not calendars:
        calendars.append("GTD")
    
    return calendars


def get_today_events_count() -> Dict[str, Any]:
    """Get count of events for today across all configured calendars."""
    import subprocess
    import shutil
    import os
    import re
    
    events_info = {
        "has_events": False,
        "event_count": 0,
        "error": None
    }
    
    # Check if gcalcli is installed and connected first
    gcalcli_status = get_gcalcli_status()
    if not gcalcli_status.get("installed", False) or not gcalcli_status.get("connected", False):
        # If not installed or not connected, return early
        events_info["error"] = gcalcli_status.get("error", "not_connected")
        return events_info
    
    # Find gcalcli path (same logic as get_gcalcli_status)
    gcalcli_path = shutil.which("gcalcli")
    if not gcalcli_path:
        homebrew_paths = [
            "/opt/homebrew/bin/gcalcli",
            "/usr/local/bin/gcalcli",
        ]
        for path in homebrew_paths:
            if os.path.exists(path) and os.access(path, os.X_OK):
                gcalcli_path = path
                break
    
    if not gcalcli_path:
        events_info["error"] = "not_installed"
        return events_info
    
    # Get events for today from ALL calendars
    # Use "today" as start and calculate end of today
    # Note: gcalcli agenda "today" "today" sometimes doesn't work correctly
    # Better to use "today" as start and "tomorrow" as end, then filter to today only
    from datetime import datetime, timedelta
    today = datetime.now().strftime("%Y-%m-%d")
    tomorrow = (datetime.now() + timedelta(days=1)).strftime("%Y-%m-%d")
    
    try:
        result = subprocess.run(
            [gcalcli_path, "agenda", today, tomorrow],
            capture_output=True,
            text=True,
            timeout=8  # Increased timeout since checking all calendars
        )
        
        if result.returncode == 0 and result.stdout:
            # Strip ANSI color codes first
            ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
            all_output_text = ansi_escape.sub('', result.stdout.strip())
        else:
            all_output_text = ""
    except subprocess.TimeoutExpired:
        events_info["error"] = "timeout"
        return events_info
    except Exception as e:
        events_info["error"] = f"error: {str(e)}"
        return events_info
    
    # Check if there are actual events (not just "No Events Found")
    if all_output_text and "no events found" not in all_output_text.lower():
        # Parse events and filter to today only
        # gcalcli format:
        #   "Mon Dec 30         Event name" (date header, may have all-day event name)
        #   "            7:00           Timed event" (indented timed events)
        today_dt = datetime.now()
        today_day_name = today_dt.strftime("%a")  # e.g., "Tue"
        today_month = today_dt.strftime("%b")  # e.g., "Dec"
        today_day = today_dt.strftime("%d").lstrip("0") or "0"  # e.g., "30" or "1"
        
        # Pattern to match today's date header
        date_header_pattern = rf'^{today_day_name} {today_month}\s+{today_day}\b'
        
        # Count events for today
        total_event_count = 0
        in_today_section = False
        
        for line in all_output_text.split('\n'):
            line_stripped = line.strip()
            
            # Check if this is today's date header
            if re.match(date_header_pattern, line_stripped):
                in_today_section = True
                # Count the date header line itself (for all-day events)
                total_event_count += 1
                log(f"  DEBUG: Found today's date header: {line_stripped[:60]}")
                continue
            
            # If we're in today's section, count indented event lines
            if in_today_section:
                # Check if this is an indented event line
                # Format: "            9:30           Event name" (has leading spaces)
                # After strip: "9:30           Event name" (starts with time)
                # Match either the original line (with spaces) or stripped line (starts with time)
                if re.match(r'^\s+\d{1,2}:\d{2}', line) or (line_stripped and re.match(r'^\d{1,2}:\d{2}', line_stripped)):
                    total_event_count += 1
                    log(f"  DEBUG: Found event line: {line_stripped[:60]}")
                # If we hit another date header, we've moved to a different day
                elif line_stripped and re.match(r'^[A-Z][a-z]{2} [A-Z][a-z]{2}\s+\d', line_stripped):
                    in_today_section = False
                    log(f"  DEBUG: Moved to different day: {line_stripped[:60]}")
        
        if total_event_count > 0:
            events_info["has_events"] = True
            events_info["event_count"] = total_event_count
            log(f"  DEBUG: Found {total_event_count} events for today")
        else:
            # Debug: log why no events were found
            log(f"  DEBUG: No events found. Output length: {len(all_output_text)}")
            log(f"  DEBUG: Pattern: {date_header_pattern}, Looking for: {today_day_name} {today_month} {today_day}")
            log(f"  DEBUG: First 300 chars of output: {all_output_text[:300]}")
    else:
        log(f"  DEBUG: No output or 'no events found' message. Output length: {len(all_output_text) if all_output_text else 0}")
    
    return events_info


def get_knowledge_org_results() -> List[Dict[str, Any]]:
    """Get list of knowledge organization results ready for review."""
    results = []
    knowledge_org_results_dir = GTD_BASE_DIR / "knowledge_organization_results"
    
    if not knowledge_org_results_dir.exists():
        return results
    
    try:
        for result_file in knowledge_org_results_dir.glob("knowledge_org_*.json"):
            results.append({
                "file": str(result_file),
                "name": result_file.stem,
                "timestamp": result_file.stat().st_mtime
            })
    except Exception:
        pass
    
    return results[:10]  # Limit to 10 for display


def update_cache() -> Dict[str, Any]:
    """Update the dashboard cache with current statistics."""
    start_time = time.time()
    log("Updating dashboard cache...")
    
    # Diagnostic: Check file counts to detect potential issues
    try:
        if PROJECTS_PATH.exists():
            project_files = list(PROJECTS_PATH.rglob("*.md"))
            if len(project_files) > 10000:
                log(f"  WARNING: Large number of project files detected ({len(project_files)}), this may cause slowdowns")
    except Exception:
        pass
    
    cache = {}
    step_start = time.time()
    
    # Quick file counts (fast operations)
    cache["timestamp"] = datetime.now().isoformat()
    cache["inbox_count"] = count_files(INBOX_PATH)
    log(f"  inbox_count: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["tasks_count"] = count_files(TASKS_PATH)
    log(f"  tasks_count: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["areas_count"] = count_files(AREAS_PATH)
    log(f"  areas_count: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["waiting_count"] = count_files(WAITING_PATH)
    log(f"  waiting_count: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["someday_count"] = count_files(SOMEDAY_PATH)
    log(f"  someday_count: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["projects_count"] = len([d for d in PROJECTS_PATH.iterdir() if d.is_dir()]) if PROJECTS_PATH.exists() else 0
    log(f"  projects_count: {time.time() - step_start:.3f}s")
    
    # OPTIMIZED: Single comprehensive scan for all task/project data
    step_start = time.time()
    scan_data = scan_tasks_and_projects_comprehensive()
    elapsed = time.time() - step_start
    log(f"  comprehensive_scan (tasks+projects): {elapsed:.3f}s")
    if elapsed > 5.0:
        log(f"  WARNING: comprehensive_scan took {elapsed:.1f}s (unusually slow)")
    
    # Extract data from comprehensive scan
    cache["active_tasks_count"] = scan_data["tasks_active_count"]
    cache["project_tasks_count"] = scan_data["projects_active_count"]
    cache["total_active_tasks"] = scan_data["tasks_active_count"] + scan_data["projects_active_count"]
    cache["favorited_tasks"] = scan_data["favorited_tasks"]
    cache["favorited_projects"] = scan_data["favorited_projects"]
    
    # Other operations
    step_start = time.time()
    cache["suggestions"] = count_suggestions()
    elapsed = time.time() - step_start
    log(f"  suggestions: {elapsed:.3f}s")
    if elapsed > 5.0:
        log(f"  WARNING: suggestions took {elapsed:.1f}s (unusually slow)")
    
    step_start = time.time()
    cache["today_entries"] = get_today_entries()
    log(f"  today_entries: {time.time() - step_start:.3f}s")
    
    step_start = time.time()
    cache["streak"] = get_streak()
    log(f"  streak: {time.time() - step_start:.3f}s")
    
    # Background worker status (can be slow, so cache it)
    step_start = time.time()
    cache["background_workers"] = get_background_worker_status()
    elapsed = time.time() - step_start
    log(f"  background_workers: {elapsed:.3f}s")
    if elapsed > 2.0:
        log(f"  WARNING: background_workers took {elapsed:.1f}s (unusually slow)")
    
    # GCalCLI connection status (can be slow, so cache it)
    step_start = time.time()
    cache["gcalcli_status"] = get_gcalcli_status()
    elapsed = time.time() - step_start
    log(f"  gcalcli_status: {elapsed:.3f}s")
    if elapsed > 2.0:
        log(f"  WARNING: gcalcli_status took {elapsed:.1f}s (unusually slow)")
    
    # Today's events count (only if gcalcli is connected, can be slow)
    step_start = time.time()
    cache["today_events"] = get_today_events_count()
    elapsed = time.time() - step_start
    log(f"  today_events: {elapsed:.3f}s")
    if elapsed > 2.0:
        log(f"  WARNING: today_events took {elapsed:.1f}s (unusually slow)")
    
    # Get stalled projects from comprehensive scan data
    step_start = time.time()
    stalled_projects = get_stalled_projects_from_scan(scan_data["project_info"])
    log(f"  stalled_projects: {time.time() - step_start:.3f}s")
    
    # Items ready for review (using data from comprehensive scan)
    step_start = time.time()
    cache["ready_for_review"] = {
        "inbox_items": get_inbox_items(),
        "overdue_tasks": scan_data["overdue_tasks"],  # From comprehensive scan
        "blocked_tasks": scan_data["blocked_tasks"],  # From comprehensive scan
        "waiting_items": get_waiting_items(),
        "stalled_projects": stalled_projects,  # From comprehensive scan
        "ai_suggestions": get_ai_suggestions(),
        "advice_results": get_advice_results(),
        "project_suggestions": get_project_suggestions(),
        "knowledge_org_results": get_knowledge_org_results()
    }
    elapsed = time.time() - step_start
    log(f"  ready_for_review: {elapsed:.3f}s")
    if elapsed > 10.0:
        log(f"  WARNING: ready_for_review took {elapsed:.1f}s (unusually slow)")
    
    # Add summary counts for quick access
    cache["ready_for_review_counts"] = {
        "inbox": len(cache["ready_for_review"]["inbox_items"]),
        "overdue": len(cache["ready_for_review"]["overdue_tasks"]),
        "blocked": len(cache["ready_for_review"]["blocked_tasks"]),
        "waiting": len(cache["ready_for_review"]["waiting_items"]),
        "stalled_projects": len(cache["ready_for_review"]["stalled_projects"]),
        "ai_suggestions": len(cache["ready_for_review"]["ai_suggestions"]),
        "advice_results": len(cache["ready_for_review"]["advice_results"]),
        "project_suggestions": len(cache["ready_for_review"]["project_suggestions"]),
        "knowledge_org": len(cache["ready_for_review"]["knowledge_org_results"])
    }
    
    # Write cache file
    step_start = time.time()
    try:
        CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(cache, f, indent=2)
        log(f"  write_cache: {time.time() - step_start:.3f}s")
        total_time = time.time() - start_time
        
        # Build summary of ready-for-review items
        review_summary = []
        counts = cache.get("ready_for_review_counts", {})
        if counts.get("inbox", 0) > 0:
            review_summary.append(f"{counts['inbox']} inbox")
        if counts.get("overdue", 0) > 0:
            review_summary.append(f"{counts['overdue']} overdue")
        if counts.get("blocked", 0) > 0:
            review_summary.append(f"{counts['blocked']} blocked")
        if counts.get("waiting", 0) > 0:
            review_summary.append(f"{counts['waiting']} waiting")
        if counts.get("stalled_projects", 0) > 0:
            review_summary.append(f"{counts['stalled_projects']} stalled")
        if counts.get("ai_suggestions", 0) > 0:
            review_summary.append(f"{counts['ai_suggestions']} AI suggestions")
        
        review_text = f", {', '.join(review_summary)} ready for review" if review_summary else ""
        log(f"Cache updated successfully: {cache['inbox_count']} inbox, {cache['total_active_tasks']} active tasks{review_text} (total: {total_time:.3f}s)")
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


