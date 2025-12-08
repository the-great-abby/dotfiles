#!/usr/bin/env python3
"""
GTD Google Health/Fitness Sync
Downloads health data from Google Fit (via Data Portability API or Takeout export)
and logs it to daily logs using gtd-healthkit-log

Supports two modes:
1. Data Portability API (automated, requires OAuth setup)
2. Google Takeout export (manual export, then process files)
"""

import json
import os
import sys
import subprocess
import argparse
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any

# Try to import Google API libraries
try:
    from google.oauth2.credentials import Credentials
    from google_auth_oauthlib.flow import InstalledAppFlow
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
    from googleapiclient.errors import HttpError
    GOOGLE_API_AVAILABLE = True
except ImportError:
    GOOGLE_API_AVAILABLE = False
    print("⚠️  Google API libraries not installed. Install with: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")

# Configuration
SCOPES = ['https://www.googleapis.com/auth/dataportability']
DATA_PORTABILITY_SERVICE = 'fitness'
HOME_DIR = Path.home()
DOTFILES_DIR = HOME_DIR / "code" / "dotfiles"
PERSONAL_DOTFILES_DIR = HOME_DIR / "code" / "personal" / "dotfiles"

# Find dotfiles directory
if DOTFILES_DIR.exists():
    DOTFILES_ROOT = DOTFILES_DIR
elif PERSONAL_DOTFILES_DIR.exists():
    DOTFILES_ROOT = PERSONAL_DOTFILES_DIR
else:
    DOTFILES_ROOT = Path(__file__).parent.parent

CONFIG_DIR = DOTFILES_ROOT / ".google_health"
CREDENTIALS_FILE = CONFIG_DIR / "credentials.json"
TOKEN_FILE = CONFIG_DIR / "token.json"
TAKEOUT_DIR = CONFIG_DIR / "takeout"


def ensure_config_dir():
    """Create config directory if it doesn't exist"""
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    TAKEOUT_DIR.mkdir(parents=True, exist_ok=True)


def get_gtd_healthkit_log():
    """Find the gtd-healthkit-log script"""
    paths = [
        "gtd-healthkit-log",
        str(DOTFILES_ROOT / "bin" / "gtd-healthkit-log"),
        str(HOME_DIR / "code" / "dotfiles" / "bin" / "gtd-healthkit-log"),
        str(HOME_DIR / "code" / "personal" / "dotfiles" / "bin" / "gtd-healthkit-log"),
    ]
    
    for path in paths:
        if os.path.exists(path) or subprocess.run(["which", path.split("/")[-1]], 
                                                  capture_output=True).returncode == 0:
            return path.split("/")[-1] if "/" not in path else path
    
    return None


def log_health_entry(entry: str, timestamp: Optional[str] = None):
    """Log health entry using gtd-healthkit-log"""
    log_script = get_gtd_healthkit_log()
    if not log_script:
        print(f"⚠️  gtd-healthkit-log not found. Entry: {entry}")
        return False
    
    try:
        cmd = [log_script, entry]
        if timestamp:
            cmd.append(timestamp)
        
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✓ {result.stdout.strip()}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error logging entry: {e.stderr}")
        return False


def parse_google_fit_data(data: Dict[str, Any], date: Optional[str] = None) -> List[str]:
    """
    Parse Google Fit data and format as health log entries
    Returns list of formatted entries
    """
    entries = []
    target_date = date or datetime.now().strftime("%Y-%m-%d")
    
    # Handle different data structures from Google Fit
    if isinstance(data, list):
        for item in data:
            entries.extend(parse_google_fit_data(item, date))
        return entries
    
    if not isinstance(data, dict):
        return entries
    
    # Parse activities/workouts
    if "activities" in data or "workouts" in data:
        activities = data.get("activities", data.get("workouts", []))
        for activity in activities:
            activity_type = activity.get("activityType", activity.get("type", "Exercise"))
            duration = activity.get("duration", activity.get("durationMillis", 0))
            calories = activity.get("calories", activity.get("energy", {}).get("value", 0))
            distance = activity.get("distance", activity.get("distanceValue", 0))
            
            # Convert duration from milliseconds to minutes if needed
            if duration > 10000:  # Likely in milliseconds
                duration = duration / 1000 / 60
            
            entry_parts = [f"Google Fit {activity_type}"]
            if duration:
                entry_parts.append(f"{int(duration)} min")
            if calories:
                entry_parts.append(f"{int(calories)} calories")
            if distance:
                unit = activity.get("distanceUnit", "km")
                entry_parts.append(f"{distance:.2f} {unit}")
            
            entries.append(" - ".join(entry_parts))
    
    # Parse step count
    if "steps" in data or "stepCount" in data:
        steps = data.get("steps", data.get("stepCount", 0))
        if steps:
            entries.append(f"Google Fit: {steps} steps")
    
    # Parse calories
    if "calories" in data and not any("calories" in e for e in entries):
        calories = data.get("calories", 0)
        if calories:
            entries.append(f"Google Fit: {calories} calories burned")
    
    # Parse heart rate
    if "heartRate" in data or "heart_rate" in data:
        hr = data.get("heartRate", data.get("heart_rate", {}))
        if isinstance(hr, dict):
            hr_value = hr.get("value", hr.get("average", 0))
        else:
            hr_value = hr
        if hr_value:
            entries.append(f"Google Fit Heart Rate: {hr_value} bpm")
    
    # Parse sleep
    if "sleep" in data:
        sleep_data = data["sleep"]
        duration = sleep_data.get("duration", sleep_data.get("durationMillis", 0))
        if duration > 10000:  # Likely in milliseconds
            duration = duration / 1000 / 60 / 60  # Convert to hours
        if duration:
            entries.append(f"Google Fit Sleep: {duration:.1f} hours")
    
    # Parse daily summary
    if "dailySummary" in data:
        summary = data["dailySummary"]
        parts = ["Google Fit Daily Summary"]
        if summary.get("steps"):
            parts.append(f"{summary['steps']} steps")
        if summary.get("calories"):
            parts.append(f"{summary['calories']} calories")
        if summary.get("activeMinutes"):
            parts.append(f"{summary['activeMinutes']} min active")
        entries.append(" - ".join(parts))
    
    return entries


def process_takeout_file(file_path: Path, date: Optional[str] = None) -> List[str]:
    """Process a single Google Takeout JSON file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        return parse_google_fit_data(data, date)
    except Exception as e:
        print(f"⚠️  Error processing {file_path}: {e}")
        return []


def sync_from_takeout(takeout_path: Optional[Path] = None, date: Optional[str] = None):
    """
    Sync health data from Google Takeout export
    Can process either a directory or a specific file
    """
    if takeout_path is None:
        takeout_path = TAKEOUT_DIR
    
    takeout_path = Path(takeout_path)
    
    if not takeout_path.exists():
        print(f"❌ Takeout path does not exist: {takeout_path}")
        print(f"   Expected location: {TAKEOUT_DIR}")
        print(f"   Or provide path: --takeout /path/to/takeout")
        return False
    
    print(f"📂 Processing Google Takeout data from: {takeout_path}")
    
    # Find all JSON files
    json_files = []
    if takeout_path.is_file() and takeout_path.suffix == '.json':
        json_files = [takeout_path]
    elif takeout_path.is_dir():
        # Look for Google Fit data in typical Takeout structure
        fit_dirs = [
            takeout_path / "Fit",
            takeout_path / "Google Fit",
            takeout_path,
        ]
        
        for fit_dir in fit_dirs:
            if fit_dir.exists():
                json_files.extend(fit_dir.rglob("*.json"))
                break
    
    if not json_files:
        print(f"⚠️  No JSON files found in {takeout_path}")
        return False
    
    print(f"   Found {len(json_files)} JSON file(s)")
    
    all_entries = []
    for json_file in json_files:
        entries = process_takeout_file(json_file, date)
        all_entries.extend(entries)
    
    if not all_entries:
        print("⚠️  No health data found in Takeout files")
        return False
    
    # Log entries
    print(f"\n📝 Logging {len(all_entries)} health entry/entries...")
    success_count = 0
    for entry in all_entries:
        if log_health_entry(entry):
            success_count += 1
    
    print(f"\n✓ Successfully logged {success_count}/{len(all_entries)} entries")
    return success_count > 0


def get_credentials():
    """Get valid user credentials from storage or OAuth flow"""
    ensure_config_dir()
    
    creds = None
    if TOKEN_FILE.exists():
        try:
            creds = Credentials.from_authorized_user_file(str(TOKEN_FILE), SCOPES)
        except Exception as e:
            print(f"⚠️  Error loading token: {e}")
    
    # If there are no (valid) credentials available, let the user log in
    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            try:
                creds.refresh(Request())
            except Exception as e:
                print(f"⚠️  Error refreshing token: {e}")
                creds = None
        
        if not creds:
            if not CREDENTIALS_FILE.exists():
                print(f"❌ Credentials file not found: {CREDENTIALS_FILE}")
                print("\n📋 To set up OAuth credentials:")
                print("   1. Go to https://console.cloud.google.com/")
                print("   2. Create a new project or select existing")
                print("   3. Enable 'Google Data Portability API'")
                print("   4. Create OAuth 2.0 credentials (Desktop app)")
                print("   5. Download credentials and save to:")
                print(f"      {CREDENTIALS_FILE}")
                return None
            
            flow = InstalledAppFlow.from_client_secrets_file(
                str(CREDENTIALS_FILE), SCOPES)
            creds = flow.run_local_server(port=0)
        
        # Save credentials for next run
        with open(TOKEN_FILE, 'w') as token:
            token.write(creds.to_json())
    
    return creds


def sync_from_api(date: Optional[str] = None, days: int = 1):
    """
    Sync health data using Google Data Portability API
    Note: This is a simplified implementation. The actual Data Portability API
    may require different endpoints and data structures.
    """
    if not GOOGLE_API_AVAILABLE:
        print("❌ Google API libraries not available")
        print("   Install with: pip install google-auth google-auth-oauthlib google-auth-httplib2 google-api-python-client")
        return False
    
    print("🔐 Authenticating with Google...")
    creds = get_credentials()
    if not creds:
        return False
    
    try:
        # Note: The Data Portability API structure may differ
        # This is a template that may need adjustment based on actual API
        service = build('dataportability', 'v1', credentials=creds)
        
        # Request data export
        # Note: Actual API calls will depend on Google's Data Portability API structure
        print("📥 Requesting health data from Google...")
        print("⚠️  Note: Data Portability API implementation may need adjustment")
        print("   Consider using --takeout mode for now")
        
        # For now, suggest using Takeout
        print("\n💡 Tip: Use Google Takeout export mode:")
        print(f"   python {sys.argv[0]} --takeout /path/to/takeout")
        
        return False
        
    except HttpError as error:
        print(f"❌ API Error: {error}")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Sync Google Health/Fitness data to GTD daily logs",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Process Google Takeout export
  %(prog)s --takeout ~/Downloads/Takeout
  
  # Process specific date from Takeout
  %(prog)s --takeout ~/Downloads/Takeout --date 2024-12-15
  
  # Use Data Portability API (requires OAuth setup)
  %(prog)s --api --date 2024-12-15

Setup:
  1. For Takeout: Export Google Fit data from https://takeout.google.com/
  2. For API: Set up OAuth credentials (see error messages for details)
        """
    )
    
    parser.add_argument(
        '--takeout',
        type=str,
        help='Path to Google Takeout export directory or file'
    )
    parser.add_argument(
        '--api',
        action='store_true',
        help='Use Data Portability API (requires OAuth setup)'
    )
    parser.add_argument(
        '--date',
        type=str,
        help='Target date (YYYY-MM-DD). Default: today'
    )
    parser.add_argument(
        '--days',
        type=int,
        default=1,
        help='Number of days to sync (API mode only, default: 1)'
    )
    
    args = parser.parse_args()
    
    # Validate date format
    date = None
    if args.date:
        try:
            datetime.strptime(args.date, "%Y-%m-%d")
            date = args.date
        except ValueError:
            print(f"❌ Invalid date format: {args.date}. Use YYYY-MM-DD")
            return 1
    
    # Determine mode
    if args.takeout:
        success = sync_from_takeout(Path(args.takeout), date)
    elif args.api:
        success = sync_from_api(date, args.days)
    else:
        # Default: try Takeout in config directory
        print("📂 Using default Takeout directory...")
        success = sync_from_takeout(None, date)
        if not success:
            print("\n💡 To use Google Takeout export:")
            print(f"   1. Export Google Fit data from https://takeout.google.com/")
            print(f"   2. Extract and place in: {TAKEOUT_DIR}")
            print(f"   3. Run: {sys.argv[0]} --takeout {TAKEOUT_DIR}")
            print("\n   Or use --api for Data Portability API mode")
    
    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
