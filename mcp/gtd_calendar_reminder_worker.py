#!/usr/bin/env python3
"""
GTD Calendar Reminder Worker
Background worker that checks for upcoming meeting reminders and sends notifications.
"""

import json
import os
import sys
import time
import signal
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

# Configuration
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
CALENDAR_CACHE_DIR = GTD_BASE_DIR / "calendar"
CALENDAR_CACHE_FILE = CALENDAR_CACHE_DIR / "cache.json"
REMINDERS_SENT_FILE = CALENDAR_CACHE_DIR / "reminders_sent.json"
DASHBOARD_CACHE_FILE = GTD_BASE_DIR / ".dashboard_cache.json"
LOG_FILE = Path("/tmp/calendar-reminder-worker.log")

# Update intervals
CALENDAR_CACHE_UPDATE_INTERVAL = 300  # Update calendar cache every 5 minutes
REMINDER_CHECK_INTERVAL = 60  # Check for reminders every 1 minute

# Load GTD config
def load_gtd_config() -> Dict[str, str]:
    """Load GTD configuration."""
    config = {}
    config_files = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config",
        Path.home() / ".gtd_config",
    ]
    
    for config_file in config_files:
        if config_file.exists():
            try:
                with open(config_file, "r") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            key, value = line.split("=", 1)
                            key = key.strip()
                            value = value.strip().strip('"').strip("'")
                            config[key] = value
            except Exception:
                pass
    
    return config

# Load calendar config
def load_calendar_config() -> Dict[str, Any]:
    """Load calendar configuration."""
    config = {}
    config_files = [
        Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_calendar",
        Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".gtd_config_calendar",
        Path.home() / ".gtd_config_calendar",
    ]
    
    for config_file in config_files:
        if config_file.exists():
            try:
                with open(config_file, "r") as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith("#") and "=" in line:
                            key, value = line.split("=", 1)
                            key = key.strip()
                            value = value.strip().strip('"').strip("'")
                            config[key] = value
            except Exception:
                pass
    
    return config

def log(message: str):
    """Write to log file."""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(LOG_FILE, "a") as f:
        f.write(f"[{timestamp}] {message}\n")

def load_calendar_cache() -> Dict[str, Any]:
    """Load calendar cache."""
    if not CALENDAR_CACHE_FILE.exists():
        return {"metadata": {}, "events": []}
    
    try:
        with open(CALENDAR_CACHE_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {"metadata": {}, "events": []}

def load_reminders_sent() -> Dict[str, Any]:
    """Load reminders sent tracking."""
    if not REMINDERS_SENT_FILE.exists():
        return {"reminders": []}
    
    try:
        with open(REMINDERS_SENT_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return {"reminders": []}

def save_reminders_sent(reminders_data: Dict[str, Any]):
    """Save reminders sent tracking."""
    CALENDAR_CACHE_DIR.mkdir(parents=True, exist_ok=True)
    with open(REMINDERS_SENT_FILE, "w") as f:
        json.dump(reminders_data, f, indent=2)

def was_reminder_sent(event_id: str, reminder_time_minutes: int) -> bool:
    """Check if reminder was already sent."""
    reminders_data = load_reminders_sent()
    reminders = reminders_data.get("reminders", [])
    
    for reminder in reminders:
        if (reminder.get("event_id") == event_id and 
            reminder.get("reminder_time_minutes") == reminder_time_minutes):
            return True
    
    return False

def mark_reminder_sent(event_id: str, reminder_time_minutes: int):
    """Mark reminder as sent."""
    reminders_data = load_reminders_sent()
    reminders = reminders_data.get("reminders", [])
    
    # Check if already exists
    found = False
    for reminder in reminders:
        if (reminder.get("event_id") == event_id and 
            reminder.get("reminder_time_minutes") == reminder_time_minutes):
            found = True
            reminder["sent_at"] = datetime.now().isoformat()
            break
    
    if not found:
        reminders.append({
            "event_id": event_id,
            "reminder_time_minutes": reminder_time_minutes,
            "sent_at": datetime.now().isoformat()
        })
    
    reminders_data["reminders"] = reminders
    save_reminders_sent(reminders_data)

def get_reminder_times() -> List[int]:
    """Get configured reminder times."""
    calendar_config = load_calendar_config()
    reminder_times_str = calendar_config.get("GTD_CALENDAR_REMINDER_TIMES", "15")
    
    # Parse comma-separated values
    reminder_times = []
    for time_str in reminder_times_str.split(","):
        try:
            reminder_times.append(int(time_str.strip()))
        except ValueError:
            continue
    
    if not reminder_times:
        reminder_times = [15]  # Default
    
    return reminder_times

def check_reminders() -> List[Dict[str, Any]]:
    """Check for upcoming meeting reminders."""
    cache_data = load_calendar_cache()
    events = cache_data.get("events", [])
    reminder_times = get_reminder_times()
    
    now = datetime.now()
    reminders_to_send = []
    
    for event in events:
        try:
            event_start = datetime.fromisoformat(event["start"].replace('Z', '+00:00'))
            
            # Check each reminder time
            for reminder_minutes_before in reminder_times:
                reminder_time = event_start - timedelta(minutes=reminder_minutes_before)
                
                # Check if we're within the reminder window (within 1 minute of reminder time)
                time_diff = (reminder_time - now).total_seconds()
                
                if 0 <= time_diff <= 60:  # Within 1 minute window
                    event_id = event.get("id", "")
                    
                    # Check if already sent
                    if not was_reminder_sent(event_id, reminder_minutes_before):
                        time_until = int((event_start - now).total_seconds() / 60)
                        reminders_to_send.append({
                            "event": event,
                            "reminder_minutes": reminder_minutes_before,
                            "event_start": event_start,
                            "time_until": time_until
                        })
        except Exception as e:
            log(f"Error processing event: {e}")
            continue
    
    return reminders_to_send

def send_notification(title: str, message: str, subtitle: str = "", sound: str = "Glass"):
    """Send macOS notification."""
    try:
        # Check if notifications are enabled
        gtd_config = load_gtd_config()
        notifications_enabled = gtd_config.get("GTD_NOTIFICATIONS", "true").lower() == "true"
        if not notifications_enabled:
            return
        
        # Try to use gtd-notify if available
        notify_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-notify"
        if not notify_cmd.exists():
            notify_cmd = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-notify"
        
        if notify_cmd.exists():
            import subprocess
            subprocess.run(
                [str(notify_cmd), title, message, subtitle, sound],
                timeout=5,
                stderr=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL
            )
        elif sys.platform == "darwin":
            # Use osascript directly
            import subprocess
            applescript = f'''
            display notification "{message}" with title "{title}" subtitle "{subtitle}" sound name "{sound}"
            '''
            subprocess.run(
                ["osascript", "-e", applescript],
                timeout=5,
                stderr=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL
            )
    except Exception as e:
        log(f"Error sending notification: {e}")

def send_reminder_notification(reminder_info: Dict[str, Any]):
    """Send notification for a meeting reminder."""
    event = reminder_info["event"]
    time_until = reminder_info["time_until"]
    event_start = reminder_info["event_start"]
    
    title = event.get("title", "Untitled")
    start_str = event_start.strftime("%-I:%M %p")
    location = event.get("location", "")
    calendar = event.get("calendar_display", event.get("calendar", ""))
    
    # Build message
    if time_until == 1:
        time_str = "1 minute"
    else:
        time_str = f"{time_until} minutes"
    
    message = f"Starts in {time_str} ({start_str})"
    
    # Build subtitle
    subtitle_parts = []
    if location:
        subtitle_parts.append(location)
    if calendar:
        subtitle_parts.append(calendar)
    subtitle = " • ".join(subtitle_parts) if subtitle_parts else ""
    
    # Send notification
    send_notification(
        title=f"🔔 Meeting Reminder: {title}",
        message=message,
        subtitle=subtitle,
        sound="Glass"
    )
    
    log(f"Sent reminder for: {title} (in {time_until} minutes)")

def update_calendar_cache():
    """Update calendar cache by calling gtd-calendar-fetch."""
    try:
        fetch_cmd = Path.home() / "code" / "dotfiles" / "bin" / "gtd-calendar-fetch"
        if not fetch_cmd.exists():
            fetch_cmd = Path.home() / "code" / "personal" / "dotfiles" / "bin" / "gtd-calendar-fetch"
        
        if fetch_cmd.exists():
            import subprocess
            result = subprocess.run(
                [str(fetch_cmd)],
                capture_output=True,
                timeout=30,
                text=True
            )
            if result.returncode == 0:
                log("Calendar cache updated successfully")
            else:
                log(f"Calendar cache update failed: {result.stderr}")
        else:
            log("gtd-calendar-fetch not found")
    except Exception as e:
        log(f"Error updating calendar cache: {e}")

def update_dashboard_cache():
    """Update dashboard cache with calendar reminder info."""
    try:
        cache_data = load_calendar_cache()
        events = cache_data.get("events", [])
        
        now = datetime.now()
        upcoming_reminders = []
        
        # Check for events in next 2 hours
        for event in events:
            try:
                event_start = datetime.fromisoformat(event["start"].replace('Z', '+00:00'))
                time_until = (event_start - now).total_seconds() / 60  # minutes
                
                # Events in next 2 hours
                if 0 <= time_until <= 120:
                    upcoming_reminders.append({
                        "title": event.get("title", "Untitled"),
                        "start": event_start.isoformat(),
                        "time_until_minutes": int(time_until),
                        "location": event.get("location", ""),
                        "calendar": event.get("calendar_display", event.get("calendar", ""))
                    })
            except Exception:
                continue
        
        # Sort by time
        upcoming_reminders.sort(key=lambda x: x["time_until_minutes"])
        
        # Update dashboard cache
        if DASHBOARD_CACHE_FILE.exists():
            with open(DASHBOARD_CACHE_FILE, "r") as f:
                dashboard_cache = json.load(f)
        else:
            dashboard_cache = {}
        
        dashboard_cache["calendar_reminders"] = {
            "upcoming": upcoming_reminders[:5],  # Top 5 upcoming
            "next_meeting": upcoming_reminders[0] if upcoming_reminders else None,
            "last_updated": datetime.now().isoformat()
        }
        
        with open(DASHBOARD_CACHE_FILE, "w") as f:
            json.dump(dashboard_cache, f, indent=2)
        
    except Exception as e:
        log(f"Error updating dashboard cache: {e}")

def main():
    """Main worker loop."""
    def signal_handler(signum, frame):
        log("Received shutdown signal, exiting...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Load config
    config = load_gtd_config()
    if "GTD_BASE_DIR" in config:
        global GTD_BASE_DIR, CALENDAR_CACHE_DIR, CALENDAR_CACHE_FILE
        global REMINDERS_SENT_FILE, DASHBOARD_CACHE_FILE
        GTD_BASE_DIR = Path(config["GTD_BASE_DIR"].replace("$HOME", str(Path.home())))
        CALENDAR_CACHE_DIR = GTD_BASE_DIR / "calendar"
        CALENDAR_CACHE_FILE = CALENDAR_CACHE_DIR / "cache.json"
        REMINDERS_SENT_FILE = CALENDAR_CACHE_DIR / "reminders_sent.json"
        DASHBOARD_CACHE_FILE = GTD_BASE_DIR / ".dashboard_cache.json"
    
    log("Calendar reminder worker starting...")
    log(f"Calendar cache file: {CALENDAR_CACHE_FILE}")
    log(f"Reminder check interval: {REMINDER_CHECK_INTERVAL} seconds")
    log(f"Calendar cache update interval: {CALENDAR_CACHE_UPDATE_INTERVAL} seconds")
    
    # Initial calendar cache update
    update_calendar_cache()
    update_dashboard_cache()
    
    last_cache_update = time.time()
    
    # Continuous loop
    while True:
        try:
            # Check for reminders
            reminders = check_reminders()
            for reminder_info in reminders:
                send_reminder_notification(reminder_info)
                # Mark as sent
                event_id = reminder_info["event"].get("id", "")
                reminder_minutes = reminder_info["reminder_minutes"]
                mark_reminder_sent(event_id, reminder_minutes)
            
            # Update dashboard cache
            update_dashboard_cache()
            
            # Update calendar cache periodically
            current_time = time.time()
            if current_time - last_cache_update >= CALENDAR_CACHE_UPDATE_INTERVAL:
                update_calendar_cache()
                last_cache_update = current_time
            
            # Sleep until next check
            time.sleep(REMINDER_CHECK_INTERVAL)
            
        except KeyboardInterrupt:
            log("Interrupted by user")
            break
        except Exception as e:
            log(f"Error in worker loop: {e}")
            time.sleep(REMINDER_CHECK_INTERVAL)

if __name__ == "__main__":
    main()
