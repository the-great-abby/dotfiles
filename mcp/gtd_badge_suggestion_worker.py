#!/usr/bin/env python3
"""
GTD Badge Suggestion Worker - Processes badge suggestion requests from queue

Consumes messages from file queue and processes badge suggestion requests.
Uses AI personas to analyze logs and suggest custom badges.
"""

import json
import sys
import os
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional

# Add parent directories to path
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent
sys.path.insert(0, str(dotfiles_dir))

# Find persona helper
PERSONA_HELPER = None
for path in [
    dotfiles_dir / "zsh" / "functions" / "gtd_persona_helper.py",
    Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions" / "gtd_persona_helper.py",
    Path.home() / "code" / "dotfiles" / "zsh" / "functions" / "gtd_persona_helper.py",
]:
    if path.exists():
        PERSONA_HELPER = str(path)
        break

if not PERSONA_HELPER:
    print("Error: gtd_persona_helper.py not found", file=sys.stderr)
    sys.exit(1)

# Queue and gamification file paths
QUEUE_FILE = Path.home() / "Documents" / "gtd" / "badge_suggestion_queue.jsonl"
GAMIFICATION_FILE = Path.home() / "Documents" / "gtd" / ".gtd" / "gamification" / "gamification.json"

# Create directories if needed
QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
GAMIFICATION_FILE.parent.mkdir(parents=True, exist_ok=True)

# Python command
PYTHON_CMD = os.getenv("GTD_PYTHON", "python3")


def get_daily_log_dir() -> Path:
    """Get daily log directory from config."""
    # Try to read from config
    config_file = Path.home() / ".daily_log_config"
    if not config_file.exists():
        config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".daily_log_config"
    if not config_file.exists():
        config_file = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / ".daily_log_config"
    
    if config_file.exists():
        try:
            with open(config_file, 'r') as f:
                for line in f:
                    if line.startswith("DAILY_LOG_DIR="):
                        log_dir = line.split("=", 1)[1].strip().strip('"').strip("'")
                        # Expand $HOME
                        log_dir = log_dir.replace("$HOME", str(Path.home()))
                        return Path(log_dir)
        except Exception:
            pass
    
    # Default
    return Path.home() / "Documents" / "daily_logs"


def get_log_content(date_range: str) -> str:
    """Get log content for the specified date range."""
    log_dir = get_daily_log_dir()
    log_content = ""
    
    if date_range == "week":
        # Last 7 days
        for i in range(7):
            date = datetime.now().date()
            date = date.replace(day=date.day - i) if date.day > i else date
            log_file = log_dir / f"{date.strftime('%Y-%m-%d')}.md"
            if log_file.exists():
                with open(log_file, 'r') as f:
                    log_content += f"\n\n# {date.strftime('%Y-%m-%d')}\n{f.read()}"
    elif date_range == "month":
        # Last 30 days
        for i in range(30):
            date = datetime.now().date()
            date = date.replace(day=date.day - i) if date.day > i else date
            log_file = log_dir / f"{date.strftime('%Y-%m-%d')}.md"
            if log_file.exists():
                with open(log_file, 'r') as f:
                    log_content += f"\n\n# {date.strftime('%Y-%m-%d')}\n{f.read()}"
    elif date_range == "all":
        # All logs (up to 50 most recent)
        log_files = sorted(log_dir.glob("*.md"), key=lambda p: p.stat().st_mtime, reverse=True)[:50]
        for log_file in log_files:
            date = log_file.stem
            with open(log_file, 'r') as f:
                log_content += f"\n\n# {date}\n{f.read()}"
    
    return log_content


def extract_json_from_response(text: str) -> Optional[Dict[str, Any]]:
    """Extract JSON from AI response."""
    import re
    
    # Try code blocks first
    code_block_pattern = r'```(?:json)?\s*(\{.*?"suggestions".*?\})\s*```'
    code_match = re.search(code_block_pattern, text, re.DOTALL | re.IGNORECASE)
    if code_match:
        try:
            json_str = code_match.group(1).strip()
            return json.loads(json_str)
        except:
            pass
    
    # Try JSON pattern
    json_pattern = r'\{[^{}]*"suggestions"\s*:\s*\[.*?\][^{}]*\}'
    match = re.search(json_pattern, text, re.DOTALL)
    if match:
        try:
            json_str = match.group(0)
            return json.loads(json_str)
        except:
            pass
    
    # Try to find opening brace and match closing
    start = text.find('{"suggestions"')
    if start != -1:
        brace_count = 0
        in_string = False
        escape_next = False
        for i in range(start, len(text)):
            char = text[i]
            if escape_next:
                escape_next = False
                continue
            if char == '\\':
                escape_next = True
                continue
            if char == '"' and not escape_next:
                in_string = not in_string
            if not in_string:
                if char == '{':
                    brace_count += 1
                elif char == '}':
                    brace_count -= 1
                    if brace_count == 0:
                        try:
                            json_str = text[start:i+1]
                            return json.loads(json_str)
                        except:
                            pass
    
    return None


def process_badge_suggestion_request(job: Dict[str, Any]) -> bool:
    """Process a single badge suggestion request."""
    try:
        request_id = job.get("id", f"badge_{datetime.now().timestamp()}")
        date_range = job.get("date_range", "week")
        persona = job.get("persona", "hank")
        
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Processing badge suggestion request: {request_id}")
        print(f"  Date range: {date_range}, Persona: {persona}")
        
        # Get log content
        log_content = get_log_content(date_range)
        if not log_content:
            print(f"  ⚠️  No log entries found for analysis")
            return False
        
        # Build analysis prompt
        analysis_prompt = f"""I've been analyzing your daily logs and I want to suggest some custom badges based on patterns I've noticed. 

Here are the log entries I've reviewed:
{log_content}

Based on these logs, please suggest 2-3 custom badges that would be meaningful and achievable. 

IMPORTANT: Respond with ONLY valid JSON, no additional text before or after. Use this exact structure:

{{
  "suggestions": [
    {{
      "name": "Badge Name",
      "description": "What pattern or achievement it recognizes",
      "challenge_requirement": {{"daily_logging_streak": 7}},
      "maintenance_requirement": {{"daily_logging_streak": 3}},
      "xp_reward": 50,
      "reason": "Why this pattern matters"
    }}
  ]
}}

For challenge_requirement and maintenance_requirement, use one of these metric keys:
- daily_logging_streak (number of days)
- task_streak (number of days)
- exercise_streak (number of days)
- review_streak (number of days)
- tasks_completed (total count)
- habits_completed (total count)
- projects_completed (total count)
- exercise_sessions (total count)
- reviews_completed (total count)
- wizard_uses (total count)

Focus on patterns that are:
- Specific and measurable (use actual numbers)
- Meaningful to their personal growth
- Achievable but challenging
- Based on actual patterns in the logs

Look for patterns like: specific activities they do regularly, themes in their entries, habits they're building, or goals they're working toward.

Respond with ONLY the JSON object, nothing else."""
        
        # Call persona helper
        import subprocess
        result = subprocess.run(
            [PYTHON_CMD, PERSONA_HELPER, persona, analysis_prompt],
            capture_output=True,
            text=True,
            timeout=120  # 2 minute timeout
        )
        
        if result.returncode != 0:
            print(f"  ❌ Error calling persona helper: {result.stderr}")
            return False
        
        suggestions_text = result.stdout
        
        # Extract JSON
        suggestions_data = extract_json_from_response(suggestions_text)
        if not suggestions_data:
            print(f"  ⚠️  Could not parse suggestions as JSON")
            return False
        
        # Load gamification file
        if GAMIFICATION_FILE.exists():
            with open(GAMIFICATION_FILE, 'r') as f:
                gamification_data = json.load(f)
        else:
            gamification_data = {"badge_suggestions": []}
        
        # Add suggestions
        existing = gamification_data.get("badge_suggestions", [])
        for suggestion in suggestions_data.get("suggestions", []):
            suggestion["status"] = "pending"
            suggestion["suggested_date"] = datetime.now().isoformat()
            suggestion["request_id"] = request_id
            existing.append(suggestion)
        
        gamification_data["badge_suggestions"] = existing
        
        # Save
        with open(GAMIFICATION_FILE, 'w') as f:
            json.dump(gamification_data, f, indent=2)
        
        num_suggestions = len(suggestions_data.get("suggestions", []))
        print(f"  ✓ Saved {num_suggestions} badge suggestion(s) to gamification.json")
        return True
        
    except Exception as e:
        print(f"  ❌ Error processing request: {e}")
        import traceback
        traceback.print_exc()
        return False


def process_file_queue():
    """Process messages from file-based queue."""
    if not QUEUE_FILE.exists():
        return False
    
    try:
        # Read first line (oldest job)
        with open(QUEUE_FILE, 'r') as f:
            lines = f.readlines()
        
        if not lines or not lines[0].strip():
            return False
        
        # Parse job
        job = json.loads(lines[0].strip())
        
        # Process job
        success = process_badge_suggestion_request(job)
        
        if success:
            # Remove processed line
            if len(lines) > 1:
                with open(QUEUE_FILE, 'w') as f:
                    f.writelines(lines[1:])
            else:
                QUEUE_FILE.unlink()
            return True
        else:
            # Move to end for retry
            if len(lines) > 1:
                with open(QUEUE_FILE, 'w') as f:
                    f.writelines(lines[1:] + [lines[0]])
            return False
            
    except json.JSONDecodeError as e:
        print(f"Error parsing job JSON: {e}", file=sys.stderr)
        # Remove invalid line
        with open(QUEUE_FILE, 'r') as f:
            lines = f.readlines()
        if len(lines) > 1:
            with open(QUEUE_FILE, 'w') as f:
                f.writelines(lines[1:])
        else:
            QUEUE_FILE.unlink()
        return False
    except Exception as e:
        print(f"Error processing file queue: {e}", file=sys.stderr)
        return False


def main():
    """Main worker loop."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Badge Suggestion Worker")
    parser.add_argument("--queue-type", choices=["file"], default="file", help="Queue type")
    args = parser.parse_args()
    
    if args.queue_type == "file":
        # Ensure queue file exists
        QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
        if not QUEUE_FILE.exists():
            QUEUE_FILE.touch()
            print(f"✓ Created queue file: {QUEUE_FILE}")
        else:
            print(f"✓ Queue file ready: {QUEUE_FILE}")
        
        print(f"Waiting for badge suggestion requests. To exit press CTRL+C")
        print("")
        
        # Process in loop
        while True:
            try:
                processed = process_file_queue()
                if not processed:
                    time.sleep(5)  # Check every 5 seconds
            except KeyboardInterrupt:
                print("\nStopping worker...")
                break
            except Exception as e:
                print(f"Error in worker loop: {e}")
                time.sleep(10)  # Wait longer on error


if __name__ == "__main__":
    main()

