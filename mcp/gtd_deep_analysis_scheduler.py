#!/usr/bin/env python3
"""
GTD Deep Analysis Automatic Scheduler
Automatically submits deep analysis jobs to the queue based on schedules and triggers.
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from gtd_mcp_server import queue_deep_analysis, GTD_BASE_DIR
except ImportError:
    print("Error: Could not import queue_deep_analysis from gtd_mcp_server")
    sys.exit(1)


def load_config() -> Dict:
    """Load configuration from config files."""
    config_paths = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_database",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config_database",
        Path.home() / ".gtd_config_database",
    ]
    
    config = {
        "auto_weekly_review": os.getenv("DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW", "false").lower() == "true",
        "weekly_review_day": os.getenv("DEEP_ANALYSIS_WEEKLY_REVIEW_DAY", "monday"),  # monday, tuesday, etc.
        "weekly_review_time": os.getenv("DEEP_ANALYSIS_WEEKLY_REVIEW_TIME", "09:00"),  # HH:MM format
        
        "auto_energy_analysis": os.getenv("DEEP_ANALYSIS_AUTO_ENERGY", "false").lower() == "true",
        "energy_analysis_interval_days": int(os.getenv("DEEP_ANALYSIS_ENERGY_INTERVAL", "3")),  # Every N days
        "energy_analysis_days": int(os.getenv("DEEP_ANALYSIS_ENERGY_DAYS", "7")),  # Analyze last N days
        
        "auto_insights": os.getenv("DEEP_ANALYSIS_AUTO_INSIGHTS", "false").lower() == "true",
        "insights_interval_days": int(os.getenv("DEEP_ANALYSIS_INSIGHTS_INTERVAL", "1")),  # Every N days
        
        "auto_connections": os.getenv("DEEP_ANALYSIS_AUTO_CONNECTIONS", "false").lower() == "true",
        "connections_interval_days": int(os.getenv("DEEP_ANALYSIS_CONNECTIONS_INTERVAL", "7")),  # Every N days
        
        # Event-driven triggers
        "trigger_energy_on_daily_log": os.getenv("DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG", "false").lower() == "true",
        "trigger_insights_on_content": os.getenv("DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT", "false").lower() == "true",
        "trigger_connections_on_task": os.getenv("DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK", "false").lower() == "true",
    }
    
    # Override with config file if present
    for config_path in config_paths:
        if config_path.exists():
            try:
                with open(config_path) as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip()
                            # Remove comments
                            if '#' in value:
                                value = value.split('#')[0].strip()
                            # Remove quotes
                            value = value.strip('"').strip("'")
                            # Handle variable expansion syntax like ${VAR:-default}
                            if value.startswith("${") and ":-" in value:
                                value = value.split(":-", 1)[1].rstrip("}")
                            
                            # Map config keys
                            if key == "DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW":
                                config["auto_weekly_review"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_WEEKLY_REVIEW_DAY":
                                config["weekly_review_day"] = value.lower()
                            elif key == "DEEP_ANALYSIS_WEEKLY_REVIEW_TIME":
                                config["weekly_review_time"] = value
                            elif key == "DEEP_ANALYSIS_AUTO_ENERGY":
                                config["auto_energy_analysis"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_ENERGY_INTERVAL":
                                try:
                                    config["energy_analysis_interval_days"] = int(value)
                                except ValueError:
                                    pass
                            elif key == "DEEP_ANALYSIS_ENERGY_DAYS":
                                try:
                                    config["energy_analysis_days"] = int(value)
                                except ValueError:
                                    pass
                            elif key == "DEEP_ANALYSIS_AUTO_INSIGHTS":
                                config["auto_insights"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_INSIGHTS_INTERVAL":
                                try:
                                    config["insights_interval_days"] = int(value)
                                except ValueError:
                                    pass
                            elif key == "DEEP_ANALYSIS_AUTO_CONNECTIONS":
                                config["auto_connections"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_CONNECTIONS_INTERVAL":
                                try:
                                    config["connections_interval_days"] = int(value)
                                except ValueError:
                                    pass
                            elif key == "DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG":
                                config["trigger_energy_on_daily_log"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT":
                                config["trigger_insights_on_content"] = value.lower() == "true"
                            elif key == "DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK":
                                config["trigger_connections_on_task"] = value.lower() == "true"
            except Exception as e:
                print(f"Warning: Could not read config file {config_path}: {e}")
    
    return config


def get_last_run_timestamp(analysis_type: str) -> Optional[datetime]:
    """Get the last run timestamp for an analysis type."""
    state_file = GTD_BASE_DIR / ".deep_analysis_scheduler_state.json"
    
    if not state_file.exists():
        return None
    
    try:
        with open(state_file) as f:
            state = json.load(f)
            timestamp_str = state.get(analysis_type)
            if timestamp_str:
                return datetime.fromisoformat(timestamp_str)
    except Exception:
        pass
    
    return None


def set_last_run_timestamp(analysis_type: str, timestamp: datetime):
    """Set the last run timestamp for an analysis type."""
    state_file = GTD_BASE_DIR / ".deep_analysis_scheduler_state.json"
    
    state = {}
    if state_file.exists():
        try:
            with open(state_file) as f:
                state = json.load(f)
        except Exception:
            pass
    
    state[analysis_type] = timestamp.isoformat()
    
    GTD_BASE_DIR.mkdir(parents=True, exist_ok=True)
    with open(state_file, 'w') as f:
        json.dump(state, f, indent=2)


def should_run_weekly_review(config: Dict) -> bool:
    """Check if weekly review should run based on schedule."""
    if not config["auto_weekly_review"]:
        return False
    
    now = datetime.now()
    
    # Check if it's the right day
    target_day = config["weekly_review_day"].lower()
    day_names = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
    current_day_name = day_names[now.weekday()]
    
    if current_day_name != target_day:
        return False
    
    # Check if it's past the scheduled time
    try:
        target_time = datetime.strptime(config["weekly_review_time"], "%H:%M").time()
        if now.time() < target_time:
            return False
    except ValueError:
        # Invalid time format, skip time check
        pass
    
    # Check if we already ran today
    last_run = get_last_run_timestamp("weekly_review")
    if last_run and last_run.date() == now.date():
        return False
    
    return True


def should_run_energy_analysis(config: Dict) -> bool:
    """Check if energy analysis should run based on interval."""
    if not config["auto_energy_analysis"]:
        return False
    
    last_run = get_last_run_timestamp("analyze_energy")
    if last_run:
        days_since = (datetime.now() - last_run).days
        if days_since < config["energy_analysis_interval_days"]:
            return False
    
    return True


def should_run_insights(config: Dict) -> bool:
    """Check if insights should run based on interval."""
    if not config["auto_insights"]:
        return False
    
    last_run = get_last_run_timestamp("generate_insights")
    if last_run:
        days_since = (datetime.now() - last_run).days
        if days_since < config["insights_interval_days"]:
            return False
    
    return True


def should_run_connections(config: Dict) -> bool:
    """Check if connections should run based on interval."""
    if not config["auto_connections"]:
        return False
    
    last_run = get_last_run_timestamp("find_connections")
    if last_run:
        days_since = (datetime.now() - last_run).days
        if days_since < config["connections_interval_days"]:
            return False
    
    return True


def trigger_energy_analysis_on_log(config: Dict) -> bool:
    """Trigger energy analysis when a new daily log is created."""
    if not config["trigger_energy_on_daily_log"]:
        return False
    
    # Check if a new daily log was created recently (last 5 minutes)
    daily_log_dir = Path(os.getenv("DAILY_LOG_DIR", str(Path.home() / "Documents" / "daily_logs")))
    today = datetime.now().date()
    log_file = daily_log_dir / f"{today.strftime('%Y-%m-%d')}.md"
    
    if log_file.exists():
        mtime = datetime.fromtimestamp(log_file.stat().st_mtime)
        if (datetime.now() - mtime).total_seconds() < 300:  # 5 minutes
            # New log created, check if we should trigger
            last_run = get_last_run_timestamp("analyze_energy")
            if not last_run or (datetime.now() - last_run).total_seconds() > 3600:  # At least 1 hour ago
                return True
    
    return False


def run_scheduled_analyses(config: Dict, dry_run: bool = False):
    """Run all scheduled analyses."""
    results = []
    
    # Weekly review
    if should_run_weekly_review(config):
        week_start = datetime.now() - timedelta(days=datetime.now().weekday())
        week_start_str = week_start.strftime("%Y-%m-%d")
        
        if dry_run:
            results.append(f"[DRY RUN] Would queue weekly_review for week {week_start_str}")
        else:
            status = queue_deep_analysis("weekly_review", {"week_start": week_start_str})
            set_last_run_timestamp("weekly_review", datetime.now())
            results.append(f"✅ Queued weekly_review: {status}")
    
    # Energy analysis (scheduled)
    if should_run_energy_analysis(config):
        days = config["energy_analysis_days"]
        
        if dry_run:
            results.append(f"[DRY RUN] Would queue analyze_energy for last {days} days")
        else:
            status = queue_deep_analysis("analyze_energy", {"days": days})
            set_last_run_timestamp("analyze_energy", datetime.now())
            results.append(f"✅ Queued analyze_energy: {status}")
    
    # Energy analysis (triggered by daily log)
    elif trigger_energy_analysis_on_log(config):
        days = config["energy_analysis_days"]
        
        if dry_run:
            results.append(f"[DRY RUN] Would queue analyze_energy (triggered by daily log)")
        else:
            status = queue_deep_analysis("analyze_energy", {"days": days})
            set_last_run_timestamp("analyze_energy", datetime.now())
            results.append(f"✅ Queued analyze_energy (triggered): {status}")
    
    # Insights
    if should_run_insights(config):
        if dry_run:
            results.append("[DRY RUN] Would queue generate_insights")
        else:
            status = queue_deep_analysis("generate_insights", {"focus": "general"})
            set_last_run_timestamp("generate_insights", datetime.now())
            results.append(f"✅ Queued generate_insights: {status}")
    
    # Connections
    if should_run_connections(config):
        if dry_run:
            results.append("[DRY RUN] Would queue find_connections")
        else:
            status = queue_deep_analysis("find_connections", {"scope": "all"})
            set_last_run_timestamp("find_connections", datetime.now())
            results.append(f"✅ Queued find_connections: {status}")
    
    return results


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Deep Analysis Automatic Scheduler")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be queued without actually queuing")
    parser.add_argument("--trigger", choices=["energy", "insights", "connections"], help="Trigger specific analysis (event-driven)")
    args = parser.parse_args()
    
    config = load_config()
    
    if args.trigger:
        # Event-driven trigger
        if args.trigger == "energy" and config["trigger_energy_on_daily_log"]:
            days = config["energy_analysis_days"]
            if args.dry_run:
                print("[DRY RUN] Would queue analyze_energy (triggered)")
            else:
                status = queue_deep_analysis("analyze_energy", {"days": days})
                set_last_run_timestamp("analyze_energy", datetime.now())
                print(f"✅ Queued analyze_energy (triggered): {status}")
        elif args.trigger == "insights" and config["trigger_insights_on_content"]:
            if args.dry_run:
                print("[DRY RUN] Would queue generate_insights (triggered)")
            else:
                status = queue_deep_analysis("generate_insights", {"focus": "general"})
                set_last_run_timestamp("generate_insights", datetime.now())
                print(f"✅ Queued generate_insights (triggered): {status}")
        elif args.trigger == "connections" and config["trigger_connections_on_task"]:
            if args.dry_run:
                print("[DRY RUN] Would queue find_connections (triggered)")
            else:
                status = queue_deep_analysis("find_connections", {"scope": "all"})
                set_last_run_timestamp("find_connections", datetime.now())
                print(f"✅ Queued find_connections (triggered): {status}")
    else:
        # Scheduled run
        results = run_scheduled_analyses(config, dry_run=args.dry_run)
        
        if results:
            for result in results:
                print(result)
        else:
            if args.dry_run:
                print("[DRY RUN] No analyses scheduled to run at this time")


if __name__ == "__main__":
    main()
