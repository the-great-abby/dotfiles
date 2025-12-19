#!/usr/bin/env python3
"""
GTD Auto-Suggest System

Automatically implements high-confidence AI suggestions with safety controls.
Integrates with the unified learning system for threshold management.

Features:
- Autonomous suggestion implementation
- Configurable confidence thresholds per type
- Dry-run mode for testing
- Action logging and audit trail
- Undo functionality
- Safety limits (max actions per run/day)
- Whitelist/blacklist patterns
"""

import json
import os
import sys
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import shutil

# Import unified learning system functions
try:
    from gtd_unified_learning import (
        load_learning_data,
        save_learning_data,
        record_decision,
        should_show_suggestion,
        get_acceptance_rate,
        get_stats_summary
    )
except ImportError:
    sys.path.insert(0, os.path.dirname(__file__))
    from gtd_unified_learning import (
        load_learning_data,
        save_learning_data,
        record_decision,
        should_show_suggestion,
        get_acceptance_rate,
        get_stats_summary
    )

# Set GTD_BASE_DIR - don't import from gtd_mcp_server to avoid mcp dependency
GTD_BASE_DIR = os.path.expanduser("~/Documents/gtd")
GTD_DISCORD_WEBHOOK_URL = os.getenv("GTD_DISCORD_WEBHOOK_URL")

# Try to read from config if available
gtd_config_file = os.path.expanduser("~/code/dotfiles/zsh/.gtd_config")
if os.path.exists(gtd_config_file):
    try:
        with open(gtd_config_file) as f:
            for line in f:
                if line.strip().startswith("GTD_BASE_DIR="):
                    value = line.split("=", 1)[1].strip().strip('"').strip("'")
                    GTD_BASE_DIR = value.replace("$HOME", os.path.expanduser("~"))
                elif line.strip().startswith("export GTD_DISCORD_WEBHOOK_URL="):
                    value = line.split("=", 1)[1].strip().strip('"').strip("'")
                    if value and not GTD_DISCORD_WEBHOOK_URL:
                        GTD_DISCORD_WEBHOOK_URL = value
    except Exception:
        pass

# Configuration paths
AUTO_SUGGEST_CONFIG = os.path.join(GTD_BASE_DIR, ".auto_suggest_config.json")
AUTO_SUGGEST_LOG = os.path.join(GTD_BASE_DIR, "auto_suggest_actions.jsonl")
AUTO_SUGGEST_UNDO = os.path.join(GTD_BASE_DIR, ".auto_suggest_undo")

DEFAULT_CONFIG = {
    "enabled": False,  # Global enable/disable
    "dry_run": True,   # Always start in dry-run mode for safety
    "max_actions_per_run": 5,
    "max_actions_per_day": 20,
    "min_confidence_override": None,  # Override learning system thresholds
    "type_configs": {
        "task_suggestion": {
            "enabled": True,
            "min_confidence": 0.85
        },
        "project_suggestion": {
            "enabled": True,
            "min_confidence": 0.90
        },
        "moc_suggestion": {
            "enabled": False,  # More conservative for knowledge org
            "min_confidence": 0.95
        },
        "area_suggestion": {
            "enabled": False,  # More conservative for knowledge org
            "min_confidence": 0.95
        },
        "deep_analysis": {
            "enabled": False,  # Deep analysis is already auto-applied via insights
            "min_confidence": 0.80
        }
    },
    "whitelist_patterns": [],  # File/tag patterns to always allow
    "blacklist_patterns": [],  # File/tag patterns to never auto-implement
    "safety": {
        "require_backup": True,
        "max_file_size_kb": 500,  # Don't auto-edit files larger than this
        "preserve_history": 30  # Days to keep undo data
    },
    "notifications": {
        "discord_enabled": True,  # Send Discord notifications
        "notify_on_action": True,  # Notify for each action
        "notify_daily_summary": True,  # Send daily summary
        "notify_on_error": True,  # Alert on failures
        "notify_threshold_adjustment": True  # Notify when thresholds auto-adjust
    },
    "smart_thresholds": {
        "enabled": False,  # Auto-adjust thresholds based on acceptance rate
        "min_threshold": 0.70,  # Never go below this
        "max_threshold": 0.98,  # Never go above this
        "adjustment_interval_days": 7,  # How often to review and adjust
        "min_samples": 20,  # Need this many decisions before adjusting
        "target_acceptance_rate": 0.85  # Aim for 85% acceptance
    }
}


class AutoSuggestSystem:
    """Manages autonomous suggestion implementation"""
    
    def __init__(self, config_path: str = AUTO_SUGGEST_CONFIG):
        self.config_path = config_path
        self.config = self._load_config()
        self.learning_data = load_learning_data()
        self.actions_taken = []
        self.undo_dir = Path(AUTO_SUGGEST_UNDO)
        self.undo_dir.mkdir(exist_ok=True)
        
    def _load_config(self) -> Dict:
        """Load auto-suggest configuration"""
        if os.path.exists(self.config_path):
            with open(self.config_path, 'r') as f:
                config = json.load(f)
                # Merge with defaults for any missing keys
                return {**DEFAULT_CONFIG, **config}
        return DEFAULT_CONFIG.copy()
    
    def save_config(self):
        """Save configuration to disk"""
        with open(self.config_path, 'w') as f:
            json.dump(self.config, f, indent=2)
    
    def is_enabled(self, suggestion_type: str = None) -> bool:
        """Check if auto-suggest is enabled globally and for a specific type"""
        if not self.config.get("enabled", False):
            return False
        
        if suggestion_type:
            type_config = self.config["type_configs"].get(suggestion_type, {})
            return type_config.get("enabled", False)
        
        return True
    
    def get_min_confidence(self, suggestion_type: str) -> float:
        """Get minimum confidence threshold for a suggestion type"""
        # Check for global override
        if self.config.get("min_confidence_override") is not None:
            return self.config["min_confidence_override"]
        
        # Get type-specific threshold
        type_config = self.config["type_configs"].get(suggestion_type, {})
        type_min = type_config.get("min_confidence", 0.85)
        
        # Get learned threshold from the learning data
        type_data = self.learning_data.get("suggestion_types", {}).get(suggestion_type, {})
        learned_threshold = type_data.get("confidence_threshold", 0.7)
        
        # Use the higher (more conservative) of the two
        return max(type_min, learned_threshold)
    
    def check_daily_limit(self) -> Tuple[bool, int, int]:
        """Check if we're within daily action limits"""
        max_per_day = self.config.get("max_actions_per_day", 20)
        
        # Count actions from today
        today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        today_actions = self._count_actions_since(today_start)
        
        can_proceed = today_actions < max_per_day
        return can_proceed, today_actions, max_per_day
    
    def _count_actions_since(self, since: datetime) -> int:
        """Count actions taken since a given datetime"""
        if not os.path.exists(AUTO_SUGGEST_LOG):
            return 0
        
        count = 0
        with open(AUTO_SUGGEST_LOG, 'r') as f:
            for line in f:
                if line.strip():
                    try:
                        action = json.loads(line)
                        action_time = datetime.fromisoformat(action.get("timestamp", ""))
                        if action_time >= since and not action.get("dry_run", False):
                            count += 1
                    except (json.JSONDecodeError, ValueError):
                        continue
        
        return count
    
    def matches_pattern(self, text: str, patterns: List[str]) -> bool:
        """Check if text matches any pattern in the list"""
        import fnmatch
        for pattern in patterns:
            if fnmatch.fnmatch(text.lower(), pattern.lower()):
                return True
        return False
    
    def is_allowed(self, suggestion: Dict) -> Tuple[bool, str]:
        """Check if a suggestion is allowed to be auto-implemented"""
        # Check blacklist first
        blacklist = self.config.get("blacklist_patterns", [])
        suggestion_text = suggestion.get("description", "") + " " + suggestion.get("file_path", "")
        
        if self.matches_pattern(suggestion_text, blacklist):
            return False, "Matches blacklist pattern"
        
        # Check whitelist (if whitelist exists, must match it)
        whitelist = self.config.get("whitelist_patterns", [])
        if whitelist and not self.matches_pattern(suggestion_text, whitelist):
            return False, "Does not match whitelist pattern"
        
        # Check file size if applicable
        file_path = suggestion.get("file_path")
        if file_path and os.path.exists(file_path):
            max_size_kb = self.config["safety"].get("max_file_size_kb", 500)
            size_kb = os.path.getsize(file_path) / 1024
            if size_kb > max_size_kb:
                return False, f"File too large ({size_kb:.1f}KB > {max_size_kb}KB)"
        
        return True, "OK"
    
    def create_backup(self, suggestion: Dict) -> Optional[str]:
        """Create backup before implementing suggestion"""
        if not self.config["safety"].get("require_backup", True):
            return None
        
        file_path = suggestion.get("file_path")
        if not file_path or not os.path.exists(file_path):
            return None
        
        # Create timestamped backup
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{os.path.basename(file_path)}.{timestamp}.backup"
        backup_path = self.undo_dir / backup_name
        
        shutil.copy2(file_path, backup_path)
        
        return str(backup_path)
    
    def implement_suggestion(self, suggestion: Dict, dry_run: bool = None) -> Dict:
        """Implement a single suggestion"""
        if dry_run is None:
            dry_run = self.config.get("dry_run", True)
        
        result = {
            "suggestion_id": suggestion.get("id"),
            "type": suggestion.get("type"),
            "description": suggestion.get("description", ""),
            "confidence": suggestion.get("confidence", 0),
            "timestamp": datetime.now().isoformat(),
            "dry_run": dry_run,
            "success": False,
            "error": None,
            "backup_path": None
        }
        
        try:
            # Check if allowed
            allowed, reason = self.is_allowed(suggestion)
            if not allowed:
                result["error"] = f"Not allowed: {reason}"
                return result
            
            # Create backup if not dry run
            if not dry_run:
                result["backup_path"] = self.create_backup(suggestion)
            
            # Implement based on type
            suggestion_type = suggestion.get("type")
            
            if suggestion_type == "task_suggestion":
                success = self._implement_task_suggestion(suggestion, dry_run)
            elif suggestion_type == "project_suggestion":
                success = self._implement_project_suggestion(suggestion, dry_run)
            elif suggestion_type == "area_assignment":
                success = self._implement_area_assignment(suggestion, dry_run)
            elif suggestion_type == "moc_suggestion":
                success = self._implement_moc_creation(suggestion, dry_run)
            elif suggestion_type == "area_suggestion":
                success = self._implement_area_creation(suggestion, dry_run)
            else:
                result["error"] = f"Unsupported suggestion type: {suggestion_type}"
                return result
            
            result["success"] = success
            
            # Record decision in learning system if not dry run
            if not dry_run and success:
                record_decision(
                    suggestion_type=suggestion_type,
                    decision="accept",
                    confidence=suggestion.get("confidence", 0),
                    suggestion_id=suggestion.get("id"),
                    metadata={"auto_implemented": True}
                )
            
        except Exception as e:
            result["error"] = str(e)
            result["success"] = False
        
        return result
    
    def _implement_task_suggestion(self, suggestion: Dict, dry_run: bool) -> bool:
        """Implement a task creation suggestion"""
        details = suggestion.get("details", {})
        title = details.get("title", "")
        
        if not title:
            return False
        
        if dry_run:
            print(f"  [DRY RUN] Would create task: {title}")
            return True
        
        # Create task using gtd CLI
        # First, write task content to temp file or use stdin
        cmd = ["gtd", "add", title]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            # Mark suggestion as implemented
            suggestion_file = suggestion.get("file_path")
            if suggestion_file and os.path.exists(suggestion_file):
                try:
                    with open(suggestion_file, 'r') as f:
                        data = json.load(f)
                    data["status"] = "implemented"
                    data["implemented_at"] = datetime.now().isoformat()
                    with open(suggestion_file, 'w') as f:
                        json.dump(data, f, indent=2)
                except Exception:
                    pass
        
        return result.returncode == 0
    
    def _implement_project_suggestion(self, suggestion: Dict, dry_run: bool) -> bool:
        """Implement a task-to-project assignment suggestion"""
        details = suggestion.get("details", {})
        task_id = details.get("task_id", "")
        suggested_project = details.get("suggested_project", "")
        
        if not task_id or not suggested_project:
            return False
        
        if dry_run:
            print(f"  [DRY RUN] Would move task {task_id} to project {suggested_project}")
            return True
        
        # Use gtd-task-organize helper to move task
        cmd = ["gtd-task-organize", "move", task_id, suggested_project]
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        return result.returncode == 0
    
    def _implement_area_assignment(self, suggestion: Dict, dry_run: bool) -> bool:
        """Implement an area assignment to a project"""
        details = suggestion.get("details", {})
        project_slug = details.get("project_slug", "")
        suggested_area = details.get("suggested_area", "")
        
        if not project_slug or not suggested_area:
            return False
        
        if dry_run:
            print(f"  [DRY RUN] Would assign project '{project_slug}' to area '{suggested_area}'")
            return True
        
        # Use knowledge_org_implement.py to handle this
        implementation_script = Path(__file__).parent / "knowledge_org_implement.py"
        if implementation_script.exists():
            cmd = ["python3", str(implementation_script), "--auto", "--type", "area_assignment",
                   "--project", project_slug, "--area", suggested_area]
            result = subprocess.run(cmd, capture_output=True, text=True)
            return result.returncode == 0
        
        # Fallback: try to update project frontmatter directly
        try:
            projects_path = Path(GTD_BASE_DIR) / "1-projects" / project_slug / "README.md"
            if projects_path.exists():
                # Read, update frontmatter, write back
                with open(projects_path, 'r') as f:
                    content = f.read()
                
                # Simple frontmatter update (you may want to use a proper parser)
                if "area:" in content:
                    content = content.replace(f"area:", f"area: {suggested_area}")
                else:
                    # Add area to frontmatter
                    if content.startswith("---"):
                        parts = content.split("---", 2)
                        if len(parts) >= 3:
                            parts[1] += f"\narea: {suggested_area}\n"
                            content = "---".join(parts)
                
                with open(projects_path, 'w') as f:
                    f.write(content)
                
                return True
        except Exception as e:
            print(f"Error assigning area: {e}", file=sys.stderr)
        
        return False
    
    def _implement_moc_creation(self, suggestion: Dict, dry_run: bool) -> bool:
        """Implement a MoC creation suggestion"""
        details = suggestion.get("details", {})
        name = details.get("name", "")
        
        if not name:
            return False
        
        if dry_run:
            print(f"  [DRY RUN] Would create MoC: {name}")
            return True
        
        # Use gtd-moc CLI
        cmd = ["gtd-moc", "create", name]
        result = subprocess.run(cmd, capture_output=True, text=True, input="\n")
        
        return result.returncode == 0
    
    def _implement_area_creation(self, suggestion: Dict, dry_run: bool) -> bool:
        """Implement an area creation suggestion"""
        details = suggestion.get("details", {})
        name = details.get("name", "")
        
        if not name:
            return False
        
        if dry_run:
            print(f"  [DRY RUN] Would create Area: {name}")
            return True
        
        # Use gtd-area CLI
        cmd = ["gtd-area", "create", name]
        result = subprocess.run(cmd, capture_output=True, text=True, input="\n")
        
        return result.returncode == 0
    
    def log_action(self, action: Dict):
        """Log an action to the audit trail"""
        with open(AUTO_SUGGEST_LOG, 'a') as f:
            f.write(json.dumps(action) + "\n")
    
    def get_recent_actions(self, limit: int = 20, only_successful: bool = True) -> List[Dict]:
        """Get recent actions from the log"""
        if not os.path.exists(AUTO_SUGGEST_LOG):
            return []
        
        actions = []
        with open(AUTO_SUGGEST_LOG, 'r') as f:
            for line in f:
                if line.strip():
                    try:
                        action = json.loads(line)
                        if only_successful and not action.get("success"):
                            continue
                        if action.get("dry_run"):
                            continue
                        actions.append(action)
                    except json.JSONDecodeError:
                        continue
        
        # Return most recent first
        return list(reversed(actions))[:limit]
    
    def undo_action(self, action_id: str = None, index: int = None) -> Tuple[bool, str]:
        """
        Undo a specific action by ID or by index (0 = most recent).
        
        Returns: (success, message)
        """
        # Get recent actions
        actions = self.get_recent_actions(limit=100, only_successful=True)
        
        if not actions:
            return False, "No actions to undo"
        
        # Find action to undo
        action_to_undo = None
        if index is not None:
            if 0 <= index < len(actions):
                action_to_undo = actions[index]
            else:
                return False, f"Invalid index: {index} (only {len(actions)} actions available)"
        elif action_id:
            for action in actions:
                if action.get("suggestion_id") == action_id:
                    action_to_undo = action
                    break
            if not action_to_undo:
                return False, f"Action not found: {action_id}"
        else:
            # Undo most recent
            action_to_undo = actions[0]
        
        # Check if already undone
        if action_to_undo.get("undone"):
            return False, "Action already undone"
        
        # Undo based on type
        suggestion_type = action_to_undo.get("type")
        success = False
        message = ""
        
        try:
            if suggestion_type == "task_suggestion":
                success, message = self._undo_task_creation(action_to_undo)
            elif suggestion_type == "project_suggestion":
                success, message = self._undo_project_assignment(action_to_undo)
            elif suggestion_type == "area_assignment":
                success, message = self._undo_area_assignment(action_to_undo)
            elif suggestion_type == "moc_suggestion":
                success, message = self._undo_moc_creation(action_to_undo)
            elif suggestion_type == "area_suggestion":
                success, message = self._undo_area_creation(action_to_undo)
            else:
                return False, f"Cannot undo type: {suggestion_type}"
            
            if success:
                # Mark as undone in the log
                self._mark_action_undone(action_to_undo)
                
                # Update learning system - record as rejected
                record_decision(
                    suggestion_type=suggestion_type,
                    decision="reject",
                    confidence=action_to_undo.get("confidence", 0),
                    suggestion_id=action_to_undo.get("suggestion_id"),
                    metadata={"undone": True, "auto_implemented": True}
                )
        
        except Exception as e:
            return False, f"Error undoing action: {e}"
        
        return success, message
    
    def _mark_action_undone(self, action: Dict):
        """Mark an action as undone in the log"""
        # Append an undo record
        undo_record = {
            "action": "undo",
            "undone_suggestion_id": action.get("suggestion_id"),
            "undone_at": datetime.now().isoformat(),
            "original_action": action
        }
        self.log_action(undo_record)
    
    def _undo_task_creation(self, action: Dict) -> Tuple[bool, str]:
        """Undo a task creation"""
        # Task was created - we need to delete or archive it
        # This is tricky because we don't have the task ID stored
        # For now, return instructions for manual undo
        description = action.get("description", "")
        return True, f"To undo task creation '{description}', manually delete the task from your inbox"
    
    def _undo_project_assignment(self, action: Dict) -> Tuple[bool, str]:
        """Undo a project assignment"""
        backup_path = action.get("backup_path")
        
        if backup_path and os.path.exists(backup_path):
            # Restore from backup
            # Extract original path from backup name
            backup_file = Path(backup_path)
            original_name = backup_file.stem.rsplit('.', 1)[0]  # Remove timestamp
            
            # Find the original file (would need more context)
            return True, f"Backup available at: {backup_path}. Restore manually to undo."
        
        return True, "No backup found. Manual undo required."
    
    def _undo_area_assignment(self, action: Dict) -> Tuple[bool, str]:
        """Undo an area assignment"""
        backup_path = action.get("backup_path")
        
        if backup_path and os.path.exists(backup_path):
            # Could restore project README from backup
            return True, f"Backup available at: {backup_path}. Use 'gtd-auto-suggest restore {backup_path}' to undo."
        
        return True, "Manual undo: remove area assignment from project frontmatter"
    
    def _undo_moc_creation(self, action: Dict) -> Tuple[bool, str]:
        """Undo a MoC creation"""
        # MoC was created - could delete it
        # For safety, we'll just provide instructions
        description = action.get("description", "")
        return True, f"To undo '{description}', manually delete the MoC file"
    
    def _undo_area_creation(self, action: Dict) -> Tuple[bool, str]:
        """Undo an area creation"""
        description = action.get("description", "")
        return True, f"To undo '{description}', manually delete the area file"
    
    def restore_from_backup(self, backup_path: str) -> Tuple[bool, str]:
        """Restore a file from backup"""
        if not os.path.exists(backup_path):
            return False, f"Backup not found: {backup_path}"
        
        # Parse backup filename to get original path
        backup_file = Path(backup_path)
        # Backup format: filename.timestamp.backup
        parts = backup_file.stem.split('.')
        if len(parts) < 2:
            return False, "Invalid backup filename format"
        
        original_name = '.'.join(parts[:-1])  # Remove timestamp
        
        # This is simplified - in practice, you'd need to know the original directory
        return False, "Restore not yet fully implemented - manual restore required"
    
    def get_statistics(self, days: int = 30) -> Dict[str, Any]:
        """Generate aggregated statistics"""
        if not os.path.exists(AUTO_SUGGEST_LOG):
            return {"error": "No action log found"}
        
        cutoff_date = datetime.now() - timedelta(days=days)
        
        stats = {
            "period_days": days,
            "total_actions": 0,
            "successful_actions": 0,
            "failed_actions": 0,
            "dry_run_actions": 0,
            "undone_actions": 0,
            "by_type": {},
            "by_date": {},
            "success_rate": 0.0,
            "actions_per_day": 0.0,
            "most_common_type": None,
            "most_common_failure": None
        }
        
        with open(AUTO_SUGGEST_LOG, 'r') as f:
            for line in f:
                if not line.strip():
                    continue
                
                try:
                    action = json.loads(line)
                    
                    # Skip undo records
                    if action.get("action") == "undo":
                        stats["undone_actions"] += 1
                        continue
                    
                    # Check date
                    timestamp_str = action.get("timestamp", "")
                    if timestamp_str:
                        try:
                            action_date = datetime.fromisoformat(timestamp_str)
                            if action_date < cutoff_date:
                                continue
                            
                            date_key = action_date.strftime("%Y-%m-%d")
                            stats["by_date"][date_key] = stats["by_date"].get(date_key, 0) + 1
                        except ValueError:
                            pass
                    
                    stats["total_actions"] += 1
                    
                    if action.get("dry_run"):
                        stats["dry_run_actions"] += 1
                        continue
                    
                    if action.get("success"):
                        stats["successful_actions"] += 1
                    else:
                        stats["failed_actions"] += 1
                    
                    # Count by type
                    action_type = action.get("type", "unknown")
                    if action_type not in stats["by_type"]:
                        stats["by_type"][action_type] = {
                            "total": 0,
                            "successful": 0,
                            "failed": 0
                        }
                    
                    stats["by_type"][action_type]["total"] += 1
                    if action.get("success"):
                        stats["by_type"][action_type]["successful"] += 1
                    else:
                        stats["by_type"][action_type]["failed"] += 1
                
                except json.JSONDecodeError:
                    continue
        
        # Calculate derived statistics
        if stats["total_actions"] > 0:
            non_dry_run = stats["successful_actions"] + stats["failed_actions"]
            if non_dry_run > 0:
                stats["success_rate"] = stats["successful_actions"] / non_dry_run
            stats["actions_per_day"] = stats["total_actions"] / days
        
        # Find most common type
        if stats["by_type"]:
            most_common = max(stats["by_type"].items(), key=lambda x: x[1]["total"])
            stats["most_common_type"] = most_common[0]
        
        return stats
    
    def rotate_logs(self, max_size_mb: int = 10) -> bool:
        """Rotate log file if it's too large"""
        if not os.path.exists(AUTO_SUGGEST_LOG):
            return False
        
        file_size_mb = os.path.getsize(AUTO_SUGGEST_LOG) / (1024 * 1024)
        
        if file_size_mb < max_size_mb:
            print(f"Log file size ({file_size_mb:.2f}MB) is under threshold ({max_size_mb}MB)")
            return False
        
        # Rotate: rename current log and start fresh
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        rotated_name = f"{AUTO_SUGGEST_LOG}.{timestamp}"
        
        shutil.move(AUTO_SUGGEST_LOG, rotated_name)
        
        print(f"Log rotated: {rotated_name}")
        print(f"Size: {file_size_mb:.2f}MB")
        
        # Optionally compress the rotated log
        try:
            import gzip
            with open(rotated_name, 'rb') as f_in:
                with gzip.open(f"{rotated_name}.gz", 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            os.remove(rotated_name)
            print(f"Compressed to: {rotated_name}.gz")
        except Exception:
            pass  # Compression is optional
        
        return True
    
    def send_discord_notification(self, title: str, message: str, color: int = 5814783) -> bool:
        """Send a notification to Discord webhook if configured"""
        if not GTD_DISCORD_WEBHOOK_URL:
            return False
        
        if not self.config.get("notifications", {}).get("discord_enabled", True):
            return False
        
        try:
            import urllib.request
            import json as json_module
            from datetime import timezone
            
            # Build Discord embed payload
            payload = {
                "embeds": [{
                    "title": title,
                    "description": message,
                    "color": color,  # Default: blue (5814783), green: 5763719, red: 15158332, yellow: 16776960
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }]
            }
            
            # Send to Discord
            data = json_module.dumps(payload).encode('utf-8')
            req = urllib.request.Request(
                GTD_DISCORD_WEBHOOK_URL,
                data=data,
                headers={'Content-Type': 'application/json'}
            )
            
            with urllib.request.urlopen(req, timeout=5) as response:
                return response.status == 204
        except Exception:
            # Silently fail - don't break auto-suggest if Discord fails
            return False
    
    def notify_action(self, action: Dict):
        """Send Discord notification for an action"""
        if not self.config.get("notifications", {}).get("notify_on_action", True):
            return
        
        if action.get("dry_run"):
            return  # Don't notify for dry runs
        
        if action.get("success"):
            color = 5763719  # Green
            emoji = "✅"
        else:
            color = 15158332  # Red
            emoji = "❌"
        
        description = action.get("description", "Unknown action")
        suggestion_type = action.get("type", "unknown")
        confidence = action.get("confidence", 0)
        
        message = f"{emoji} **{description}**\n\n"
        message += f"**Type:** {suggestion_type}\n"
        message += f"**Confidence:** {confidence:.0%}\n"
        
        if not action.get("success"):
            error = action.get("error", "Unknown error")
            message += f"**Error:** {error}\n"
        
        self.send_discord_notification("🤖 Auto-Suggest Action", message, color=color)
    
    def notify_daily_summary(self, summary: Dict):
        """Send Discord notification with daily summary"""
        if not self.config.get("notifications", {}).get("notify_daily_summary", True):
            return
        
        if summary.get("dry_run"):
            return  # Don't notify for dry runs
        
        actions_taken = summary.get("actions_taken", 0)
        actions_failed = summary.get("actions_failed", 0)
        actions_skipped = summary.get("actions_skipped", 0)
        
        if actions_taken == 0 and actions_failed == 0:
            return  # No actions, no notification
        
        success_rate = 0
        if actions_taken + actions_failed > 0:
            success_rate = actions_taken / (actions_taken + actions_failed)
        
        message = f"**Summary for {datetime.now().strftime('%Y-%m-%d')}**\n\n"
        message += f"✅ **Successful:** {actions_taken}\n"
        message += f"❌ **Failed:** {actions_failed}\n"
        message += f"⏭️ **Skipped:** {actions_skipped}\n"
        message += f"📊 **Success Rate:** {success_rate:.0%}\n\n"
        
        # Add breakdown by type
        results = summary.get("results", [])
        type_counts = {}
        for result in results:
            if result.get("success"):
                result_type = result.get("type", "unknown")
                type_counts[result_type] = type_counts.get(result_type, 0) + 1
        
        if type_counts:
            message += "**By Type:**\n"
            for type_name, count in sorted(type_counts.items(), key=lambda x: x[1], reverse=True):
                message += f"  • {type_name}: {count}\n"
        
        color = 5763719 if success_rate >= 0.8 else 16776960  # Green if good, yellow if mediocre
        self.send_discord_notification("📊 Auto-Suggest Daily Summary", message, color=color)
    
    def notify_threshold_adjustment(self, suggestion_type: str, old_threshold: float, new_threshold: float, reason: str):
        """Send Discord notification when threshold is auto-adjusted"""
        if not self.config.get("notifications", {}).get("notify_threshold_adjustment", True):
            return
        
        direction = "↑ Increased" if new_threshold > old_threshold else "↓ Decreased"
        change = abs(new_threshold - old_threshold)
        
        message = f"**Type:** {suggestion_type}\n"
        message += f"**Old Threshold:** {old_threshold:.0%}\n"
        message += f"**New Threshold:** {new_threshold:.0%}\n"
        message += f"**Change:** {direction} by {change:.0%}\n\n"
        message += f"**Reason:** {reason}\n"
        
        self.send_discord_notification("⚙️ Auto-Suggest Threshold Adjusted", message, color=5814783)
    
    def adjust_smart_thresholds(self) -> Dict[str, Any]:
        """
        Analyze acceptance rates and automatically adjust confidence thresholds.
        
        Returns dictionary with adjustments made.
        """
        smart_config = self.config.get("smart_thresholds", {})
        
        if not smart_config.get("enabled", False):
            return {"enabled": False}
        
        min_threshold = smart_config.get("min_threshold", 0.70)
        max_threshold = smart_config.get("max_threshold", 0.98)
        min_samples = smart_config.get("min_samples", 20)
        target_rate = smart_config.get("target_acceptance_rate", 0.85)
        
        adjustments = {
            "enabled": True,
            "adjustments_made": [],
            "skipped": []
        }
        
        # Get acceptance rates per type from learning system
        for suggestion_type in ["task_suggestion", "project_suggestion", "area_assignment", 
                                "moc_suggestion", "area_suggestion"]:
            
            # Get stats for this type
            try:
                acceptance_rate = get_acceptance_rate(suggestion_type)
                stats = get_stats_summary(suggestion_type)
                
                total_decisions = stats.get("decision_count", 0)
                
                if total_decisions < min_samples:
                    adjustments["skipped"].append({
                        "type": suggestion_type,
                        "reason": f"Not enough samples ({total_decisions} < {min_samples})"
                    })
                    continue
                
                # Get current threshold
                current_threshold = self.get_min_confidence(suggestion_type)
                
                # Calculate desired adjustment
                # If acceptance rate is high, we can lower threshold (show more suggestions)
                # If acceptance rate is low, raise threshold (show fewer, better suggestions)
                
                new_threshold = current_threshold
                
                if acceptance_rate > target_rate + 0.10:  # Accepting too much
                    # Can afford to lower threshold (show more suggestions)
                    new_threshold = max(min_threshold, current_threshold - 0.05)
                    reason = f"High acceptance rate ({acceptance_rate:.0%}) allows lowering threshold"
                
                elif acceptance_rate < target_rate - 0.10:  # Rejecting too much
                    # Need to raise threshold (be more selective)
                    new_threshold = min(max_threshold, current_threshold + 0.05)
                    reason = f"Low acceptance rate ({acceptance_rate:.0%}) requires raising threshold"
                
                else:
                    # In acceptable range, no adjustment needed
                    adjustments["skipped"].append({
                        "type": suggestion_type,
                        "reason": f"Acceptance rate ({acceptance_rate:.0%}) is within target range"
                    })
                    continue
                
                if new_threshold != current_threshold:
                    # Update configuration
                    if suggestion_type in self.config["type_configs"]:
                        self.config["type_configs"][suggestion_type]["min_confidence"] = new_threshold
                        self.save_config()
                        
                        adjustments["adjustments_made"].append({
                            "type": suggestion_type,
                            "old_threshold": current_threshold,
                            "new_threshold": new_threshold,
                            "acceptance_rate": acceptance_rate,
                            "reason": reason
                        })
                        
                        # Send notification
                        self.notify_threshold_adjustment(suggestion_type, current_threshold, new_threshold, reason)
                
            except Exception as e:
                adjustments["skipped"].append({
                    "type": suggestion_type,
                    "reason": f"Error: {e}"
                })
        
        return adjustments
    
    def get_pending_suggestions(self) -> List[Dict]:
        """Get all pending suggestions from various sources"""
        suggestions = []
        
        # Source 1: Task suggestions from gtd_smart_suggestions.py
        suggestions.extend(self._get_task_suggestions())
        
        # Source 2: Knowledge organization suggestions
        suggestions.extend(self._get_knowledge_org_suggestions())
        
        # Source 3: Task organization (project assignment) suggestions  
        suggestions.extend(self._get_task_organization_suggestions())
        
        return suggestions
    
    def check_pending_task_completions(self, days: int = 7) -> Dict[str, Any]:
        """
        Check for tasks mentioned as completed in logs that need review.
        
        Returns dict with:
        - count: Number of potential completions found
        - completions: List of completion details
        - has_pending: Boolean if any need review
        """
        try:
            # Import here to avoid circular dependencies
            from gtd_progress_analyzer import analyze_completions_for_tasks
            
            analysis = analyze_completions_for_tasks(days=days)
            potential = analysis.get("potential_completions", [])
            
            return {
                "count": len(potential),
                "completions": potential,
                "has_pending": len(potential) > 0,
                "analysis_date": analysis.get("analysis_date")
            }
        except Exception as e:
            # Silently fail if progress analyzer not available
            return {
                "count": 0,
                "completions": [],
                "has_pending": False,
                "error": str(e)
            }
    
    def notify_task_completions_available(self, completions_info: Dict[str, Any]) -> bool:
        """Send notification when task completions need review."""
        if not completions_info.get("has_pending"):
            return False
        
        count = completions_info.get("count", 0)
        if count == 0:
            return False
        
        # Build notification message
        title = "📋 Task Completions Need Review"
        
        if count == 1:
            completion = completions_info.get("completions", [{}])[0]
            desc = completion.get("completion", {}).get("description", "task")
            message = f"1 task completion found: {desc[:50]}"
        else:
            message = f"{count} task completions found in recent logs"
        
        subtitle = f"Run 'gtd-review-task-completions' to review"
        
        # Send Discord notification
        discord_msg = f"**{title}**\n\n"
        discord_msg += f"**{message}**\n\n"
        discord_msg += f"📋 **Review:** Run `gtd-review-task-completions`\n"
        discord_msg += f"🔍 **Dry Run:** `gtd-review-task-completions --dry-run`"
        
        self.send_discord_notification(title, discord_msg, color=16776960)  # Yellow
        
        # Try to send local notification (macOS)
        try:
            import subprocess
            notify_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-notify"
            if notify_cmd.exists():
                subprocess.run(
                    [str(notify_cmd), title, message, subtitle, "Glass"],
                    capture_output=True,
                    timeout=5
                )
        except Exception:
            pass  # Don't fail if local notification fails
        
        return True
    
    def _get_task_suggestions(self) -> List[Dict]:
        """Get pending task suggestions from suggestions directory"""
        suggestions = []
        suggestions_dir = Path(GTD_BASE_DIR) / "suggestions"
        
        if not suggestions_dir.exists():
            return suggestions
        
        # Read all suggestion JSON files
        for suggestion_file in suggestions_dir.glob("*.json"):
            try:
                with open(suggestion_file, 'r') as f:
                    suggestion = json.load(f)
                
                # Only include pending suggestions
                if suggestion.get("status") != "pending":
                    continue
                
                # Normalize to auto-suggest format
                normalized = {
                    "id": suggestion.get("id", suggestion_file.stem),
                    "type": "task_suggestion",
                    "confidence": suggestion.get("confidence", 0.5),
                    "description": suggestion.get("title", "Task suggestion"),
                    "file_path": str(suggestion_file),
                    "action": "create_task",
                    "details": {
                        "title": suggestion.get("title", ""),
                        "reason": suggestion.get("reason", ""),
                        "category": suggestion.get("category", "medium"),
                        "source_text": suggestion.get("source_text", ""),
                        "original_suggestion": suggestion
                    }
                }
                
                suggestions.append(normalized)
                
            except (json.JSONDecodeError, IOError) as e:
                print(f"Warning: Could not read suggestion file {suggestion_file}: {e}", file=sys.stderr)
                continue
        
        return suggestions
    
    def _get_knowledge_org_suggestions(self) -> List[Dict]:
        """Get knowledge organization suggestions (MoC/Area)"""
        suggestions = []
        results_dir = Path(GTD_BASE_DIR) / "knowledge_organization_results"
        
        if not results_dir.exists():
            return suggestions
        
        # Get most recent knowledge org results
        result_files = sorted(results_dir.glob("knowledge_org_*.json"), key=os.path.getmtime, reverse=True)
        
        if not result_files:
            return suggestions
        
        # Only process the most recent results file
        try:
            with open(result_files[0], 'r') as f:
                results = json.load(f)
            
            for suggestion in results.get("suggestions", []):
                # Map knowledge org types to auto-suggest types
                suggestion_type = suggestion.get("type")
                
                if suggestion_type == "area_assignment":
                    normalized = {
                        "id": f"area_assign_{suggestion.get('project_slug', 'unknown')}",
                        "type": "area_assignment",
                        "confidence": suggestion.get("confidence", 0.5),
                        "description": f"Assign project '{suggestion.get('project_name', '')}' to area '{suggestion.get('suggested_area', '')}'",
                        "file_path": None,
                        "action": "assign_area",
                        "details": {
                            "project_slug": suggestion.get("project_slug"),
                            "project_name": suggestion.get("project_name"),
                            "suggested_area": suggestion.get("suggested_area"),
                            "reason": suggestion.get("reason", ""),
                            "original_suggestion": suggestion
                        }
                    }
                
                elif suggestion_type == "moc_creation":
                    normalized = {
                        "id": f"moc_create_{suggestion.get('suggested_moc', '').replace(' ', '_')}",
                        "type": "moc_suggestion",
                        "confidence": suggestion.get("confidence", 0.5),
                        "description": f"Create MoC: '{suggestion.get('suggested_moc', '')}'",
                        "file_path": None,
                        "action": "create_moc",
                        "details": {
                            "name": suggestion.get("suggested_moc"),
                            "notes": suggestion.get("notes", []),
                            "theme": suggestion.get("theme", ""),
                            "reason": suggestion.get("reason", ""),
                            "original_suggestion": suggestion
                        }
                    }
                
                elif suggestion_type == "area_creation":
                    normalized = {
                        "id": f"area_create_{suggestion.get('suggested_area', '').replace(' ', '_')}",
                        "type": "area_suggestion",
                        "confidence": suggestion.get("confidence", 0.5),
                        "description": f"Create Area: '{suggestion.get('suggested_area', '')}'",
                        "file_path": None,
                        "action": "create_area",
                        "details": {
                            "name": suggestion.get("suggested_area"),
                            "theme": suggestion.get("theme", ""),
                            "frequency": suggestion.get("frequency", 0),
                            "reason": suggestion.get("reason", ""),
                            "original_suggestion": suggestion
                        }
                    }
                
                else:
                    continue  # Unknown type
                
                suggestions.append(normalized)
        
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Could not read knowledge org results: {e}", file=sys.stderr)
        
        return suggestions
    
    def _get_task_organization_suggestions(self) -> List[Dict]:
        """Get task-to-project organization suggestions"""
        suggestions = []
        
        # Get most recent bulk organize results
        result_files = sorted(Path(GTD_BASE_DIR).glob(".bulk_organize_results_*.json"), 
                            key=os.path.getmtime, reverse=True)
        
        if not result_files:
            return suggestions
        
        try:
            with open(result_files[0], 'r') as f:
                results = json.load(f)
            
            for suggestion in results.get("suggestions", []):
                suggested_project = suggestion.get("suggested_project")
                
                # Skip if no project suggested or already assigned
                if not suggested_project or suggested_project == "none":
                    continue
                
                # Skip if there was an error
                if "error" in suggestion:
                    continue
                
                normalized = {
                    "id": f"task_org_{suggestion.get('task_id', 'unknown')}",
                    "type": "project_suggestion",
                    "confidence": suggestion.get("confidence", 0.75),  # Default confidence if not provided
                    "description": f"Move task '{suggestion.get('task_name', '')}' to project '{suggested_project}'",
                    "file_path": None,
                    "action": "assign_project",
                    "details": {
                        "task_id": suggestion.get("task_id"),
                        "task_name": suggestion.get("task_name"),
                        "suggested_project": suggested_project,
                        "original_suggestion": suggestion
                    }
                }
                
                suggestions.append(normalized)
        
        except (json.JSONDecodeError, IOError) as e:
            print(f"Warning: Could not read task organization results: {e}", file=sys.stderr)
        
        return suggestions
    
    def run(self, dry_run: bool = None) -> Dict:
        """Run the auto-suggest system"""
        if dry_run is None:
            dry_run = self.config.get("dry_run", True)
        
        summary = {
            "timestamp": datetime.now().isoformat(),
            "dry_run": dry_run,
            "enabled": self.is_enabled(),
            "actions_taken": 0,
            "actions_skipped": 0,
            "actions_failed": 0,
            "daily_limit_reached": False,
            "results": []
        }
        
        # Check if enabled
        if not self.is_enabled():
            print("Auto-suggest is disabled globally")
            return summary
        
        # Check daily limit
        can_proceed, today_count, max_daily = self.check_daily_limit()
        if not can_proceed and not dry_run:
            print(f"Daily action limit reached: {today_count}/{max_daily}")
            summary["daily_limit_reached"] = True
            return summary
        
        # Get pending suggestions
        suggestions = self.get_pending_suggestions()
        
        if not suggestions:
            print("No pending suggestions found")
            return summary
        
        print(f"Found {len(suggestions)} pending suggestions")
        print(f"Mode: {'DRY RUN' if dry_run else 'LIVE'}")
        print(f"Daily limit: {today_count}/{max_daily} actions used")
        print()
        
        max_per_run = self.config.get("max_actions_per_run", 5)
        actions_this_run = 0
        
        for suggestion in suggestions:
            suggestion_type = suggestion.get("type")
            confidence = suggestion.get("confidence", 0)
            
            # Check if type is enabled
            if not self.is_enabled(suggestion_type):
                summary["actions_skipped"] += 1
                continue
            
            # Check confidence threshold
            min_confidence = self.get_min_confidence(suggestion_type)
            if confidence < min_confidence:
                summary["actions_skipped"] += 1
                continue
            
            # Check per-run limit
            if actions_this_run >= max_per_run:
                print(f"Reached per-run limit of {max_per_run} actions")
                break
            
            # Implement suggestion
            print(f"Processing: {suggestion.get('description', '')[:80]}")
            print(f"  Type: {suggestion_type}, Confidence: {confidence:.2%}")
            
            result = self.implement_suggestion(suggestion, dry_run)
            summary["results"].append(result)
            
            if result["success"]:
                summary["actions_taken"] += 1
                actions_this_run += 1
                print(f"  ✓ {'[DRY RUN] ' if dry_run else ''}Implemented successfully")
            else:
                summary["actions_failed"] += 1
                print(f"  ✗ Failed: {result.get('error', 'Unknown error')}")
            
            # Log action
            self.log_action(result)
            
            # Send Discord notification for action
            self.notify_action(result)
            
            print()
        
        # Check for pending task completions and notify
        if not dry_run:
            completions_info = self.check_pending_task_completions(days=7)
            if completions_info.get("has_pending"):
                self.notify_task_completions_available(completions_info)
        
        # Print summary
        print("\n" + "="*60)
        print(f"Auto-Suggest Summary ({'DRY RUN' if dry_run else 'LIVE'})")
        print("="*60)
        print(f"Total suggestions processed: {len(suggestions)}")
        print(f"Actions taken: {summary['actions_taken']}")
        print(f"Actions skipped: {summary['actions_skipped']}")
        print(f"Actions failed: {summary['actions_failed']}")
        print(f"Daily usage: {today_count + summary['actions_taken']}/{max_daily}")
        
        if dry_run:
            print("\nThis was a DRY RUN - no actual changes were made")
            print("To enable live mode, run: gtd-auto-suggest enable --live")
        else:
            # Send daily summary notification
            self.notify_daily_summary(summary)
        
        return summary


def main():
    """CLI interface for auto-suggest system"""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Auto-Suggest System")
    parser.add_argument("command", choices=["run", "status", "enable", "disable", "config", "history", "undo", "list-undo", "stats", "rotate-logs", "adjust-thresholds", "check-completions"],
                       help="Command to execute")
    parser.add_argument("--dry-run", action="store_true", help="Run in dry-run mode")
    parser.add_argument("--live", action="store_true", help="Run in live mode (actually implement suggestions)")
    parser.add_argument("--type", help="Suggestion type to configure")
    parser.add_argument("--value", help="Configuration value")
    parser.add_argument("--index", type=int, help="Index of action to undo (0 = most recent)")
    parser.add_argument("--id", help="ID of suggestion to undo")
    
    args = parser.parse_args()
    
    auto_suggest = AutoSuggestSystem()
    
    if args.command == "run":
        dry_run = not args.live if args.live else None
        summary = auto_suggest.run(dry_run=dry_run)
        sys.exit(0 if summary["actions_failed"] == 0 else 1)
    
    elif args.command == "status":
        print("Auto-Suggest Status")
        print("="*60)
        print(f"Global enabled: {auto_suggest.config['enabled']}")
        print(f"Dry-run mode: {auto_suggest.config['dry_run']}")
        print(f"Max actions per run: {auto_suggest.config['max_actions_per_run']}")
        print(f"Max actions per day: {auto_suggest.config['max_actions_per_day']}")
        print()
        
        can_proceed, today_count, max_daily = auto_suggest.check_daily_limit()
        print(f"Today's usage: {today_count}/{max_daily}")
        print()
        
        print("Type Configurations:")
        for type_name, type_config in auto_suggest.config["type_configs"].items():
            enabled = "✓" if type_config.get("enabled") else "✗"
            min_conf = type_config.get("min_confidence", 0.85)
            print(f"  {enabled} {type_name}: min_confidence={min_conf:.2%}")
    
    elif args.command == "enable":
        auto_suggest.config["enabled"] = True
        if args.live:
            auto_suggest.config["dry_run"] = False
            print("Auto-suggest enabled in LIVE mode")
            print("⚠️  Suggestions will be automatically implemented!")
        else:
            auto_suggest.config["dry_run"] = True
            print("Auto-suggest enabled in DRY-RUN mode")
            print("Run with --live to enable actual implementation")
        auto_suggest.save_config()
    
    elif args.command == "disable":
        auto_suggest.config["enabled"] = False
        auto_suggest.save_config()
        print("Auto-suggest disabled")
    
    elif args.command == "config":
        if args.type and args.value:
            # Update specific type configuration
            if args.type in auto_suggest.config["type_configs"]:
                if args.value.lower() in ["true", "false"]:
                    auto_suggest.config["type_configs"][args.type]["enabled"] = args.value.lower() == "true"
                else:
                    try:
                        confidence = float(args.value)
                        auto_suggest.config["type_configs"][args.type]["min_confidence"] = confidence
                    except ValueError:
                        print(f"Invalid value: {args.value}")
                        sys.exit(1)
                
                auto_suggest.save_config()
                print(f"Updated {args.type} configuration")
            else:
                print(f"Unknown type: {args.type}")
                sys.exit(1)
        else:
            # Show current config
            print(json.dumps(auto_suggest.config, indent=2))
    
    elif args.command == "history":
        if not os.path.exists(AUTO_SUGGEST_LOG):
            print("No action history found")
            return
        
        print("Auto-Suggest Action History (last 20)")
        print("="*60)
        
        with open(AUTO_SUGGEST_LOG, 'r') as f:
            lines = f.readlines()
            for line in lines[-20:]:
                if line.strip():
                    try:
                        action = json.loads(line)
                        timestamp = action.get("timestamp", "")[:19]
                        dry_run = "[DRY RUN] " if action.get("dry_run") else ""
                        success = "✓" if action.get("success") else "✗"
                        desc = action.get("description", "")[:50]
                        print(f"{timestamp} {success} {dry_run}{desc}")
                    except json.JSONDecodeError:
                        continue
    
    elif args.command == "list-undo":
        actions = auto_suggest.get_recent_actions(limit=20, only_successful=True)
        
        if not actions:
            print("No actions to undo")
            return
        
        print("Recent Actions (can be undone)")
        print("="*60)
        for idx, action in enumerate(actions):
            timestamp = action.get("timestamp", "")[:19]
            desc = action.get("description", "")[:50]
            suggestion_id = action.get("suggestion_id", "N/A")
            undone = " [UNDONE]" if action.get("undone") else ""
            print(f"{idx}: {timestamp} - {desc}{undone}")
            print(f"   ID: {suggestion_id}")
        
        print()
        print("To undo: gtd-auto-suggest undo --index <N>")
        print("         gtd-auto-suggest undo --id <suggestion_id>")
    
    elif args.command == "undo":
        if args.index is None and args.id is None:
            # Undo most recent
            success, message = auto_suggest.undo_action(index=0)
        elif args.index is not None:
            success, message = auto_suggest.undo_action(index=args.index)
        else:
            success, message = auto_suggest.undo_action(action_id=args.id)
        
        if success:
            print(f"✓ {message}")
        else:
            print(f"✗ {message}")
            sys.exit(1)
    
    elif args.command == "stats":
        days = args.value if args.value else 30
        try:
            days = int(days)
        except ValueError:
            days = 30
        
        stats = auto_suggest.get_statistics(days=days)
        
        if "error" in stats:
            print(f"Error: {stats['error']}")
            sys.exit(1)
        
        print(f"Auto-Suggest Statistics (last {stats['period_days']} days)")
        print("="*60)
        print()
        print(f"Total actions: {stats['total_actions']}")
        print(f"  Successful: {stats['successful_actions']}")
        print(f"  Failed: {stats['failed_actions']}")
        print(f"  Dry run: {stats['dry_run_actions']}")
        print(f"  Undone: {stats['undone_actions']}")
        print()
        print(f"Success rate: {stats['success_rate']:.1%}")
        print(f"Actions per day: {stats['actions_per_day']:.1f}")
        print()
        
        if stats['most_common_type']:
            print(f"Most common type: {stats['most_common_type']}")
        
        print()
        print("By Type:")
        for type_name, type_stats in sorted(stats['by_type'].items()):
            success_rate = type_stats['successful'] / type_stats['total'] if type_stats['total'] > 0 else 0
            print(f"  {type_name}:")
            print(f"    Total: {type_stats['total']}")
            print(f"    Success rate: {success_rate:.1%}")
        
        if stats['by_date']:
            print()
            print("Recent Activity (last 7 days):")
            sorted_dates = sorted(stats['by_date'].items(), reverse=True)[:7]
            for date, count in sorted_dates:
                print(f"  {date}: {count} actions")
    
    elif args.command == "rotate-logs":
        max_size = 10
        if args.value:
            try:
                max_size = int(args.value)
            except ValueError:
                pass
        
        rotated = auto_suggest.rotate_logs(max_size_mb=max_size)
        if not rotated:
            print("No rotation needed")
        sys.exit(0 if rotated else 0)
    
    elif args.command == "adjust-thresholds":
        print("Analyzing acceptance rates and adjusting thresholds...")
        print()
        
        result = auto_suggest.adjust_smart_thresholds()
        
        if not result.get("enabled"):
            print("Smart threshold adjustment is not enabled")
            print()
            print("To enable, add to your config:")
            print('  "smart_thresholds": {')
            print('    "enabled": true')
            print('  }')
            print()
            print("Or run:")
            print("  gtd-auto-suggest config --type smart_thresholds.enabled --value true")
            sys.exit(0)
        
        adjustments_made = result.get("adjustments_made", [])
        skipped = result.get("skipped", [])
        
        if adjustments_made:
            print("✓ Threshold Adjustments Made:")
            print("="*60)
            for adj in adjustments_made:
                print(f"\n{adj['type']}:")
                print(f"  Old threshold: {adj['old_threshold']:.0%}")
                print(f"  New threshold: {adj['new_threshold']:.0%}")
                print(f"  Acceptance rate: {adj['acceptance_rate']:.0%}")
                print(f"  Reason: {adj['reason']}")
        else:
            print("No adjustments needed")
        
        if skipped:
            print()
            print("Skipped Types:")
            print("="*60)
            for skip in skipped:
                print(f"  {skip['type']}: {skip['reason']}")
        
        print()
        print("Current configuration:")
        auto_suggest_cmd = AutoSuggestSystem()
        for type_name in ["task_suggestion", "project_suggestion", "area_assignment", 
                          "moc_suggestion", "area_suggestion"]:
            threshold = auto_suggest_cmd.get_min_confidence(type_name)
            print(f"  {type_name}: {threshold:.0%}")
    
    elif args.command == "check-completions":
        days = int(args.value) if args.value else 7
        try:
            days = int(days)
        except ValueError:
            days = 7
        
        auto_suggest = AutoSuggestSystem()
        completions_info = auto_suggest.check_pending_task_completions(days=days)
        
        count = completions_info.get("count", 0)
        
        if count == 0:
            print(f"✓ No task completions found in the last {days} days")
            print("All tasks appear to be up to date!")
        else:
            print(f"📋 Found {count} task completion(s) that need review")
            print()
            print("Top completions:")
            for i, completion in enumerate(completions_info.get("completions", [])[:5], 1):
                comp = completion.get("completion", {})
                desc = comp.get("description", "Unknown")
                matches = completion.get("matches", [])
                if matches:
                    task = matches[0].get("task", {})
                    task_title = task.get("title", "Unknown")
                    confidence = matches[0].get("confidence", 0)
                    print(f"  {i}. {desc}")
                    print(f"     Matches: {task_title} ({confidence:.0%} confidence)")
            if count > 5:
                print(f"  ... and {count - 5} more")
            print()
            print("To review: gtd-review-task-completions")
            print("Dry run:   gtd-review-task-completions --dry-run")
            
            # Send notification if enabled
            if not args.dry_run:
                auto_suggest.notify_task_completions_available(completions_info)
        
        sys.exit(0 if count == 0 else 1)


if __name__ == "__main__":
    main()
