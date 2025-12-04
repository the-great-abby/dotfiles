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
        "backend": "lmstudio",  # Default to lmstudio for backward compatibility
        "url": "http://localhost:1234/v1/chat/completions",
        "chat_model": "",
        "embedding_model": "",
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
                    if key == "AI_BACKEND":
                        config["backend"] = value.lower()
                    elif key == "LM_STUDIO_URL":
                        config["lmstudio_url"] = value
                    elif key == "LM_STUDIO_CHAT_MODEL":
                        config["lmstudio_model"] = value
                    elif key == "LM_STUDIO_EMBEDDING_MODEL":
                        config["embedding_model"] = value
                    elif key == "LM_STUDIO_MODEL":
                        # Legacy support - map to chat_model
                        config["lmstudio_model"] = value
                    elif key == "OLLAMA_URL":
                        config["ollama_url"] = value
                    elif key == "OLLAMA_CHAT_MODEL":
                        config["ollama_model"] = value
                    elif key == "DAILY_LOG_DIR":
                        config["log_dir"] = value
                    elif key == "NAME":
                        config["name"] = value
                    elif key == "MAX_TOKENS":
                        try:
                            config["max_tokens"] = int(value)
                        except ValueError:
                            pass  # Keep default if invalid
    
    # Set URL and model based on backend
    backend = config.get("backend", "lmstudio").lower()
    if backend == "ollama":
        config["url"] = config.get("ollama_url", "http://localhost:11434/v1/chat/completions")
        if not config.get("chat_model"):
            config["chat_model"] = config.get("ollama_model", "")
        config["backend_name"] = "Ollama"
    else:  # Default to lmstudio
        config["url"] = config.get("lmstudio_url", "http://localhost:1234/v1/chat/completions")
        if not config.get("chat_model"):
            config["chat_model"] = config.get("lmstudio_model", "")
        config["backend_name"] = "LM Studio"
    
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

def check_ai_server(config):
    """Check if AI server (LM Studio or Ollama) is accessible and if a model is loaded."""
    import urllib.request
    
    backend_name = config.get("backend_name", "AI server")
    # Extract base URL (remove /v1/chat/completions)
    base_url = config["url"].replace("/v1/chat/completions", "")
    
    try:
        # Check if server is running by checking /v1/models
        models_url = f"{base_url}/v1/models"
        req = urllib.request.Request(models_url)
        with urllib.request.urlopen(req, timeout=5) as response:
            models_data = json.loads(response.read().decode('utf-8'))
            if 'data' in models_data and len(models_data['data']) > 0:
                return True, "Server is running"
            else:
                return False, "Server is running but no models are available"
    except urllib.error.URLError as e:
        return False, f"Could not connect to {backend_name} server at {base_url}. Make sure {backend_name} is running and the server is started."
    except Exception as e:
        return False, f"Error checking server: {e}"

def call_lm_studio(config, daily_log_content):
    """Call AI backend (LM Studio or Ollama) API with the daily log content."""
    import urllib.request
    import urllib.parse
    
    backend_name = config.get("backend_name", "AI server")
    backend = config.get("backend", "lmstudio").lower()
    
    # First, check if server is accessible
    server_ok, server_msg = check_ai_server(config)
    if not server_ok:
        if backend == "ollama":
            return (f"⚠️  {server_msg}\n\nTo fix this:\n1. Make sure Ollama is running (run 'ollama serve')\n2. Pull a model if needed (e.g., 'ollama pull gemma2:1b')\n3. Check that the model is available (run 'ollama list')", 1)
        else:
            return (f"⚠️  {server_msg}\n\nTo fix this:\n1. Open LM Studio\n2. Load a model (click on a model and click 'Load')\n3. Make sure the local server is running (check the 'Server' tab)", 1)
    
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
    # Use chat_model from config, or fall back to "local-model" which uses whatever is currently loaded
    model_name = config.get("chat_model", "").strip()
    if not model_name:
        model_name = "local-model"
    
    payload = {
        "model": model_name,
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
            # Check for error responses
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                if 'model' in error_msg.lower() and ('load' in error_msg.lower() or 'not found' in error_msg.lower()):
                    if backend == "ollama":
                        return (f"⚠️  Model not available in Ollama.\n\nError: {error_msg}\n\nTo fix this:\n1. Pull the model (e.g., 'ollama pull gemma2:1b')\n2. Check available models (run 'ollama list')\n3. Make sure the model name in config matches an available model", 1)
                    else:
                        return (f"⚠️  Model not loaded in LM Studio.\n\nError: {error_msg}\n\nTo fix this:\n1. Open LM Studio\n2. Go to the 'Chat' or 'Models' tab\n3. Click on a model and click 'Load' to load it\n4. Wait for the model to finish loading\n5. Try again", 1)
                return (f"⚠️  {backend_name} returned an error: {error_msg}", 1)
            if 'choices' in result and len(result['choices']) > 0:
                return (result['choices'][0]['message']['content'], 0)
            else:
                return ("Hmm, I got a response but it's not quite right. Yep.", 1)
    except urllib.error.URLError as e:
        if "timed out" in str(e).lower() or "timeout" in str(e).lower():
            if backend == "ollama":
                return (f"⚠️  Connection to Ollama timed out.\n\nThis usually means:\n1. No model is available in Ollama (run 'ollama pull <model>')\n2. The model is still loading (wait for it to finish)\n3. The server isn't responding (check 'ollama serve' is running)\n\nServer URL: {config['url']}", 1)
            else:
                return (f"⚠️  Connection to LM Studio timed out.\n\nThis usually means:\n1. No model is loaded in LM Studio (open LM Studio, load a model)\n2. The model is still loading (wait for it to finish)\n3. The server isn't responding (check the 'Server' tab in LM Studio)\n\nServer URL: {config['url']}", 1)
        if backend == "ollama":
            return (f"⚠️  Could not connect to Ollama: {e}\n\nMake sure:\n1. Ollama is running (run 'ollama serve')\n2. A model is available (run 'ollama list')\n\nServer URL: {config['url']}", 1)
        else:
            return (f"⚠️  Could not connect to LM Studio: {e}\n\nMake sure:\n1. LM Studio is running\n2. The local server is started (check the 'Server' tab)\n3. A model is loaded\n\nServer URL: {config['url']}", 1)
    except Exception as e:
        return (f"⚠️  Well, that didn't work out: {e}", 1)

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

