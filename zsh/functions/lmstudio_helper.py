#!/usr/bin/env python3
"""
Helper script to interact with LM Studio API for daily log advice.
"""

import json
import sys
import os
from pathlib import Path

def read_config():
    """Read configuration from .daily_log_config file."""
    config_path = Path.home() / ".daily_log_config"
    if not config_path.exists():
        # Try in dotfiles location
        dotfiles_path = Path(__file__).parent.parent / ".daily_log_config"
        if dotfiles_path.exists():
            config_path = dotfiles_path
    
    config = {
        "url": "http://localhost:1234/v1/chat/completions",
        "model": "",
        "log_dir": str(Path.home() / "Documents" / "daily_logs"),
        "name": "",
        "max_tokens": 1200
    }
    
    if config_path.exists():
        with open(config_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    if key == "LM_STUDIO_URL":
                        config["url"] = value
                    elif key == "LM_STUDIO_MODEL":
                        config["model"] = value
                    elif key == "DAILY_LOG_DIR":
                        config["log_dir"] = value
                    elif key == "NAME":
                        config["name"] = value
                    elif key == "MAX_TOKENS":
                        try:
                            config["max_tokens"] = int(value)
                        except ValueError:
                            pass  # Keep default if invalid
    
    return config

def get_daily_goal(daily_log_content):
    """Extract daily goal from log content."""
    goal_keywords = ["goal", "intention", "achieve", "accomplish", "today"]
    lines = daily_log_content.lower().split('\n')
    for i, line in enumerate(lines):
        if any(keyword in line for keyword in goal_keywords):
            # Look for the goal in the next few lines
            for j in range(i, min(i + 5, len(lines))):
                if lines[j].strip() and not lines[j].strip().startswith('#'):
                    return lines[j].strip()
    return None

def call_lm_studio(config, daily_log_content):
    """Call LM Studio API with the daily log content."""
    import urllib.request
    import urllib.parse
    
    # Check if goal exists
    goal = get_daily_goal(daily_log_content)
    has_goal = goal is not None and len(goal) > 10
    
    # Get the user's name for personalization
    user_name = config.get("name", "").strip()
    name_greeting = f", {user_name}" if user_name else ""
    
    # Create the prompt in Hank Hill's style
    if has_goal:
        system_prompt = f"""You are Hank Hill, a helpful and practical friend from King of the Hill. 
You're reviewing {user_name if user_name else "someone"}'s daily log and providing friendly, practical advice to help them accomplish their goals. 
Be encouraging, practical, and remind them of things they might have forgotten. Keep it brief and conversational.
Address them by name ({user_name}) if provided, otherwise use friendly terms like "friend" or "pal"."""
        user_prompt = f"""Here's my daily log so far:

{daily_log_content}

My goal today is: {goal}

Can you give me some helpful reminders and advice to help me accomplish my goal? Be like Hank Hill - practical, friendly, and encouraging. Address me by name if you know it."""
    else:
        system_prompt = f"""You are Hank Hill, a helpful and practical friend from King of the Hill. 
You're reviewing {user_name if user_name else "someone"}'s daily log. Be friendly, practical, and encouraging. Keep it brief and conversational.
Address them by name ({user_name}) if provided, otherwise use friendly terms like "friend" or "pal"."""
        user_prompt = f"""Here's my daily log so far:

{daily_log_content}

I haven't clearly defined my goal for today yet. Can you ask me what I'd like to accomplish today? Be like Hank Hill - friendly and encouraging. Address me by name if you know it."""
    
    # Prepare the request
    payload = {
        "model": config["model"] if config["model"] else "local-model",
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": 0.7,
        "max_tokens": config.get("max_tokens", 1200)
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        config["url"],
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'choices' in result and len(result['choices']) > 0:
                return (result['choices'][0]['message']['content'], 0)
            else:
                return ("Hmm, I got a response but it's not quite right. Yep.", 1)
    except urllib.error.URLError as e:
        return (f"Dang it! Couldn't connect to LM Studio: {e}. Make sure it's running on {config['url']}", 1)
    except Exception as e:
        return (f"Well, that didn't work out: {e}", 1)

def main():
    if len(sys.argv) < 2:
        print("Usage: lmstudio_helper.py <daily_log_file_path>")
        sys.exit(1)
    
    log_file = sys.argv[1]
    if not os.path.exists(log_file):
        print(f"Log file not found: {log_file}")
        sys.exit(1)
    
    with open(log_file, 'r') as f:
        daily_log_content = f.read()
    
    config = read_config()
    advice, exit_code = call_lm_studio(config, daily_log_content)
    print(advice)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()

