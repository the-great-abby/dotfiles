#!/usr/bin/env python3
"""
GTD Deep Analysis Worker

Background worker that processes deep analysis requests from the queue.
Uses GPT-OSS 20b for deeper analysis tasks like weekly reviews, energy analysis,
connections, and insights.
"""

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List

try:
    import pika
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

# Configuration - Deep model via LM Studio
# Try to read config from persona helper
try:
    sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
    from gtd_persona_helper import read_config as read_gtd_config
    from gtd_ai_helpers import handle_ai_response
    GTD_CONFIG = read_gtd_config()
    # Map the config to expected keys
    if "url" not in GTD_CONFIG and "lmstudio_url" in GTD_CONFIG:
        GTD_CONFIG["url"] = GTD_CONFIG["lmstudio_url"]
except (ImportError, Exception):
    # Fallback: read config manually
    GTD_CONFIG = {}

# Always read DEEP_MODEL_TIMEOUT from config files (gtd_persona_helper might not include it)
config_paths = [
    Path.home() / ".gtd_config_ai",
    Path.home() / ".gtd_config",
    Path.home() / ".daily_log_config",
    Path(__file__).parent.parent / "zsh" / ".gtd_config_ai",
    Path(__file__).parent.parent / "zsh" / ".gtd_config",
]
for config_path in config_paths:
    if config_path.exists():
        with open(config_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    # Remove variable expansion syntax like ${VAR:-default} or ${VAR:default}
                    if value.startswith("${") and "}" in value:
                        if ":-" in value:
                            # Standard syntax: ${VAR:-default}
                            value = value.split(":-", 1)[1].rstrip("}")
                        elif ":" in value and not value.startswith("${:-"):
                            # Bash alternate syntax: ${VAR:default} (use if VAR is unset or empty)
                            # For API keys, prefer checking environment variable
                            if key == "OLLAMA_API_KEY":
                                # Don't strip the default - let it fall through to env var check
                                value = ""
                            else:
                                value = value.split(":", 1)[1].rstrip("}")
                        elif value == "${OLLAMA_API_KEY:-}":
                            # Empty default - use env var
                            value = ""
                    
                    # Process the key-value pair
                    if key == "GTD_COMPUTER_MODE":
                        GTD_CONFIG["computer_mode"] = value.strip('"').strip("'").lower()
                    elif key == "GTD_DEEP_MODEL_URL":
                        GTD_CONFIG["deep_model_url"] = value
                    elif key == "LM_STUDIO_URL" and "url" not in GTD_CONFIG and "deep_model_url" not in GTD_CONFIG:
                        GTD_CONFIG["url"] = value
                    elif key == "OLLAMA_URL" and "ollama_url" not in GTD_CONFIG:
                        GTD_CONFIG["ollama_url"] = value
                    elif key == "OLLAMA_API_KEY" and "ollama_api_key" not in GTD_CONFIG:
                        GTD_CONFIG["ollama_api_key"] = value
                    elif key == "AI_BACKEND":
                        GTD_CONFIG["ai_backend"] = value.strip('"').strip("'").lower()
                    elif key == "GTD_DEEP_MODEL_NAME" and "deep_model_name" not in GTD_CONFIG:
                        GTD_CONFIG["deep_model_name"] = value
                    elif key == "DEEP_MODEL_TIMEOUT" or key == "LM_STUDIO_TIMEOUT":
                        # Always read timeout, override if already set (later files override earlier ones)
                        try:
                            timeout_val = int(value)
                            GTD_CONFIG["deep_model_timeout"] = timeout_val
                            if os.getenv("GTD_DEBUG"):
                                print(f"DEBUG: Read DEEP_MODEL_TIMEOUT={timeout_val} from {config_path}", file=sys.stderr)
                        except ValueError:
                            pass
                    elif key == "DEEP_ANALYSIS_MAX_TOKENS" or key == "WEEKLY_REVIEW_MAX_TOKENS":
                        # Read max tokens for deep analysis
                        try:
                            GTD_CONFIG["deep_analysis_max_tokens"] = int(value)
                        except ValueError:
                            pass
                    elif key == "TIMEOUT" and "deep_model_timeout" not in GTD_CONFIG:
                        # Only use TIMEOUT if DEEP_MODEL_TIMEOUT wasn't found
                        try:
                            GTD_CONFIG["deep_model_timeout"] = int(value)
                        except ValueError:
                            pass
        # Don't break - read from all config files, later ones override earlier ones

# Second pass: Check for mode-specific settings (WORK_* or HOME_*)
computer_mode = GTD_CONFIG.get("computer_mode", os.getenv("GTD_COMPUTER_MODE", "home")).lower()
mode_prefix = "WORK_" if computer_mode == "work" else "HOME_"

# Re-read config files to get mode-specific settings
for config_path in config_paths:
    if config_path.exists():
        with open(config_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    # Remove variable expansion syntax like ${VAR:-default} or ${VAR:default}
                    if value.startswith("${") and "}" in value:
                        if ":-" in value:
                            # Standard syntax: ${VAR:-default}
                            value = value.split(":-", 1)[1].rstrip("}")
                        elif ":" in value and not value.startswith("${:-"):
                            # Bash alternate syntax: ${VAR:default} (use if VAR is unset or empty)
                            # For API keys, prefer checking environment variable
                            if mode_key == "OLLAMA_API_KEY":
                                # Don't strip the default - let it fall through to env var check
                                value = ""
                            else:
                                value = value.split(":", 1)[1].rstrip("}")
                        elif value == "${OLLAMA_API_KEY:-}" or value.endswith(":-}"):
                            # Empty default - use env var
                            value = ""
                    
                    # Check for mode-specific settings
                    if key.startswith(mode_prefix):
                        mode_key = key[len(mode_prefix):]  # Remove prefix
                        if mode_key == "AI_BACKEND" and value:
                            GTD_CONFIG["ai_backend"] = value.lower()
                        elif mode_key == "OLLAMA_URL" and value:
                            GTD_CONFIG["ollama_url"] = value
                        elif mode_key == "OLLAMA_API_KEY" and value:
                            GTD_CONFIG["ollama_api_key"] = value
                        elif mode_key == "LM_STUDIO_URL" and value:
                            GTD_CONFIG["url"] = value
                        elif mode_key == "DEEP_MODEL_NAME" and value:
                            GTD_CONFIG["deep_model_name"] = value
                        elif mode_key == "GTD_DEEP_MODEL_URL" and value:
                            GTD_CONFIG["deep_model_url"] = value

# Determine deep model URL based on AI backend and available config
# Priority: GTD_DEEP_MODEL_URL env var > GTD_DEEP_MODEL_URL config > AI_BACKEND-based selection > default
deep_model_url_from_env = os.getenv("GTD_DEEP_MODEL_URL")
if deep_model_url_from_env:
    DEEP_MODEL_URL = deep_model_url_from_env
elif "deep_model_url" in GTD_CONFIG:
    DEEP_MODEL_URL = GTD_CONFIG["deep_model_url"]
else:
    # Check AI backend to determine which URL to use
    ai_backend = GTD_CONFIG.get("ai_backend", os.getenv("AI_BACKEND", "lmstudio")).lower()
    
    # If OLLAMA_URL is set and contains :31080 (Ollama Controller), use it
    if "ollama_url" in GTD_CONFIG and ":31080" in GTD_CONFIG["ollama_url"]:
        DEEP_MODEL_URL = GTD_CONFIG["ollama_url"]
    elif ai_backend == "ollama" and "ollama_url" in GTD_CONFIG:
        DEEP_MODEL_URL = GTD_CONFIG["ollama_url"]
    elif "url" in GTD_CONFIG and ":31080" in GTD_CONFIG["url"]:
        # Using Ollama Controller (port 31080) - auto-detect even if AI_BACKEND isn't "ollama"
        DEEP_MODEL_URL = GTD_CONFIG["url"]
    else:
        # Default to LM Studio URL or fallback
        DEEP_MODEL_URL = GTD_CONFIG.get("url", "http://localhost:1234/v1/chat/completions")
# Get model name from env var, then config, then default
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME") or os.getenv("GTD_DEEP_MODEL") or GTD_CONFIG.get("deep_model_name") or "gpt-oss-20b"


def _build_ollama_headers(url: str) -> Dict[str, str]:
    """Build HTTP headers for Ollama requests, including Authorization if API key is present.
    
    Args:
        url: Request URL (to check if it's an Ollama URL)
    
    Returns:
        Dictionary of HTTP headers
    """
    headers = {'Content-Type': 'application/json'}
    
    # Check if this is an Ollama URL
    is_ollama = 'ollama' in url.lower() or ':11434' in url or ':31080' in url
    if is_ollama:
        # Try to get API key from config, then environment variable
        api_key = GTD_CONFIG.get("ollama_api_key") or os.getenv("OLLAMA_API_KEY")
        if api_key:
            headers['Authorization'] = f'Bearer {api_key}'
    
    return headers


def _check_ollama_controller_ready(url: str) -> tuple[bool, str]:
    """Check if Ollama Controller is ready and responding.
    
    Uses /v1/models endpoint (GET request) to avoid queuing test requests.
    
    Returns:
        (is_ready, message) tuple
    """
    import urllib.request
    import urllib.error
    import json
    
    if ":31080" not in url:
        return True, ""  # Not using Ollama Controller
    
    try:
        # Use /v1/models endpoint (GET request) to check readiness without queuing
        # This is a read-only endpoint that doesn't create queue entries
        base_url = url.replace("/v1/chat/completions", "")
        models_url = f"{base_url}/v1/models"
        
        test_req = urllib.request.Request(models_url)
        with urllib.request.urlopen(test_req, timeout=3) as test_response:
            if test_response.status == 200:
                # Try to parse response to ensure it's valid
                try:
                    models_data = json.loads(test_response.read().decode('utf-8'))
                    # Response can be a list or dict with 'data' key
                    if isinstance(models_data, list) or (isinstance(models_data, dict) and 'data' in models_data):
                        return True, ""
                    else:
                        return True, ""  # Still consider it ready if we get 200
                except (json.JSONDecodeError, ValueError):
                    # If we can't parse, but got 200, consider it ready
                    return True, ""
            else:
                return False, f"Endpoint returned status {test_response.status}"
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return False, "Endpoint not found (404) - controller may need redeploy"
        else:
            return False, f"HTTP error {e.code}"
    except urllib.error.URLError as e:
        return False, f"Connection error: {e}"
    except Exception as e:
        return False, f"Error: {e}"

# Debug: Print config values (remove in production)
if os.getenv("GTD_DEBUG"):
    print(f"DEBUG: GTD_CONFIG keys: {list(GTD_CONFIG.keys())}", file=sys.stderr)
    print(f"DEBUG: deep_model_timeout from config: {GTD_CONFIG.get('deep_model_timeout')}", file=sys.stderr)
    print(f"DEBUG: DEEP_MODEL_TIMEOUT from env: {os.getenv('DEEP_MODEL_TIMEOUT')}", file=sys.stderr)
def get_rabbitmq_url() -> str:
    """Get RabbitMQ URL with optional credentials."""
    url = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
    
    # If URL already has credentials, use it as-is
    if "//" in url:
        url_parts = url.split("//", 1)
        if len(url_parts) == 2 and "@" in url_parts[1]:
            return url  # Already has credentials
    
    # Otherwise, check for separate username/password
    username = os.getenv("RABBITMQ_USER") or os.getenv("GTD_RABBITMQ_USER")
    password = os.getenv("RABBITMQ_PASS") or os.getenv("GTD_RABBITMQ_PASS")
    
    if username:
        # Extract host:port from URL
        if "//" in url:
            url_parts = url.split("//", 1)
            host_part = url_parts[1]
            protocol = url_parts[0] + "//"
        else:
            host_part = url
            protocol = "amqp://"
        
        if password:
            url = f"{protocol}{username}:{password}@{host_part}"
        else:
            url = f"{protocol}{username}@{host_part}"
    
    return url

RABBITMQ_URL = get_rabbitmq_url()
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_QUEUE", "gtd_deep_analysis")
RESULT_DIR = Path.home() / "Documents" / "gtd" / "deep_analysis_results"
RESULT_DIR.mkdir(parents=True, exist_ok=True)

# Fallback queue file
QUEUE_FILE = Path.home() / "Documents" / "gtd" / "deep_analysis_queue.jsonl"

GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
DAILY_LOG_DIR = Path.home() / "Documents" / "daily_logs"
SECOND_BRAIN = Path.home() / "Documents" / "obsidian" / "Second Brain"

USER_NAME = os.getenv("GTD_USER_NAME", "Abby")

# Load Discord webhook URL from config
GTD_DISCORD_WEBHOOK_URL = os.getenv("GTD_DISCORD_WEBHOOK_URL", "")
if not GTD_DISCORD_WEBHOOK_URL:
    # Try to read from config files
    config_paths = [
        Path.home() / ".gtd_config_ai",
        Path.home() / ".gtd_config",
        Path(__file__).parent.parent / "zsh" / ".gtd_config_ai",
        Path(__file__).parent.parent / "zsh" / ".gtd_config",
    ]
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        if key == "GTD_DISCORD_WEBHOOK_URL":
                            GTD_DISCORD_WEBHOOK_URL = value
                            break
            if GTD_DISCORD_WEBHOOK_URL:
                break


# Helper function to get callback URL for tool execution
def get_tool_callback_url() -> Optional[str]:
    """Get the callback URL for tool execution from config or environment.
    
    For Kubernetes (Ollama Controller), detects accessible URL (Tailscale or node IP).
    For local setups, uses localhost.
    
    Returns:
        Callback URL string if configured, None otherwise
    """
    # Check environment variable first
    callback_url = os.getenv("GTD_TOOL_CALLBACK_URL")
    if callback_url:
        return callback_url
    
    # Check config files
    config_paths = [
        Path.home() / ".gtd_config_ai",
        Path.home() / ".gtd_config",
        Path(__file__).parent.parent / "zsh" / ".gtd_config_ai",
        Path(__file__).parent.parent / "zsh" / ".gtd_config",
    ]
    
    for config_path in config_paths:
        if config_path.exists():
            try:
                with open(config_path) as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip().strip('"').strip("'")
                            if key == "GTD_TOOL_CALLBACK_URL":
                                return value
            except Exception:
                continue
    
    # Check if we're using Ollama Controller (Kubernetes)
    # If so, we need a URL accessible from Kubernetes pods
    is_ollama_controller = ":31080" in DEEP_MODEL_URL or "31080" in DEEP_MODEL_URL
    
    if is_ollama_controller:
        # Try Tailscale domain first (most reliable for Kubernetes access)
        tailscale_domain = os.getenv("GTD_TAILSCALE_DOMAIN", "")
        if not tailscale_domain:
            # Check config files for Tailscale domain
            for config_path in config_paths:
                if config_path.exists():
                    try:
                        with open(config_path) as f:
                            for line in f:
                                line = line.strip()
                                if line and not line.startswith('#') and '=' in line:
                                    key, value = line.split('=', 1)
                                    key = key.strip()
                                    value = value.strip().strip('"').strip("'")
                                    if key == "GTD_TAILSCALE_DOMAIN":
                                        tailscale_domain = value
                                        break
                    except Exception:
                        continue
        
        if tailscale_domain:
            # Use Tailscale domain with nginx port (8080)
            return f"http://{tailscale_domain}:8080/api/tools/execute"
        
        # Fall back to detecting Kubernetes node IP
        try:
            import subprocess
            # Try to detect node IP
            node_ip = None
            
            # Check for minikube
            try:
                result = subprocess.run(
                    ["minikube", "ip"],
                    capture_output=True,
                    text=True,
                    timeout=2
                )
                if result.returncode == 0:
                    node_ip = result.stdout.strip()
            except (subprocess.TimeoutExpired, FileNotFoundError):
                pass
            
            # Check kubectl for node IP
            if not node_ip:
                try:
                    result = subprocess.run(
                        ["kubectl", "get", "nodes", "-o", "jsonpath={.items[0].status.addresses[?(@.type==\"InternalIP\")].address}"],
                        capture_output=True,
                        text=True,
                        timeout=2
                    )
                    if result.returncode == 0 and result.stdout.strip():
                        detected_ip = result.stdout.strip()
                        # For Docker Desktop, use 127.0.0.1
                        if detected_ip == "127.0.0.1" or detected_ip.startswith("192.168"):
                            node_ip = "127.0.0.1"
                        else:
                            node_ip = detected_ip
                except (subprocess.TimeoutExpired, FileNotFoundError):
                    pass
            
            if node_ip:
                # Use node IP with nginx port (8080)
                return f"http://{node_ip}:8080/api/tools/execute"
        except Exception:
            # If detection fails, log warning but continue
            pass
    
    # Default: use localhost:8000 (web backend default port)
    # This works for local setups but NOT for Kubernetes
    return "http://127.0.0.1:8000/api/tools/execute"

def call_deep_ai(prompt: str, system_prompt: str = None, max_tokens: int = 2000, use_async: bool = False, callback=None, result_file: str = None, max_poll_time: float = None, force_tools: bool = False) -> str:
    """
    Call the deep AI model (GPT-OSS 20b) for comprehensive analysis.
    
    Args:
        prompt: The prompt to send to the AI
        system_prompt: Optional system prompt
        max_tokens: Maximum tokens for response
        use_async: If True, use non-blocking async submission (returns request_id immediately)
        callback: Optional callback(result, error) for async mode
        result_file: Optional file path to save result when complete (async mode)
        max_poll_time: Optional maximum time to poll for async responses (in seconds). 
                      If None, uses the configured timeout. For long-running requests 
                      (like advice), use 3600 (60 minutes) or higher.
        force_tools: If True, always attempt to add tools to the request, even if not using 
                     Ollama Controller. Tools are only actually functional with Ollama Controller,
                     but this allows advice worker and other callers to ensure tools are included.
    
    Returns:
        - If use_async=False: Result string (blocking)
        - If use_async=True: Request ID string (non-blocking, callback handles result)
    """
    import urllib.request
    import urllib.error
    
    # If using async and Ollama Controller, use the async system
    if use_async and ":31080" in DEEP_MODEL_URL:
        try:
            sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
            from gtd_ai_async import submit_ai_request_async
            
            if system_prompt is None:
                system_prompt = f"You are {USER_NAME}'s deep thinking GTD analyst. You provide comprehensive, thoughtful analysis."
            
            # Get model name
            actual_model_name = DEEP_MODEL_NAME
            is_thinking_model = "thinking" in actual_model_name.lower()
            
            # Get timeout
            base_timeout = 120
            if os.getenv("DEEP_MODEL_TIMEOUT"):
                try:
                    base_timeout = int(os.getenv("DEEP_MODEL_TIMEOUT"))
                except (ValueError, TypeError):
                    pass
            elif GTD_CONFIG.get("deep_model_timeout"):
                try:
                    base_timeout = int(GTD_CONFIG.get("deep_model_timeout"))
                except (ValueError, TypeError):
                    pass
            
            if is_thinking_model and base_timeout < 300:
                max_poll_time = 300
            else:
                max_poll_time = base_timeout
            
            # Use longer timeout for async (60 minutes default)
            # Always use at least 3600s (60 min) for Ollama Controller async requests
            # to handle long-running requests like morning reviews, advice, etc.
            if max_poll_time < 3600:
                max_poll_time = 3600
                if os.getenv("GTD_DEBUG"):
                    print(f"DEBUG: Increased max_poll_time to 3600s for async request (was {base_timeout}s)", file=sys.stderr)
            
            # Calculate poll_timeout for followup requests (same logic as blocking mode)
            if max_poll_time is not None:
                poll_timeout = max_poll_time
            elif ":31080" in DEEP_MODEL_URL:
                poll_timeout = max(base_timeout, 3600)
            else:
                poll_timeout = base_timeout
            timeout = base_timeout  # For urllib.request.urlopen timeout
            
            payload = {
                "model": actual_model_name,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.7,
                "max_tokens": max_tokens,
                "priority": 20,  # NORMAL priority for background tasks
            }
            
            # Add tools if using Ollama Controller (controller supports tools regardless of model)
            # Or if force_tools is True (for advice worker and other cases where tools are always needed)
            is_ollama_controller = ":31080" in DEEP_MODEL_URL or "31080" in DEEP_MODEL_URL
            if force_tools and not is_ollama_controller:
                # If force_tools is True but not using Ollama Controller, log warning but still try
                try:
                    log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                    with open(log_file, "a", encoding="utf-8") as f:
                        f.write(f"  -> ⚠️  force_tools=True but not using Ollama Controller (URL: {DEEP_MODEL_URL})\n")
                except Exception:
                    pass
            
            # Log to tool_calls.log for debugging
            log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
            try:
                from datetime import datetime
                log_file.parent.mkdir(parents=True, exist_ok=True)
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(f"[{datetime.now().isoformat()}] call_deep_ai (async) - Model: {actual_model_name}, URL: {DEEP_MODEL_URL}\n")
                    f.write(f"  -> Ollama Controller: {is_ollama_controller}\n")
            except Exception:
                pass
            
            if is_ollama_controller or force_tools:
                try:
                    # Import tool registry
                    functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                    if not functions_dir.exists():
                        functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                    if functions_dir.exists() and str(functions_dir) not in sys.path:
                        sys.path.insert(0, str(functions_dir))
                    from gtd_tool_registry import get_tool_definitions
                    
                    # Include GTD tools by default for deep analysis (comprehensive advice)
                    tools_to_include = []
                    gtd_tools = get_tool_definitions(categories=["gtd"])
                    tools_to_include.extend(gtd_tools)
                    
                    if tools_to_include:
                        payload["tools"] = tools_to_include
                        payload["tool_choice"] = "auto"
                        
                        # Update system prompt to mention available tools
                        tool_names = [tool.get("function", {}).get("name", "unknown") for tool in tools_to_include]
                        tool_description = ""
                        if "gtd_read_daily_log" in tool_names:
                            tool_description += " You have access to read the user's daily logs to understand their activities and patterns. "
                        if "gtd_list_tasks" in tool_names:
                            tool_description += " You can list tasks to see what the user is working on. "
                        if "gtd_create_task" in tool_names:
                            tool_description += " You can create tasks when needed. "
                        if "gtd_list_projects" in tool_names:
                            tool_description += " You can list projects to understand the user's work. "
                        if "gtd_get_datetime" in tool_names:
                            tool_description += " You can get date/time information using gtd_get_datetime. Call it with relative date strings like '3 days ago', 'yesterday', or 'today' to get calculated dates automatically. "
                        
                        # CRITICAL: Always add tool calling instructions when tools are present
                        # This ensures the model knows how to use tools even if tool_description is empty
                        available_tools_str_async = ", ".join(tool_names)
                        tool_calling_instructions = """

================================================================================
HOW TO CALL TOOLS (CRITICAL):
================================================================================
When you need to use tools, you MUST use the function calling interface by including tool calls in the "tool_calls" field of your response message.

CORRECT FORMAT - Your response message should have this structure:
{
  "role": "assistant",
  "content": null,
  "tool_calls": [
    {
      "id": "call_abc123",
      "type": "function",
      "function": {
        "name": "gtd_read_daily_log",
        "arguments": "{\"date\": \"2025-01-05\"}"
      }
    }
  ]
}

IMPORTANT DETAILS:
- The "tool_calls" field is an ARRAY of tool call objects
- Each tool call has: "id", "type" (always "function"), and "function"
- The "function" object has: "name" (tool name) and "arguments" (JSON string)
- The "arguments" field must be a JSON STRING, not a JSON object
- Set "content" to null when making tool calls

WRONG FORMATS (DO NOT USE):
- {"name": "gtd_read_daily_log", "arguments": {"date": "2025-01-05"}} in content field
- Describing tools in text like "I would call gtd_read_daily_log..."
- Returning JSON strings in the "content" field

Available tools: """ + available_tools_str_async + """
"""
                        
                        # Always update the system message when tools are present
                        if payload.get("messages") and len(payload["messages"]) > 0:
                            if tool_description:
                                payload["messages"][0]["content"] = system_prompt + "\n\nYou have access to tools/functions to interact with the user's GTD system." + tool_description + tool_calling_instructions
                            else:
                                # Even if tool_description is empty, still add tool instructions
                                payload["messages"][0]["content"] = system_prompt + "\n\nYou have access to tools/functions to interact with the user's GTD system." + tool_calling_instructions
                        
                        # Add callback URL for tool execution
                        # CRITICAL: Tools require a callback URL to execute when using Ollama Controller
                        # For local execution (advice worker), tools are executed locally after receiving tool calls
                        # Only set callback URL when actually using Ollama Controller (Kubernetes)
                        if is_ollama_controller:
                            callback_url = get_tool_callback_url()
                            if callback_url:
                                payload["callback_url"] = callback_url
                                try:
                                    with open(log_file, "a", encoding="utf-8") as f:
                                        f.write(f"  -> ✅ Callback URL: {callback_url}\n")
                                except Exception:
                                    pass
                            else:
                                # Log warning if callback URL is missing for Ollama Controller
                                try:
                                    with open(log_file, "a", encoding="utf-8") as f:
                                        f.write(f"  -> ⚠️  WARNING: No callback URL configured - tools will not execute via Ollama Controller!\n")
                                        f.write(f"  -> Set GTD_TOOL_CALLBACK_URL environment variable or in config\n")
                                except Exception:
                                    pass
                        else:
                            # Local execution - advice worker will handle tool execution locally
                            # No callback URL needed - tools will be executed in the advice worker after receiving tool calls
                            try:
                                with open(log_file, "a", encoding="utf-8") as f:
                                    f.write(f"  -> ℹ️  Local execution mode - tools will be executed locally by advice worker\n")
                                    f.write(f"  -> No callback URL needed for local tool execution\n")
                            except Exception:
                                pass
                            # Still add tools to payload - model can see them but execution will fail
                            # This is better than not showing tools at all
                        
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ✅ Added {len(tools_to_include)} tool(s): {', '.join(tool_names)}\n")
                                f.write(f"  -> Tool choice: {payload.get('tool_choice', 'not set')}\n")
                                f.write(f"  -> Updated system prompt to mention tools\n")
                                f.write(f"  -> System prompt length: {len(payload['messages'][0]['content']) if payload.get('messages') else 0} chars\n")
                                if callback_url:
                                    f.write(f"  -> Callback URL configured: {callback_url}\n")
                                else:
                                    f.write(f"  -> ⚠️  WARNING: No callback URL configured - tools may not execute!\n")
                        except Exception:
                            pass
                    else:
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ⚠️  No tools available (get_tool_definitions returned empty list)\n")
                        except Exception:
                            pass
                except ImportError as e:
                    # Tool registry not available - continue without tools
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> ⚠️  Failed to import gtd_tool_registry: {e}\n")
                    except Exception:
                        pass
                except Exception as e:
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> ⚠️  Error adding tools: {e}\n")
                    except Exception:
                        pass
            else:
                try:
                    with open(log_file, "a", encoding="utf-8") as f:
                        f.write(f"  -> Not Ollama Controller - tools not added\n")
                except Exception:
                    pass
            
            # Log payload info
            try:
                data_size = len(json.dumps(payload).encode('utf-8'))
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(f"  -> Payload size: {data_size} bytes\n")
                    if "tools" in payload:
                        f.write(f"  -> ✅ Tools in payload: {len(payload['tools'])} tool(s)\n")
                    else:
                        f.write(f"  -> ⚠️  No tools in payload\n")
            except Exception:
                pass
            
            # Submit async request
            request_id, error = submit_ai_request_async(
                url=DEEP_MODEL_URL,
                payload=payload,
                callback=callback,
                max_poll_time=max_poll_time,
                poll_interval=2.0,
                result_file=result_file
            )
            
            if error:
                return f"Error: {error}"
            
            if request_id:
                # Check if it's an immediate response (JSON string) or request_id
                try:
                    result_data = json.loads(request_id)
                    if 'choices' in result_data:
                        # Immediate response
                        message = result_data['choices'][0].get('message', {})
                        content = message.get('content', '')
                        
                        # Check if model made tool calls
                        if 'tool_calls' in message and message['tool_calls']:
                            # Execute tool calls manually (Ollama Controller doesn't know about our GTD tools)
                            log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                            try:
                                with open(log_file, "a", encoding="utf-8") as f:
                                    f.write(f"[{datetime.now().isoformat()}] call_deep_ai (async immediate) - Tool calls detected!\n")
                                    f.write(f"  -> Model requested {len(message['tool_calls'])} tool call(s)\n")
                                    for i, tool_call in enumerate(message['tool_calls']):
                                        f.write(f"     Tool call {i+1}: {tool_call.get('function', {}).get('name', 'unknown')}\n")
                            except Exception:
                                pass
                            
                            # Execute tool calls and collect results
                            tool_results = []
                            for tool_call in message['tool_calls']:
                                function_name = tool_call.get('function', {}).get('name', '')
                                function_args = tool_call.get('function', {}).get('arguments', '{}')
                                tool_call_id = tool_call.get('id', '')
                                
                                try:
                                    args_dict = json.loads(function_args)
                                except json.JSONDecodeError:
                                    args_dict = {}
                                
                                # Execute the tool using the registry
                                try:
                                    # Import tool registry
                                    functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                                    if not functions_dir.exists():
                                        functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                                    if functions_dir.exists() and str(functions_dir) not in sys.path:
                                        sys.path.insert(0, str(functions_dir))
                                    from gtd_tool_registry import execute_tool
                                    tool_result = execute_tool(function_name, args_dict)
                                    
                                    # Log tool execution
                                    try:
                                        with open(log_file, "a", encoding="utf-8") as f:
                                            f.write(f"  -> Executed tool: {function_name}\n")
                                    except Exception:
                                        pass
                                    
                                    tool_results.append({
                                        "tool_call_id": tool_call_id,
                                        "role": "tool",
                                        "name": function_name,
                                        "content": tool_result
                                    })
                                except Exception as e:
                                    # Tool execution error
                                    error_msg = f"Error executing tool '{function_name}': {str(e)}"
                                    tool_results.append({
                                        "tool_call_id": tool_call_id,
                                        "role": "tool",
                                        "name": function_name,
                                        "content": error_msg
                                    })
                            
                            # Send tool results back to the model and get final answer (use blocking call for followup)
                            followup_messages = [
                                {"role": "system", "content": system_prompt},
                                {"role": "user", "content": prompt},
                                message,  # The assistant's message with tool calls
                            ]
                            followup_messages.extend(tool_results)  # Add tool results
                            
                            followup_payload = {
                                "model": actual_model_name,
                                "messages": followup_messages,
                                "temperature": 0.7,
                                "max_tokens": max_tokens,
                                "priority": request_priority
                            }
                            
                            # For async mode, use blocking call for followup (simpler than handling async callback)
                            try:
                                followup_data = json.dumps(followup_payload).encode('utf-8')
                                followup_req = urllib.request.Request(
                                    DEEP_MODEL_URL,
                                    data=followup_data,
                                    headers=_build_ollama_headers(DEEP_MODEL_URL)
                                )
                                
                                with urllib.request.urlopen(followup_req, timeout=timeout) as followup_response:
                                    followup_data = followup_response.read()
                                    followup_result = json.loads(followup_data.decode('utf-8'))
                                    
                                    # Handle async/queued responses from Ollama Controller
                                    base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                                    followup_polled_result, followup_poll_error = handle_ai_response(followup_result, base_url, max_poll_time=poll_timeout, poll_interval=0.5)
                                    
                                    if followup_poll_error:
                                        return f"Error in followup request: {followup_poll_error}"
                                    
                                    if followup_polled_result:
                                        followup_result = followup_polled_result
                                    
                                    if 'error' in followup_result:
                                        error_msg = followup_result['error'].get('message', 'Unknown error')
                                        return f"Error getting final answer: {error_msg}"
                                    
                                    if 'choices' in followup_result and len(followup_result['choices']) > 0:
                                        final_message = followup_result['choices'][0].get('message', {})
                                        final_content = final_message.get('content', '')
                                        finish_reason = followup_result['choices'][0].get('finish_reason', '')
                                        if finish_reason == 'length':
                                            final_content += "\n\n[Note: Response was truncated due to token limit.]"
                                        return final_content
                                    else:
                                        return "Error: Got a followup response but it's not quite right."
                            except Exception as e:
                                return f"Error executing tool calls: {e}"
                        
                        finish_reason = result_data['choices'][0].get('finish_reason', '')
                        if finish_reason == 'length':
                            content += "\n\n[Note: Response was truncated due to token limit.]"
                        return content
                except (json.JSONDecodeError, KeyError):
                    # It's a request_id
                    return f"Request submitted: {request_id}"
            
            return "No response from AI"
        except ImportError:
            # Fall back to blocking mode if async module not available
            print("⚠️  Async module not available, falling back to blocking mode", file=sys.stderr)
            use_async = False
        except Exception as e:
            # Fall back to blocking mode on error
            print(f"⚠️  Error using async mode: {e}, falling back to blocking mode", file=sys.stderr)
            use_async = False
    
    # Continue with blocking mode (original implementation)
    
    # Check if Ollama Controller is ready (if using it)
    if ":31080" in DEEP_MODEL_URL:
        is_ready, ready_msg = _check_ollama_controller_ready(DEEP_MODEL_URL)
        if not is_ready:
            return f"Error: Ollama Controller is not ready at {DEEP_MODEL_URL}.\n\n{ready_msg}\n\nThis usually means:\n1. The controller was just restarted and needs time to start\n2. The controller needs to be redeployed (not just restarted)\n3. The NodePort service isn't configured\n\nTo fix:\n  gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable\n\nOr manually:\n  cd ~/code/external_services/ollama_controller && make k8s-deploy"
    
    if system_prompt is None:
        system_prompt = f"You are {USER_NAME}'s deep thinking GTD analyst. You provide comprehensive, thoughtful analysis."
    
    # Check if model URL is accessible and find matching model
    actual_model_name = DEEP_MODEL_NAME
    available_models = []
    try:
        test_req = urllib.request.Request(f"{DEEP_MODEL_URL.rsplit('/v1', 1)[0]}/v1/models", headers=_build_ollama_headers(DEEP_MODEL_URL))
        with urllib.request.urlopen(test_req, timeout=5) as test_response:
            models_data = json.loads(test_response.read().decode('utf-8'))
            available_models = [m.get('id', '') for m in models_data.get('data', [])]
            
            # Check for exact match first
            if DEEP_MODEL_NAME in available_models:
                actual_model_name = DEEP_MODEL_NAME
            else:
                # Try partial match - check if configured name is in any available model ID
                # (e.g., "gpt-oss-20b" should match "openai/gpt-oss-20b")
                matched = False
                for model_id in available_models:
                    if DEEP_MODEL_NAME in model_id or model_id.endswith(DEEP_MODEL_NAME):
                        actual_model_name = model_id
                        matched = True
                        break
                    # Also check reverse - if model_id is in configured name
                    # (e.g., if configured is "openai/gpt-oss-20b" but available is "gpt-oss-20b")
                    if model_id in DEEP_MODEL_NAME:
                        actual_model_name = model_id
                        matched = True
                        break
                
                if not matched:
                    return f"Error: Model '{DEEP_MODEL_NAME}' not found in LM Studio. Available models: {', '.join(available_models[:5])}"
    except urllib.error.HTTPError as e:
        # Check if this is a 404 from Ollama Controller
        if e.code == 404 and (":31080" in DEEP_MODEL_URL or "31080" in str(DEEP_MODEL_URL)):
            return f"Error: Ollama Controller endpoint not found at {DEEP_MODEL_URL}. The controller may not be fully deployed or the endpoint isn't ready yet.\n\nThis usually means:\n1. The controller was just restarted and needs time to start\n2. The controller needs to be redeployed (not just restarted)\n3. The NodePort service isn't configured\n\nTo fix:\n  gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable\n\nOr manually:\n  cd ~/code/external_services/ollama_controller && make k8s-deploy"
        else:
            error_msg = str(e)
            if ":31080" in DEEP_MODEL_URL or "31080" in error_msg:
                return f"Error: Cannot connect to Ollama Controller at {DEEP_MODEL_URL} (HTTP {e.code}). Make sure the controller is deployed and running. Error: {e}\n\nTo enable: gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable"
            else:
                return f"Error: Cannot connect to AI service at {DEEP_MODEL_URL} (HTTP {e.code}). Make sure the service is running and a model is loaded. Error: {e}"
    except Exception as e:
        error_msg = str(e)
        # Check if this is an Ollama Controller connection issue
        if ":31080" in DEEP_MODEL_URL or "31080" in error_msg:
            if "404" in error_msg or "Not Found" in error_msg:
                return f"Error: Ollama Controller endpoint not found at {DEEP_MODEL_URL}. The controller may not be deployed or needs to be redeployed.\n\nTo enable: gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable"
            else:
                return f"Error: Cannot connect to Ollama Controller at {DEEP_MODEL_URL}. Make sure the controller is deployed and running. Error: {e}\n\nTo enable: gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable"
        else:
            return f"Error: Cannot connect to AI service at {DEEP_MODEL_URL}. Make sure the service is running and a model is loaded. Error: {e}"
    
    # Get priority from environment variable or default to 20 (NORMAL for background)
    request_priority = 20  # Default priority for background tasks
    if os.getenv("GTD_REQUEST_PRIORITY"):
        try:
            request_priority = int(os.getenv("GTD_REQUEST_PRIORITY"))
        except (ValueError, TypeError):
            request_priority = 20  # Fallback to default if invalid
    
    payload = {
        "model": actual_model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": max_tokens,
        "priority": request_priority,  # Use priority from environment or default to 20
    }
    
    # Add tools if using Ollama Controller (controller supports tools regardless of model)
    # Or if force_tools is True (for advice worker and other cases where tools are always needed)
    is_ollama_controller = ":31080" in DEEP_MODEL_URL or "31080" in DEEP_MODEL_URL
    if force_tools and not is_ollama_controller:
        # If force_tools is True but not using Ollama Controller, log warning but still try
        try:
            log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"  -> ⚠️  force_tools=True but not using Ollama Controller (URL: {DEEP_MODEL_URL})\n")
        except Exception:
            pass
    
    # Log to tool_calls.log for debugging
    log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
    try:
        from datetime import datetime
        log_file.parent.mkdir(parents=True, exist_ok=True)
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"[{datetime.now().isoformat()}] call_deep_ai (blocking) - Model: {actual_model_name}, URL: {DEEP_MODEL_URL}\n")
            f.write(f"  -> Ollama Controller: {is_ollama_controller}\n")
    except Exception:
        pass
    
    if is_ollama_controller or force_tools:
        try:
            # Import tool registry
            functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
            if not functions_dir.exists():
                functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
            if functions_dir.exists() and str(functions_dir) not in sys.path:
                sys.path.insert(0, str(functions_dir))
            from gtd_tool_registry import get_tool_definitions
            
            # Include GTD tools by default for deep analysis (comprehensive advice)
            tools_to_include = []
            gtd_tools = get_tool_definitions(categories=["gtd"])
            tools_to_include.extend(gtd_tools)
            
            if tools_to_include:
                payload["tools"] = tools_to_include
                payload["tool_choice"] = "auto"
                
                # Update system prompt to mention available tools
                tool_names = [tool.get("function", {}).get("name", "unknown") for tool in tools_to_include]
                tool_description = ""
                if "gtd_read_daily_log" in tool_names:
                    tool_description += " You have access to read the user's daily logs to understand their activities and patterns. "
                if "gtd_list_tasks" in tool_names:
                    tool_description += " You can list tasks to see what the user is working on. "
                if "gtd_create_task" in tool_names:
                    tool_description += " You can create tasks when needed. "
                if "gtd_list_projects" in tool_names:
                    tool_description += " You can list projects to understand the user's work. "
                if "gtd_get_datetime" in tool_names:
                    tool_description += " You can get date/time information using gtd_get_datetime. Call it with relative date strings like '3 days ago', 'yesterday', or 'today' to get calculated dates automatically. "
                
                # CRITICAL: Always add tool calling instructions when tools are present
                # This ensures the model knows how to use tools even if tool_description is empty
                available_tools_str = ", ".join(tool_names)
                tool_calling_instructions = """

================================================================================
HOW TO CALL TOOLS (CRITICAL):
================================================================================
When you need to use tools, you MUST use the function calling interface by including tool calls in the "tool_calls" field of your response message.

CORRECT FORMAT - Your response message should have this structure:
{
  "role": "assistant",
  "content": null,
  "tool_calls": [
    {
      "id": "call_abc123",
      "type": "function",
      "function": {
        "name": "gtd_read_daily_log",
        "arguments": "{\"date\": \"2025-01-05\"}"
      }
    }
  ]
}

IMPORTANT DETAILS:
- The "tool_calls" field is an ARRAY of tool call objects
- Each tool call has: "id", "type" (always "function"), and "function"
- The "function" object has: "name" (tool name) and "arguments" (JSON string)
- The "arguments" field must be a JSON STRING, not a JSON object
- Set "content" to null when making tool calls

WRONG FORMATS (DO NOT USE):
- {"name": "gtd_read_daily_log", "arguments": {"date": "2025-01-05"}} in content field
- Describing tools in text like "I would call gtd_read_daily_log..."
- Returning JSON strings in the "content" field

Available tools: """ + available_tools_str + """
"""
                
                # Always update the system message when tools are present
                if payload.get("messages") and len(payload["messages"]) > 0:
                    if tool_description:
                        payload["messages"][0]["content"] = system_prompt + "\n\nYou have access to tools/functions to interact with the user's GTD system." + tool_description + tool_calling_instructions
                    else:
                        # Even if tool_description is empty, still add tool instructions
                        payload["messages"][0]["content"] = system_prompt + "\n\nYou have access to tools/functions to interact with the user's GTD system." + tool_calling_instructions
                
                # Add callback URL for tool execution
                # CRITICAL: Tools require a callback URL to execute when using Ollama Controller
                # For local execution (blocking mode), tools are executed locally in this function
                # Only set callback URL when actually using Ollama Controller (Kubernetes)
                callback_url = None
                if is_ollama_controller:
                    callback_url = get_tool_callback_url()
                    if callback_url:
                        payload["callback_url"] = callback_url
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ✅ Callback URL: {callback_url}\n")
                        except Exception:
                            pass
                    else:
                        # Log warning if callback URL is missing for Ollama Controller
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ⚠️  WARNING: No callback URL configured - tools will not execute via Ollama Controller!\n")
                                f.write(f"  -> Set GTD_TOOL_CALLBACK_URL environment variable or in config\n")
                        except Exception:
                            pass
                else:
                    # Local execution - tools will be executed locally in this function
                    # No callback URL needed
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> ℹ️  Local execution mode - tools will be executed locally\n")
                            f.write(f"  -> No callback URL needed for local tool execution\n")
                    except Exception:
                        pass
                
                try:
                    with open(log_file, "a", encoding="utf-8") as f:
                        f.write(f"  -> ✅ Added {len(tools_to_include)} tool(s): {', '.join(tool_names)}\n")
                        f.write(f"  -> Tool choice: {payload.get('tool_choice', 'not set')}\n")
                        f.write(f"  -> Updated system prompt to mention tools\n")
                        f.write(f"  -> System prompt length: {len(payload['messages'][0]['content']) if payload.get('messages') else 0} chars\n")
                        if callback_url:
                            f.write(f"  -> Callback URL configured: {callback_url}\n")
                        else:
                            f.write(f"  -> ⚠️  WARNING: No callback URL configured - tools may not execute!\n")
                except Exception:
                    pass
            else:
                try:
                    with open(log_file, "a", encoding="utf-8") as f:
                        f.write(f"  -> ⚠️  No tools available (get_tool_definitions returned empty list)\n")
                except Exception:
                    pass
        except ImportError as e:
            # Tool registry not available - continue without tools
            try:
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(f"  -> ⚠️  Failed to import gtd_tool_registry: {e}\n")
            except Exception:
                pass
        except Exception as e:
            try:
                with open(log_file, "a", encoding="utf-8") as f:
                    f.write(f"  -> ⚠️  Error adding tools: {e}\n")
            except Exception:
                pass
    else:
        try:
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"  -> Not Ollama Controller - tools not added\n")
        except Exception:
            pass
    
    # Log payload info before encoding
    try:
        data_size = len(json.dumps(payload).encode('utf-8'))
        with open(log_file, "a", encoding="utf-8") as f:
            f.write(f"  -> Payload size: {data_size} bytes\n")
            if "tools" in payload:
                f.write(f"  -> ✅ Tools in payload: {len(payload['tools'])} tool(s)\n")
            else:
                f.write(f"  -> ⚠️  No tools in payload\n")
    except Exception:
        pass
    
    data = json.dumps(payload).encode('utf-8')
    
    # Longer timeout for deep analysis
    # Thinking models may need more time for their reasoning phase
    # Check if it's a thinking model and increase timeout accordingly
    is_thinking_model = "thinking" in actual_model_name.lower()
    
    # Get timeout from environment variable, config, or default to 120
    base_timeout = 120
    timeout_source = "default"
    
    if os.getenv("DEEP_MODEL_TIMEOUT"):
        try:
            base_timeout = int(os.getenv("DEEP_MODEL_TIMEOUT"))
            timeout_source = "environment"
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("deep_model_timeout"):
        try:
            base_timeout = int(GTD_CONFIG.get("deep_model_timeout"))
            timeout_source = f"config ({GTD_CONFIG.get('deep_model_timeout')})"
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("timeout"):
        try:
            base_timeout = int(GTD_CONFIG.get("timeout"))
            timeout_source = "config (timeout key)"
        except (ValueError, TypeError):
            pass
    
    # Debug: Print what we found
    if os.getenv("GTD_DEBUG"):
        print(f"DEBUG: Timeout resolution - base_timeout={base_timeout}, source={timeout_source}, GTD_CONFIG keys={list(GTD_CONFIG.keys())}", file=sys.stderr)
        print(f"DEBUG: GTD_CONFIG['deep_model_timeout']={GTD_CONFIG.get('deep_model_timeout')}", file=sys.stderr)
    
    # If max_poll_time was provided, use it (even in blocking mode, this indicates desired timeout)
    # Otherwise, use timeout from config/environment
    if max_poll_time is not None:
        timeout = int(max_poll_time)
        timeout_source = "max_poll_time parameter"
    elif is_thinking_model:
        # Thinking models get extra time (they do internal reasoning)
        # For thinking models, ensure minimum timeout of 300s unless user configured higher
        if base_timeout < 300:
            # User hasn't configured for thinking models - use minimum 300s
            timeout = 300
            print(f"⚠️  Thinking model detected but timeout ({base_timeout}s) is low. Using minimum 300s for thinking models.", file=sys.stderr)
        else:
            # User has configured appropriately - use their value
            timeout = base_timeout
    else:
        # Regular model - use configured timeout
        # For Ollama Controller, use longer timeout to handle queued requests (at least 60 minutes)
        if ":31080" in DEEP_MODEL_URL or "31080" in DEEP_MODEL_URL:
            # Using Ollama Controller - requests can be queued, so use longer timeout
            timeout = max(base_timeout, 3600)  # At least 60 minutes
            if timeout > base_timeout:
                timeout_source = f"config ({base_timeout}s) increased to {timeout}s for Ollama Controller"
        else:
            timeout = base_timeout
    
    # Log timeout being used (for debugging)
    print(f"🔧 Deep AI Timeout: {timeout}s (base: {base_timeout}s, source: {timeout_source}, thinking_model: {is_thinking_model})", file=sys.stderr)
    
    # Helper function to make the actual request
    def _make_request(request_data: bytes, timeout_val: int):
        req = urllib.request.Request(
            DEEP_MODEL_URL,
            data=request_data,
            headers=_build_ollama_headers(DEEP_MODEL_URL)
        )
        return urllib.request.urlopen(req, timeout=timeout_val)
    
    # Try the primary model first
    try:
        with _make_request(data, timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                error_type = result['error'].get('type', 'unknown')
                # Check if model is unloaded - wait and retry once
                if 'model unloaded' in error_msg.lower() or 'unloaded' in error_msg.lower():
                    # Check if model exists in available models
                    model_exists = _load_model(actual_model_name, DEEP_MODEL_URL)
                    if model_exists:
                        # Model exists but isn't loaded - wait a moment and retry once
                        # (User might be loading it, or we're giving it time to auto-load)
                        time.sleep(3)
                        # Retry the original request
                        try:
                            with _make_request(data, timeout) as retry_response:
                                retry_result = json.loads(retry_response.read().decode('utf-8'))
                                if 'error' not in retry_result and 'choices' in retry_result and len(retry_result['choices']) > 0:
                                    content = retry_result['choices'][0]['message']['content']
                                    finish_reason = retry_result['choices'][0].get('finish_reason', '')
                                    if finish_reason == 'length':
                                        content += "\n\n[Note: Response was truncated due to token limit.]"
                                    return content
                        except Exception as retry_e:
                            # Retry failed - model still not loaded
                            pass
                    # If retry failed or model doesn't exist, return helpful error
                    return f"Model '{actual_model_name}' is not loaded in LM Studio.\n\nPlease:\n1. Open LM Studio\n2. Go to the 'Chat' or 'Models' tab\n3. Select '{actual_model_name}' and click 'Load'\n4. Wait for the model to finish loading\n5. Try again\n\nAvailable models: {', '.join(available_models[:5]) if available_models else 'None found'}"
                # Check if it's a resource/loading error - try fallback models
                if 'insufficient system resources' in error_msg.lower() or 'model loading' in error_msg.lower():
                    return _try_fallback_models(prompt, system_prompt, max_tokens, available_models, actual_model_name, error_msg)
                return f"Error from AI: [{error_type}] {error_msg}"
            
            # Handle async/queued responses from Ollama Controller
            base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
            # Use provided max_poll_time if given, otherwise use timeout
            # For long-running requests (like advice), use longer polling time
            # When using Ollama Controller, use longer timeout for async polling (at least 60 minutes)
            if max_poll_time is not None:
                poll_timeout = max_poll_time
            elif ":31080" in DEEP_MODEL_URL:
                # Using Ollama Controller - use longer timeout for async polling
                # Default to 3600s (60 min) for long-running requests, or use configured timeout if longer
                poll_timeout = max(timeout, 3600)
            else:
                poll_timeout = timeout
            polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=poll_timeout, poll_interval=0.5)
            
            if poll_error:
                return f"Error: {poll_error}"
            
            if polled_result:
                result = polled_result
            
            if 'choices' in result and len(result['choices']) > 0:
                message = result['choices'][0].get('message', {})
                content = message.get('content', '')
                
                # Check if model made tool calls
                if 'tool_calls' in message and message['tool_calls']:
                    # Execute tool calls manually (Ollama Controller doesn't know about our GTD tools)
                    log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"[{datetime.now().isoformat()}] call_deep_ai (blocking) - Tool calls detected!\n")
                            f.write(f"  -> Model requested {len(message['tool_calls'])} tool call(s)\n")
                            for i, tool_call in enumerate(message['tool_calls']):
                                f.write(f"     Tool call {i+1}: {tool_call.get('function', {}).get('name', 'unknown')}\n")
                    except Exception:
                        pass
                    
                    # Execute tool calls and collect results
                    tool_results = []
                    for tool_call in message['tool_calls']:
                        function_name = tool_call.get('function', {}).get('name', '')
                        function_args = tool_call.get('function', {}).get('arguments', '{}')
                        tool_call_id = tool_call.get('id', '')
                        
                        try:
                            args_dict = json.loads(function_args)
                        except json.JSONDecodeError:
                            args_dict = {}
                        
                        # Execute the tool using the registry
                        try:
                            # Import tool registry
                            functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                            if not functions_dir.exists():
                                functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                            if functions_dir.exists() and str(functions_dir) not in sys.path:
                                sys.path.insert(0, str(functions_dir))
                            from gtd_tool_registry import execute_tool
                            tool_result = execute_tool(function_name, args_dict)
                            
                            # Log tool execution
                            try:
                                with open(log_file, "a", encoding="utf-8") as f:
                                    f.write(f"  -> Executed tool: {function_name}\n")
                                    f.write(f"  -> Result length: {len(tool_result)} chars\n")
                                    if len(tool_result) < 500:
                                        f.write(f"  -> Result: {tool_result}\n")
                                    else:
                                        f.write(f"  -> Result preview: {tool_result[:300]}...\n")
                            except Exception:
                                pass
                            
                            tool_results.append({
                                "tool_call_id": tool_call_id,
                                "role": "tool",
                                "name": function_name,
                                "content": tool_result
                            })
                        except Exception as e:
                            # Tool execution error
                            error_msg = f"Error executing tool '{function_name}': {str(e)}"
                            try:
                                with open(log_file, "a", encoding="utf-8") as f:
                                    f.write(f"  -> ERROR: {error_msg}\n")
                            except Exception:
                                pass
                            tool_results.append({
                                "tool_call_id": tool_call_id,
                                "role": "tool",
                                "name": function_name,
                                "content": error_msg
                            })
                    
                    # Send tool results back to the model and get final answer
                    followup_messages = [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": prompt},
                        message,  # The assistant's message with tool calls
                    ]
                    followup_messages.extend(tool_results)  # Add tool results
                    
                    # Log what we're sending back
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> Sending followup with {len(tool_results)} tool result(s)\n")
                    except Exception:
                        pass
                    
                    followup_payload = {
                        "model": actual_model_name,
                        "messages": followup_messages,
                        "temperature": 0.7,
                        "max_tokens": max_tokens,
                        "priority": request_priority
                    }
                    
                    # Don't include tools in followup - model should respond with final answer
                    
                    # Send followup request (with same async handling as initial request)
                    try:
                        followup_data = json.dumps(followup_payload).encode('utf-8')
                        followup_req = urllib.request.Request(
                            DEEP_MODEL_URL,
                            data=followup_data,
                            headers=_build_ollama_headers(DEEP_MODEL_URL)
                        )
                        
                        with urllib.request.urlopen(followup_req, timeout=timeout) as followup_response:
                            followup_data = followup_response.read()
                            followup_result = json.loads(followup_data.decode('utf-8'))
                            
                            # Handle async/queued responses from Ollama Controller
                            base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                            followup_polled_result, followup_poll_error = handle_ai_response(followup_result, base_url, max_poll_time=poll_timeout, poll_interval=0.5)
                            
                            if followup_poll_error:
                                return f"Error in followup request: {followup_poll_error}"
                            
                            if followup_polled_result:
                                followup_result = followup_polled_result
                            
                            if 'error' in followup_result:
                                error_msg = followup_result['error'].get('message', 'Unknown error')
                                return f"Error getting final answer: {error_msg}"
                            
                            if 'choices' in followup_result and len(followup_result['choices']) > 0:
                                final_message = followup_result['choices'][0].get('message', {})
                                final_content = final_message.get('content', '')
                                finish_reason = followup_result['choices'][0].get('finish_reason', '')
                                if finish_reason == 'length':
                                    final_content += "\n\n[Note: Response was truncated due to token limit. Consider increasing max_tokens for complete analysis.]"
                                return final_content
                            else:
                                return "Error: Got a followup response but it's not quite right."
                    except Exception as e:
                        return f"Error executing tool calls: {e}"
                
                # Check if response was truncated (common indicators)
                finish_reason = result['choices'][0].get('finish_reason', '')
                if finish_reason == 'length':
                    # Response was cut off due to token limit
                    content += "\n\n[Note: Response was truncated due to token limit. Consider increasing max_tokens for complete analysis.]"
                return content
            return "No response from AI"
    except urllib.error.HTTPError as e:
        error_body = ""
        try:
            error_body = e.read().decode('utf-8')
            error_json = json.loads(error_body)
            error_msg = error_json.get('error', {}).get('message', error_body)
            # Check if model is unloaded - wait and retry once
            if ('model unloaded' in error_msg.lower() or 'unloaded' in error_msg.lower()) and e.code == 400:
                # Check if model exists in available models
                model_exists = _load_model(actual_model_name, DEEP_MODEL_URL)
                if model_exists:
                    # Model exists but isn't loaded - wait and retry once
                    time.sleep(3)
                    try:
                        with _make_request(data, timeout) as retry_response:
                            retry_result = json.loads(retry_response.read().decode('utf-8'))
                            if 'error' not in retry_result and 'choices' in retry_result and len(retry_result['choices']) > 0:
                                return retry_result['choices'][0]['message']['content']
                    except Exception:
                        # Retry failed - model still not loaded, try fallback models
                        pass
                # If retry failed or model doesn't exist, try fallback models
                return _try_fallback_models(prompt, system_prompt, max_tokens, available_models, actual_model_name, f"Model unloaded: {error_msg}")
            # Check if it's a resource/loading error - try fallback models
            if 'insufficient system resources' in error_msg.lower() or 'model loading' in error_msg.lower() or e.code == 400:
                return _try_fallback_models(prompt, system_prompt, max_tokens, available_models, actual_model_name, error_msg)
        except:
            error_msg = error_body or str(e)
        
        # Check if this is a 404 from Ollama Controller
        if e.code == 404 and (":31080" in DEEP_MODEL_URL or "31080" in str(DEEP_MODEL_URL)):
            return f"Error: Ollama Controller endpoint not found (HTTP 404) at {DEEP_MODEL_URL}.\n\nThe controller may not be fully deployed or the endpoint isn't ready yet.\n\nTo fix:\n  gtd-wizard → Infrastructure → External Services → Ollama Controller → Deploy/Enable\n\nOr manually:\n  cd ~/code/external_services/ollama_controller && make k8s-deploy\n\nNote: If you just restarted the controller, it may need a full redeploy (not just restart) to enable the /v1 endpoints."
        else:
            return f"Error calling deep AI (HTTP {e.code}): {error_msg}. Model: {actual_model_name}, URL: {DEEP_MODEL_URL}"
    except urllib.error.URLError as e:
        # Check if it's a timeout error
        if "timed out" in str(e).lower() or "timeout" in str(e).lower():
            timeout_msg = f"timed out after {timeout}s"
            suggestion = ""
            
            # Check if model is actually loaded (not just available)
            model_loaded = False
            try:
                check_req = urllib.request.Request(
                    f"{DEEP_MODEL_URL.rsplit('/v1', 1)[0]}/v1/models",
                    headers=_build_ollama_headers(DEEP_MODEL_URL)
                )
                with urllib.request.urlopen(check_req, timeout=5) as check_resp:
                    check_data = json.loads(check_resp.read().decode('utf-8'))
                    loaded_models = [m.get('id', '') for m in check_data.get('data', [])]
                    # Check if our model is in the loaded list
                    for loaded_model in loaded_models:
                        if actual_model_name in loaded_model or loaded_model in actual_model_name:
                            model_loaded = True
                            break
            except:
                pass  # Can't check, assume not loaded
            
            if is_thinking_model:
                suggestion = f"\n\nThinking models like '{actual_model_name}' may need more time for their reasoning phase."
                if not model_loaded:
                    suggestion += f"\n⚠️  Model may not be loaded in LM Studio."
                suggestion += f"\n\nConsider:\n"
                suggestion += f"1. Check if model is loaded: Open LM Studio → Chat tab → Verify '{actual_model_name}' is loaded\n"
                suggestion += f"2. Increase timeout: Add 'DEEP_MODEL_TIMEOUT=\"300\"' to your .gtd_config_ai\n"
                suggestion += f"3. Check model status: curl {DEEP_MODEL_URL.rsplit('/v1', 1)[0]}/v1/models\n"
                suggestion += f"4. Try a smaller model or reduce max_tokens"
            else:
                suggestion = f"\n\nConsider:\n"
                if not model_loaded:
                    suggestion += f"1. ⚠️  Model may not be loaded: Open LM Studio → Chat tab → Load '{actual_model_name}'\n"
                else:
                    suggestion += f"1. Model appears loaded but timed out - may be processing or stuck\n"
                suggestion += f"2. Increase timeout: Add 'DEEP_MODEL_TIMEOUT=\"180\"' to your .gtd_config_ai\n"
                suggestion += f"3. Check LM Studio server status\n"
            return f"Error calling deep AI: {timeout_msg}. Model: {actual_model_name}, URL: {DEEP_MODEL_URL}{suggestion}"
        return f"Error connecting to AI: {e}. Check that LM Studio is running at {DEEP_MODEL_URL}"
    except Exception as e:
        # Check if it's a timeout in the exception message
        if "timed out" in str(e).lower() or "timeout" in str(e).lower():
            timeout_msg = f"timed out after {timeout}s"
            suggestion = ""
            if is_thinking_model:
                suggestion = f"\n\nThinking models need more time. Increase DEEP_MODEL_TIMEOUT in config."
            return f"Error calling deep AI: {timeout_msg}. Model: {actual_model_name}, URL: {DEEP_MODEL_URL}{suggestion}"
        return f"Error calling deep AI: {e}. Model: {actual_model_name}, URL: {DEEP_MODEL_URL}"


def _load_model(model_name: str, base_url: str) -> bool:
    """
    Check if a model can be loaded and wait for it to become available.
    Returns True if model appears to be available, False otherwise.
    
    Note: LM Studio doesn't have a direct API endpoint for loading models programmatically.
    Models must be loaded through the LM Studio UI. This function:
    1. Checks if the model exists in available models
    2. Waits a bit for it to potentially be loaded
    3. Returns True if model exists (allowing retry), False otherwise
    """
    import urllib.request
    import urllib.error
    
    try:
        # Check available models
        base_api_url = base_url.rsplit('/v1', 1)[0]
        models_req = urllib.request.Request(
            f"{base_api_url}/v1/models",
            headers=_build_ollama_headers(base_url)
        )
        with urllib.request.urlopen(models_req, timeout=5) as models_resp:
            models_data = json.loads(models_resp.read().decode('utf-8'))
            available_models = [m.get('id', '') for m in models_data.get('data', [])]
            
            # Check if model exists (either exact match or partial)
            model_found = False
            if model_name in available_models:
                model_found = True
            else:
                # Try partial match
                for available_model in available_models:
                    if model_name in available_model or available_model in model_name:
                        model_found = True
                        break
            
            if model_found:
                # Model exists - wait a moment in case user is loading it
                # then return True to allow retry
                time.sleep(3)
                return True
            else:
                # Model doesn't exist in available models
                return False
    except Exception:
        # If we can't check, return False (don't retry)
        return False


def _try_fallback_models(prompt: str, system_prompt: str, max_tokens: int, available_models: list, failed_model: str, original_error: str) -> str:
    """Try fallback models if the primary model fails due to resource constraints."""
    # Get timeout from environment variable, config, or default to 120
    base_timeout = 120
    if os.getenv("DEEP_MODEL_TIMEOUT"):
        try:
            base_timeout = int(os.getenv("DEEP_MODEL_TIMEOUT"))
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("deep_model_timeout"):
        try:
            base_timeout = int(GTD_CONFIG.get("deep_model_timeout"))
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("timeout"):
        try:
            base_timeout = int(GTD_CONFIG.get("timeout"))
        except (ValueError, TypeError):
            pass
    
    # Prefer smaller models that are likely to work
    # Order: 7B -> 4B -> 3B -> 1B -> any other model
    fallback_priorities = [
        '7b', '7B',
        '4b', '4B', 
        '3b', '3B',
        '1b', '1B',
    ]
    
    # Find fallback models (exclude the one that failed and embedding models)
    fallback_candidates = []
    for model_id in available_models:
        if model_id == failed_model:
            continue
        if 'embedding' in model_id.lower():
            continue
        fallback_candidates.append(model_id)
    
    if not fallback_candidates:
        return f"Error: Primary model '{failed_model}' failed to load due to insufficient resources: {original_error}. No alternative models available."
    
    # Sort by priority (smaller models first)
    def get_priority(model_id):
        for i, priority in enumerate(fallback_priorities):
            if priority in model_id:
                return i
        return 999  # Lower priority for models without size indicators
    
    fallback_candidates.sort(key=get_priority)
    
    # Try each fallback model
    for fallback_model in fallback_candidates[:3]:  # Try up to 3 fallback models
        try:
            payload = {
                "model": fallback_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": prompt}
                ],
                "temperature": 0.7,
                "max_tokens": max_tokens,
            }
            
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(
                DEEP_MODEL_URL,
                data=data,
                headers=_build_ollama_headers(DEEP_MODEL_URL)
            )
            
            # Use base timeout for fallback models (they're usually smaller/faster)
            with urllib.request.urlopen(req, timeout=base_timeout) as response:
                result = json.loads(response.read().decode('utf-8'))
                if 'error' in result:
                    continue  # Try next fallback
                if 'choices' in result and len(result['choices']) > 0:
                    return result['choices'][0]['message']['content']
        except Exception:
            continue  # Try next fallback
    
    # All fallbacks failed
    return f"Error: Primary model '{failed_model}' and all fallback models failed. Original error: {original_error}. Available models: {', '.join(available_models[:5])}. Consider using a smaller model or freeing up system resources."


def read_daily_log(date: str) -> str:
    """Read a daily log file."""
    # Try both .md and .txt extensions
    for ext in [".md", ".txt"]:
        log_file = DAILY_LOG_DIR / f"{date}{ext}"
        if log_file.exists():
            with open(log_file, 'r') as f:
                return f.read()
    return ""


def read_recent_logs(days: int) -> List[Dict[str, str]]:
    """Read recent daily logs."""
    logs = []
    for i in range(days):
        date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
        content = read_daily_log(date)
        if content:
            logs.append({"date": date, "content": content})
    return logs


def find_task_files() -> List[Path]:
    """Find all task files."""
    tasks = []
    tasks_dir = GTD_BASE_DIR / "tasks"
    projects_dir = GTD_BASE_DIR / "1-projects"
    
    if tasks_dir.exists():
        tasks.extend(tasks_dir.glob("*.md"))
    
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if project_dir.is_dir():
                tasks.extend(project_dir.glob("*.md"))
    
    return tasks


def _call_deep_ai_with_async(prompt: str, system_prompt: str, max_tokens: int, analysis_type: str, result_data: Dict[str, Any]) -> str:
    """
    Helper to call deep AI with async support for background tasks.
    
    Returns the analysis result (blocking) or request_id (async).
    If async, the callback handles saving the result.
    """
    use_async = os.getenv("DEEP_ANALYSIS_USE_ASYNC", "true").lower() == "true" and ":31080" in DEEP_MODEL_URL
    
    if use_async:
        result_file = f"{analysis_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        def on_complete(result_str, error):
            if error:
                error_result = {
                    **result_data,
                    "error": error,
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / f"error_{result_file}"
                with open(result_path, 'w') as f:
                    json.dump(error_result, f, indent=2)
            else:
                result_json = json.loads(result_str)
                content = result_json['choices'][0]['message']['content']
                result = {
                    **result_data,
                    "analysis": content,
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / result_file
                with open(result_path, 'w') as f:
                    json.dump(result, f, indent=2)
                send_discord_notification_for_result(analysis_type, result, result_path)
                send_local_notification_for_result(analysis_type, result, result_path)
        
        request_id = call_deep_ai(prompt, system_prompt, max_tokens, use_async=True, callback=on_complete, result_file=result_file)
        return request_id.replace("Request submitted: ", "") if "Request submitted: " in request_id else request_id
    else:
        # Blocking mode
        return call_deep_ai(prompt, system_prompt, max_tokens, use_async=False)


def analyze_weekly_review(context: Dict[str, Any]) -> Dict[str, Any]:
    """Perform weekly review analysis."""
    week_start = context.get("week_start", (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d"))
    
    # Gather data
    logs = read_recent_logs(7)
    tasks = find_task_files()
    
    # Build comprehensive prompt
    prompt = f"""Perform a comprehensive weekly review for {USER_NAME} for the week starting {week_start}.

Daily Logs Summary:
{chr(10).join([f"{log['date']}: {log['content'][:200]}..." for log in logs])}

Task Files Found: {len(tasks)}

Analyze:
1. **Productivity Patterns**: What patterns do you see in their work? When are they most productive?
2. **Accomplishments**: What did they complete this week? Celebrate wins.
3. **Challenges**: What struggles or blockers appeared?
4. **Energy Patterns**: When did they have high/low energy? What activities correlate?
5. **Goals Progress**: Are they making progress on their goals?
6. **Next Week Priorities**: What should they focus on next week?
7. **Suggestions**: Concrete, actionable suggestions for improvement.

Provide a structured, comprehensive analysis. Be specific, reference actual entries, and be encouraging."""
    
    system_prompt = f"""You are a deep thinking productivity analyst helping {USER_NAME} understand their patterns and optimize their work. You provide comprehensive, insightful analysis."""
    
    # Get max_tokens from config or use default (higher for weekly reviews)
    # Weekly reviews need more tokens for comprehensive analysis
    weekly_max_tokens = 6000  # Increased from 3000 to 6000 for comprehensive weekly reviews
    if os.getenv("DEEP_ANALYSIS_MAX_TOKENS") or os.getenv("WEEKLY_REVIEW_MAX_TOKENS"):
        try:
            weekly_max_tokens = int(os.getenv("DEEP_ANALYSIS_MAX_TOKENS") or os.getenv("WEEKLY_REVIEW_MAX_TOKENS"))
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("deep_analysis_max_tokens") or GTD_CONFIG.get("weekly_review_max_tokens"):
        try:
            weekly_max_tokens = int(GTD_CONFIG.get("deep_analysis_max_tokens") or GTD_CONFIG.get("weekly_review_max_tokens"))
        except (ValueError, TypeError):
            pass
    
    analysis = _call_deep_ai_with_async(
        prompt, system_prompt, weekly_max_tokens, "weekly_review",
        {"type": "weekly_review", "week_start": week_start}
    )
    
    # If async, return placeholder
    if analysis.startswith("Request submitted: ") or (len(analysis) > 20 and not analysis.startswith("Error:")):
        return {
            "type": "weekly_review",
            "week_start": week_start,
            "status": "queued",
            "request_id": analysis.replace("Request submitted: ", ""),
            "message": "Weekly review analysis queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    
    result = {
        "type": "weekly_review",
        "week_start": week_start,
        "analysis": analysis,
        "logs_analyzed": len(logs),
        "tasks_analyzed": len(tasks),
        "timestamp": datetime.now().isoformat()
    }
    
    return result


def analyze_energy_patterns(context: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze energy patterns from daily logs."""
    days = context.get("days", 7)
    
    logs = read_recent_logs(days)
    
    prompt = f"""Analyze energy patterns for {USER_NAME} over the last {days} days.

Daily Logs:
{json.dumps(logs, indent=2)}

Analyze:
1. **Energy Levels**: Identify high/low energy periods
2. **Patterns**: When are they most energized? (time of day, day of week, after certain activities)
3. **Activities Correlation**: What activities boost/drain energy?
4. **Recommendations**: How can they schedule high-energy activities better?
5. **Insights**: What surprising patterns do you notice?

Provide detailed analysis with specific examples from the logs."""
    
    system_prompt = f"You are an energy management analyst helping {USER_NAME} optimize their energy levels."
    
    analysis = _call_deep_ai_with_async(
        prompt, system_prompt, 2500, "energy_analysis",
        {"type": "energy_analysis", "days": days}
    )
    
    # If async, return placeholder
    if analysis.startswith("Request submitted: ") or (len(analysis) > 20 and not analysis.startswith("Error:")):
        return {
            "type": "energy_analysis",
            "days": days,
            "status": "queued",
            "request_id": analysis.replace("Request submitted: ", ""),
            "message": f"Energy analysis for {days} days queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    
    result = {
        "type": "energy_analysis",
        "days": days,
        "analysis": analysis,
        "logs_analyzed": len(logs),
        "timestamp": datetime.now().isoformat()
    }
    
    return result


def find_connections(context: Dict[str, Any]) -> Dict[str, Any]:
    """Find connections between tasks, projects, and zettels."""
    scope = context.get("scope", "all")
    
    tasks = find_task_files()
    
    # Read sample of tasks
    task_contents = []
    for task_file in tasks[:20]:  # Limit to 20 for analysis
        try:
            with open(task_file) as f:
                content = f.read()
                task_contents.append({
                    "file": str(task_file.relative_to(GTD_BASE_DIR)),
                    "content": content[:500]  # First 500 chars
                })
        except:
            pass
    
    prompt = f"""Analyze connections between {USER_NAME}'s tasks, projects, and work items.

Tasks Analyzed:
{json.dumps(task_contents, indent=2)}

Find:
1. **Thematic Connections**: Tasks that relate to the same theme/concept
2. **Sequential Connections**: Tasks that should be done in order
3. **Dependency Patterns**: Tasks that depend on others
4. **Project Groupings**: Tasks that should be grouped into projects
5. **Opportunities**: Areas where combining efforts could be more efficient
6. **Suggestions**: Concrete suggestions for reorganizing or grouping work

Scope: {scope}
Provide detailed analysis with specific examples."""
    
    system_prompt = f"You are a systems thinking analyst helping {USER_NAME} see connections in their work."
    
    analysis = _call_deep_ai_with_async(
        prompt, system_prompt, 2500, "connections",
        {"type": "connections", "scope": scope}
    )
    
    # If async, return placeholder
    if analysis.startswith("Request submitted: ") or (len(analysis) > 20 and not analysis.startswith("Error:")):
        return {
            "type": "connections",
            "scope": scope,
            "status": "queued",
            "request_id": analysis.replace("Request submitted: ", ""),
            "message": f"Connection analysis for {scope} queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    
    result = {
        "type": "connections",
        "scope": scope,
        "analysis": analysis,
        "tasks_analyzed": len(task_contents),
        "timestamp": datetime.now().isoformat()
    }
    
    return result


def generate_insights(context: Dict[str, Any]) -> Dict[str, Any]:
    """Generate insights from recent activity."""
    focus = context.get("focus", "general")
    
    logs = read_recent_logs(7)
    tasks = find_task_files()
    
    prompt = f"""Generate deep insights for {USER_NAME} from their recent activity.

Focus Area: {focus}

Recent Logs:
{chr(10).join([f"{log['date']}: {log['content'][:300]}..." for log in logs[:5]])}

Tasks: {len(tasks)} total

Generate insights about:
1. **Patterns**: What recurring patterns do you notice?
2. **Opportunities**: What opportunities for improvement?
3. **Strengths**: What are they doing well?
4. **Blind Spots**: What might they be missing?
5. **Recommendations**: Actionable recommendations

Be specific, reference actual data, and provide thoughtful analysis."""
    
    system_prompt = f"You are an insights analyst helping {USER_NAME} understand their work patterns and opportunities."
    
    # Generate insights with higher token limit for comprehensive analysis
    # Thinking models can produce very detailed responses, so we need more tokens
    insights = _call_deep_ai_with_async(
        prompt, system_prompt, 4000, "insights",
        {"type": "insights", "scope": focus}
    )
    
    # If async, return placeholder
    if insights.startswith("Request submitted: ") or (len(insights) > 20 and not insights.startswith("Error:")):
        return {
            "type": "insights",
            "scope": focus,
            "status": "queued",
            "request_id": insights.replace("Request submitted: ", ""),
            "message": f"Insights generation for {focus} queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    
    # Check if response was cut off (common indicators)
    if insights and len(insights) > 100:
        # Check for incomplete sentences at the end
        last_chars = insights[-50:].strip()
        # If it ends mid-sentence or mid-word, it might be truncated
        if not last_chars.endswith(('.', '!', '?', ')', ']', '}', '"', "'")) and not last_chars.endswith('\n'):
            # Try to detect if it's actually incomplete
            # Look for common cut-off patterns
            if any(pattern in last_chars.lower() for pattern in ['|', 'table', 'recommendation', '###', '---']):
                # Might be cut off, but we'll save what we have
                pass
    
    result = {
        "type": "insights",
        "focus": focus,
        "insights": insights,
        "logs_analyzed": len(logs),
        "tasks_analyzed": len(tasks),
        "timestamp": datetime.now().isoformat()
    }
    
    return result


def send_discord_notification_for_result(analysis_type: str, result: Dict[str, Any], result_file: Path) -> bool:
    """Send a Discord notification when deep analysis results are saved."""
    if not GTD_DISCORD_WEBHOOK_URL:
        return False
    
    try:
        import urllib.request
        from datetime import timezone
        
        # Determine analysis type display name
        type_names = {
            "weekly_review": "Weekly Review",
            "analyze_energy": "Energy Analysis",
            "find_connections": "Task Connections",
            "generate_insights": "Insights Generation",
            "morning_review": "Morning Check-In Analysis",
            "evening_review": "Evening Check-In Analysis"
        }
        type_display = type_names.get(analysis_type, analysis_type.replace("_", " ").title())
        
        # Extract key information from result
        if "error" in result:
            title = f"❌ {type_display} - Error"
            description = f"**Error:** {result.get('error', 'Unknown error')}\n\n"
            description += f"📁 **File:** `{result_file}`"
            color = 15158332  # Red
        else:
            title = f"✅ {type_display} - Complete"
            
            # Build description with key metrics
            description = f"**Analysis Type:** {type_display}\n"
            
            if "logs_analyzed" in result:
                description += f"**Logs Analyzed:** {result['logs_analyzed']}\n"
            if "tasks_analyzed" in result:
                description += f"**Tasks Analyzed:** {result['tasks_analyzed']}\n"
            if "days" in result:
                description += f"**Days Analyzed:** {result['days']}\n"
            
            # Add analysis preview for morning/evening reviews
            if analysis_type in ["morning_review", "evening_review"]:
                if "analysis" in result:
                    preview = result["analysis"][:500]
                    if len(result["analysis"]) > 500:
                        preview += "..."
                    description += f"\n**Preview:**\n{preview}\n"
            
            description += f"\n📁 **Result File:** `{result_file}`\n"
            
            # Add review location hint for check-in reviews
            if analysis_type in ["morning_review", "evening_review"]:
                description += f"💡 **Review:** gtd-wizard → 19) Morning/Evening Check-In → 3) Review Background Analysis Results\n"
            else:
                description += f"💡 **View:** `open {result_file}` or `cat {result_file}`\n"
            description += f"🔗 **Review:** Run `gtd-wizard` → AI Suggestions → Review recent analysis"
            
            # Add preview of analysis (first 500 chars if available)
            analysis_key = "analysis" if "analysis" in result else "insights"
            if analysis_key in result:
                preview = str(result[analysis_key])
                if len(preview) > 500:
                    preview = preview[:500] + "..."
                description += f"\n\n**Preview:**\n```\n{preview}\n```"
            
            color = 3066993  # Green
        
        # Build Discord embed payload
        payload = {
            "embeds": [{
                "title": title,
                "description": description,
                "color": color,
                "timestamp": datetime.now(timezone.utc).isoformat()
            }]
        }
        
        # Send to Discord
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            GTD_DISCORD_WEBHOOK_URL,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.status == 204
    except urllib.error.HTTPError as e:
        # Provide more detailed error information
        error_body = ""
        try:
            error_body = e.read().decode('utf-8')
        except:
            pass
        
        if e.code == 403:
            print(f"Discord notification failed (403 Forbidden): Webhook URL may be invalid, expired, or lacks permissions. Check your GTD_DISCORD_WEBHOOK_URL in config.")
        elif e.code == 404:
            print(f"Discord notification failed (404 Not Found): Webhook URL not found. It may have been deleted.")
        else:
            print(f"Discord notification failed (HTTP {e.code}): {error_body or str(e)}")
        return False
    except Exception as e:
        # Silently fail - don't break result saving if Discord fails
        print(f"Discord notification failed: {e}")
        return False


def send_local_notification_for_result(analysis_type: str, result: Dict[str, Any], result_file: Path) -> bool:
    """Send a local macOS/terminal notification when deep analysis results are saved."""
    try:
        import subprocess
        import os
        
        # Check if notifications are enabled
        notifications_enabled = os.getenv("GTD_NOTIFICATIONS", "true").lower() == "true"
        if not notifications_enabled:
            return False
        
        # Map analysis types to friendly names
        type_names = {
            "weekly_review": "Weekly Review",
            "analyze_energy": "Energy Analysis",
            "find_connections": "Connection Analysis",
            "generate_insights": "Insights"
        }
        
        friendly_name = type_names.get(analysis_type, analysis_type.replace("_", " ").title())
        
        # Build notification message
        if "error" in result:
            title = f"❌ {friendly_name} Failed"
            message = f"Error: {result.get('error', 'Unknown error')}"
        else:
            title = f"✅ {friendly_name} Complete"
            
            # Get a preview of the result
            preview = ""
            if "analysis" in result:
                preview = str(result["analysis"])
            elif "insights" in result:
                preview = str(result["insights"])
            elif "connections" in result:
                preview = str(result["connections"])
            
            if preview:
                # Truncate preview for notification
                if len(preview) > 100:
                    preview = preview[:97] + "..."
                message = preview
            else:
                message = f"Analysis complete. View results for details."
        
        # Try to use gtd-notify if available
        notify_cmd = os.path.expanduser("~/code/dotfiles/bin/gtd-notify")
        if not os.path.exists(notify_cmd):
            notify_cmd = os.path.expanduser("~/code/personal/dotfiles/bin/gtd-notify")
        
        if os.path.exists(notify_cmd):
            # Use gtd-notify command
            subprocess.run([
                notify_cmd,
                title,
                message,
                "View results",
                "Glass"
            ], timeout=5, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        else:
            # Fallback to osascript on macOS
            if sys.platform == "darwin":
                applescript = f'''
                display notification "{message}" with title "{title}" sound name "Glass"
                '''
                subprocess.run(
                    ["osascript", "-e", applescript],
                    timeout=5,
                    stderr=subprocess.DEVNULL,
                    stdout=subprocess.DEVNULL
                )
        
        return True
    except Exception as e:
        # Silently fail - don't break result saving if notification fails
        print(f"Local notification failed (non-critical): {e}")
        return False


def auto_scan_and_create_suggestions(result_file: Path, analysis_type: str):
    """Automatically scan a result file and create suggestions from it.
    
    Queues the suggestion extraction to the deep worker instead of processing synchronously.
    """
    try:
        # Import here to avoid circular dependencies
        import sys
        sys.path.insert(0, str(Path(__file__).parent))
        
        from gtd_mcp_server import queue_deep_analysis
        
        # Read the result file
        with open(result_file) as f:
            result_data = json.load(f)
        
        # Check if this result type should be scanned
        auto_scan_types = os.getenv("DEEP_ANALYSIS_AUTO_SCAN_TYPES", "connections,insights").split(",")
        if analysis_type not in [t.strip() for t in auto_scan_types]:
            return
        
        # Queue suggestion extraction to deep worker (using thinking model)
        # This ensures we use the deep model instead of the fast model
        cutoff = datetime.now() - timedelta(hours=1)
        if result_file.stat().st_mtime >= cutoff.timestamp():
            # Extract suggestions from this specific result
            analysis_content = result_data.get("analysis") or result_data.get("insights", "")
            if analysis_content and "error" not in result_data:
                context = {
                    "source_file": str(result_file),
                    "analysis_type": analysis_type,
                    "analysis_content": analysis_content[:8000],  # Limit for queue
                    "full_content_length": len(analysis_content)
                }
                
                # Queue to deep worker
                status = queue_deep_analysis("extract_suggestions", context)
                if "queued" in status:
                    print(f"✅ Queued suggestion extraction from {analysis_type} (using deep worker)")
    except Exception as e:
        # Silently fail - don't break result saving if auto-scan fails
        print(f"Auto-scan failed (non-critical): {e}")


def analyze_morning_review(context: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze morning check-in for insights and recommendations."""
    check_in_date = context.get("date", datetime.now().strftime("%Y-%m-%d"))
    scan_days = context.get("scan_days", 7)
    
    # Read today's log and recent logs for context
    today_log = read_daily_log(check_in_date)
    recent_logs = read_recent_logs(scan_days)
    
    prompt = f"""Analyze {USER_NAME}'s morning check-in for {check_in_date} and provide insights.

Today's Morning Check-In:
{today_log[:2000] if today_log else "No log found for today"}

Recent Context (last {scan_days} days):
{chr(10).join([f"{log['date']}: {log['content'][:400]}..." for log in recent_logs[:3]])}

Provide analysis and recommendations:
1. **Mood & Energy**: How are they starting their day? Any patterns?
2. **Priorities Assessment**: Are their priorities realistic and well-chosen?
3. **Potential Issues**: What blockers or challenges should they watch for?
4. **Productivity Tips**: Suggestions for making today more productive
5. **Encouragement**: Positive reinforcement based on their recent progress

Be supportive, practical, and specific. Reference their actual check-in content."""
    
    system_prompt = f"You are a morning coach helping {USER_NAME} start their day with intention and awareness."
    
    analysis = _call_deep_ai_with_async(
        prompt, system_prompt, 2500, "morning_review",
        {"type": "morning_review", "date": check_in_date}
    )
    
    # If async, return placeholder
    if analysis.startswith("Request submitted: ") or (len(analysis) > 20 and not analysis.startswith("Error:")):
        return {
            "type": "morning_review",
            "date": check_in_date,
            "status": "queued",
            "request_id": analysis.replace("Request submitted: ", ""),
            "message": "Morning review analysis queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    
    result = {
        "type": "morning_review",
        "date": check_in_date,
        "analysis": analysis,
        "log_content_length": len(today_log) if today_log else 0,
        "recent_logs_context": len(recent_logs),
        "timestamp": datetime.now().isoformat()
    }
    
    return result


def extract_suggestions_from_analysis_deep(context: Dict[str, Any]) -> Dict[str, Any]:
    """Extract actionable suggestions from analysis content using the deep thinking model.
    
    This is called by the deep analysis worker to process suggestion extraction jobs
    that were queued from scan_analysis_results_for_suggestions.
    """
    source_file_str = context.get("source_file", "")
    analysis_type = context.get("analysis_type", "unknown")
    analysis_content = context.get("analysis_content", "")
    full_content_length = context.get("full_content_length", len(analysis_content))
    
    if not analysis_content:
        return {
            "type": "extract_suggestions",
            "success": False,
            "error": "No analysis content provided",
            "timestamp": datetime.now().isoformat()
        }
    
    # If content was truncated, note it in the prompt
    content_note = ""
    if full_content_length > len(analysis_content):
        content_note = f"\n\nNote: Analysis content was truncated from {full_content_length} to {len(analysis_content)} characters for processing."
    
    # Build extraction prompt (similar to the one in gtd_mcp_server but optimized for deep model)
    if analysis_type == "weekly_review":
        extraction_guidance = """
Look especially for:
- Action items from "Next Week Priorities" sections
- Specific recommendations from "Suggestions" sections
- Improvement ideas from "Challenges & Blockers" sections
- Priority tasks mentioned in numbered lists (e.g., "1. Task Prioritization - Immediately!")
- Concrete actions from "Actionable Suggestions" sections
- Any bold or numbered action items

Even if the analysis is strategic/advice-oriented, extract the concrete actions mentioned."""
    else:
        extraction_guidance = """
Look for:
- Specific tasks mentioned (e.g., "Document cluster setup process", "Set up Kubernetes cluster")
- Project ideas (e.g., "Create a Kubernetes Development project", "Group related tasks into a project")
- Zettel/note ideas (e.g., "Create a note about Kubernetes architecture patterns", "Document the connection between tasks")
- MOC ideas (e.g., "Create a MOC for Kubernetes learning", "Organize notes into a Kubernetes MOC")
- Organizational improvements"""
    
    prompt = f"""You are analyzing a {analysis_type} analysis that was generated for a GTD (Getting Things Done) system.

Analysis Content:
{analysis_content}{content_note}

Your task: Extract SPECIFIC, ACTIONABLE suggestions that can become tasks, projects, zettels (atomic notes), or MOCs (Maps of Content).

{extraction_guidance}

For each suggestion, determine:
1. Item type: "task", "project", "zettel", or "moc"
2. A clear, actionable title (be specific - not "review findings")
3. A reason that references specific parts of the analysis
4. Suggested project/area/MOC (if applicable - e.g., "Kubernetes Development", "Career Development", "Kubernetes Learning MOC")
5. A confidence score (0.0-1.0)

IMPORTANT: 
- Extract actual actionable items from the analysis, even from strategic/advice sections
- Convert recommendations into actionable tasks (e.g., "Dedicate 30-60 minutes to prioritize" becomes "Prioritize next 3-5 tasks in GTD system")
- Reference specific findings, patterns, or recommendations from the analysis
- Make titles specific and actionable (e.g., "Create Kubernetes Development project" not "Review Kubernetes tasks")
- CRITICAL: Keep titles COMPLETE - DO NOT truncate titles even if they are long. Include the full actionable phrase.
- Remove any markdown formatting from titles (no **, *, `, #, etc.) but keep the full meaning
- Each title should be a complete, actionable task or project idea - include the full thought, not a fragment
- For weekly reviews: Look for numbered lists, bold action items, and "Next Week Priorities" sections

Return ONLY a JSON array in this exact format:
[
  {{
    "type": "task|project|zettel|moc",
    "title": "Specific actionable title",
    "reason": "Specific reason referencing the analysis findings",
    "suggested_project": "Project name or empty string",
    "suggested_area": "Area name or empty string",
    "suggested_moc": "MOC name or empty string",
    "confidence": 0.8
  }}
]

Determine the type based on:
- "task": Single actionable item that can be done
- "project": Multiple related tasks that should be grouped together
- "zettel": Atomic note/idea to capture knowledge
- "moc": Map of Content to organize multiple related notes

Return ONLY the JSON array, no other text."""
    
    system_prompt = f"You are a GTD (Getting Things Done) expert helping {USER_NAME} extract actionable suggestions from analysis results. You understand task management, project organization, and knowledge management systems."
    
    try:
        # Use deep model to extract suggestions
        response = call_deep_ai(prompt, system_prompt, max_tokens=4000)
        
        if response.startswith("Error:"):
            return {
                "type": "extract_suggestions",
                "success": False,
                "error": response,
                "timestamp": datetime.now().isoformat()
            }
        
        # Parse JSON response
        import re
        response_clean = response.strip()
        
        # Remove markdown code blocks
        if response_clean.startswith("```"):
            response_clean = re.sub(r'^```(?:json)?\s*\n', '', response_clean)
            response_clean = re.sub(r'\n```\s*$', '', response_clean)
        
        # Try to find JSON array in response
        json_match = re.search(r'\[[\s\S]*\]', response_clean)
        if json_match:
            try:
                suggestions_data = json.loads(json_match.group())
            except json.JSONDecodeError:
                # Try to fix common JSON issues
                json_str = json_match.group()
                json_str = re.sub(r',\s*}', '}', json_str)
                json_str = re.sub(r',\s*]', ']', json_str)
                suggestions_data = json.loads(json_str)
        else:
            suggestions_data = json.loads(response_clean)
        
        # Import suggestion saving functions
        import sys
        sys.path.insert(0, str(Path(__file__).parent))
        from gtd_mcp_server import save_suggestion, clean_suggestion_title, clean_suggestion_reason, is_valid_ai_suggestion
        
        # Convert to suggestion format and save
        created_suggestions = []
        for item in suggestions_data:
            if isinstance(item, dict) and "title" in item:
                title = clean_suggestion_title(item["title"])
                reason = clean_suggestion_reason(item.get("reason", f"Extracted from {analysis_type} analysis"))
                
                # Validate the suggestion
                if not is_valid_ai_suggestion(title, reason):
                    continue
                
                # Determine item type
                item_type = item.get("type", "task").lower()
                if item_type not in ["task", "project", "zettel", "moc"]:
                    item_type = "task"
                
                suggestion = {
                    "title": title,
                    "reason": reason,
                    "item_type": item_type,
                    "suggested_project": item.get("suggested_project", "").strip(),
                    "suggested_area": item.get("suggested_area", "").strip(),
                    "suggested_moc": item.get("suggested_moc", "").strip(),
                    "confidence": float(item.get("confidence", 0.7)),
                    "status": "pending",
                    "source": f"analysis_{analysis_type}",
                    "source_file": Path(source_file_str).name if source_file_str else "",
                    "analysis_type": analysis_type
                }
                
                suggestion_id = save_suggestion(suggestion)
                created_suggestions.append({
                    "id": suggestion_id,
                    "title": title,
                    "type": item_type
                })
        
        return {
            "type": "extract_suggestions",
            "success": True,
            "source_file": Path(source_file_str).name if source_file_str else "",
            "analysis_type": analysis_type,
            "suggestions_created": len(created_suggestions),
            "suggestions": created_suggestions,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        import traceback
        return {
            "type": "extract_suggestions",
            "success": False,
            "error": str(e),
            "traceback": traceback.format_exc(),
            "timestamp": datetime.now().isoformat()
        }


def analyze_evening_review(context: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze evening check-in for insights and reflections."""
    check_in_date = context.get("date", datetime.now().strftime("%Y-%m-%d"))
    scan_days = context.get("scan_days", 7)
    
    # Read today's log and recent logs for context
    today_log = read_daily_log(check_in_date)
    recent_logs = read_recent_logs(scan_days)
    
    prompt = f"""Analyze {USER_NAME}'s evening check-in for {check_in_date} and provide reflections.

Today's Evening Check-In:
{today_log[:2000] if today_log else "No log found for today"}

Recent Context (last {scan_days} days):
{chr(10).join([f"{log['date']}: {log['content'][:400]}..." for log in recent_logs[:3]])}

Provide analysis and insights:
1. **Accomplishments**: Celebrate what they achieved today
2. **Patterns**: What patterns do you notice in their reflections?
3. **Growth Areas**: What could be improved? (gentle feedback)
4. **Tomorrow Preparation**: Suggestions for making tomorrow better
5. **Positive Reinforcement**: Acknowledge their efforts and progress

Be supportive, reflective, and constructive. Reference their actual check-in content."""
    
    system_prompt = f"You are an evening reflection coach helping {USER_NAME} learn from their day and prepare for tomorrow."
    
    # Use async mode for background tasks (non-blocking)
    use_async = os.getenv("DEEP_ANALYSIS_USE_ASYNC", "true").lower() == "true"
    
    if use_async and ":31080" in DEEP_MODEL_URL:
        # Async mode: submit request and return request_id
        # Result will be saved via callback
        result_file = f"evening_review_{check_in_date}_{datetime.now().strftime('%H%M%S')}.json"
        
        def on_complete(result_str, error):
            if error:
                error_result = {
                    "type": "evening_review",
                    "date": check_in_date,
                    "error": error,
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / f"error_{result_file}"
                with open(result_path, 'w') as f:
                    json.dump(error_result, f, indent=2)
            else:
                result_data = json.loads(result_str)
                content = result_data['choices'][0]['message']['content']
                result = {
                    "type": "evening_review",
                    "date": check_in_date,
                    "analysis": content,
                    "log_content_length": len(today_log) if today_log else 0,
                    "recent_logs_context": len(recent_logs),
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / result_file
                with open(result_path, 'w') as f:
                    json.dump(result, f, indent=2)
                send_discord_notification_for_result("evening_review", result, result_path)
                send_local_notification_for_result("evening_review", result, result_path)
        
        request_id = call_deep_ai(prompt, system_prompt, max_tokens=2500, use_async=True, callback=on_complete, result_file=result_file)
        
        # Return placeholder result with request_id
        return {
            "type": "evening_review",
            "date": check_in_date,
            "status": "queued",
            "request_id": request_id.replace("Request submitted: ", ""),
            "message": "Analysis queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    else:
        # Blocking mode (original behavior)
        analysis = call_deep_ai(prompt, system_prompt, max_tokens=2500, use_async=False)
        
        result = {
            "type": "evening_review",
            "date": check_in_date,
            "analysis": analysis,
            "log_content_length": len(today_log) if today_log else 0,
            "recent_logs_context": len(recent_logs),
            "timestamp": datetime.now().isoformat()
        }
    
    return result


def analyze_browser_article(context: Dict[str, Any]) -> Dict[str, Any]:
    """Analyze an article from the browser extension."""
    title = context.get("title", "Untitled")
    url = context.get("url", "")
    text = context.get("text", "")
    description = context.get("description", "")
    
    prompt = f"""Analyze the following article and provide comprehensive insights:

Title: {title}
URL: {url}
Description: {description}

Content:
{text}

Provide a thorough analysis with:
1. Main themes and topics
2. Key insights or takeaways
3. Actionable items or next steps
4. Connections to productivity or GTD principles
5. Questions this raises
6. Potential tasks or projects that could emerge from this content

Format your response clearly with sections and be specific about actionable items."""
    
    system_prompt = """You are a thoughtful analyst that extracts insights and actionable information from articles. 
Focus on practical applications, connections to productivity systems, and identifying concrete next steps.
Be thorough but concise, and always highlight actionable items."""
    
    # Use async mode for background processing
    use_async = os.getenv("DEEP_ANALYSIS_USE_ASYNC", "true").lower() == "true"
    
    if use_async and ":31080" in DEEP_MODEL_URL:
        # Async mode: submit request and return request_id
        result_file = f"browser_article_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        def on_complete(result_str, error):
            if error:
                error_result = {
                    "type": "browser_article",
                    "title": title,
                    "url": url,
                    "error": error,
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / f"error_{result_file}"
                with open(result_path, 'w') as f:
                    json.dump(error_result, f, indent=2)
            else:
                result_data = json.loads(result_str)
                content = result_data['choices'][0]['message']['content']
                result = {
                    "type": "browser_article",
                    "title": title,
                    "url": url,
                    "description": description,
                    "analysis": content,
                    "timestamp": datetime.now().isoformat()
                }
                result_path = RESULT_DIR / result_file
                with open(result_path, 'w') as f:
                    json.dump(result, f, indent=2)
                send_discord_notification_for_result("browser_article", result, result_path)
                send_local_notification_for_result("browser_article", result, result_path)
        
        request_id = call_deep_ai(prompt, system_prompt, max_tokens=3000, use_async=True, callback=on_complete, result_file=result_file)
        
        return {
            "type": "browser_article",
            "title": title,
            "url": url,
            "status": "queued",
            "request_id": request_id.replace("Request submitted: ", ""),
            "message": "Article analysis queued for background processing",
            "timestamp": datetime.now().isoformat()
        }
    else:
        # Blocking mode
        analysis = call_deep_ai(prompt, system_prompt, max_tokens=3000, use_async=False)
        
        result = {
            "type": "browser_article",
            "title": title,
            "url": url,
            "description": description,
            "analysis": analysis,
            "timestamp": datetime.now().isoformat()
        }
        
        # Save result
        result_file = f"browser_article_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        result_path = RESULT_DIR / result_file
        with open(result_path, 'w') as f:
            json.dump(result, f, indent=2)
        send_discord_notification_for_result("browser_article", result, result_path)
        send_local_notification_for_result("browser_article", result, result_path)
        
        return result


def process_analysis_request(message: Dict[str, Any]) -> Dict[str, Any]:
    """Process a single analysis request."""
    analysis_type = message.get("type")
    context = message.get("context", {})
    
    try:
        if analysis_type == "weekly_review":
            result = analyze_weekly_review(context)
        elif analysis_type == "analyze_energy":
            result = analyze_energy_patterns(context)
        elif analysis_type == "find_connections":
            result = find_connections(context)
        elif analysis_type == "generate_insights":
            result = generate_insights(context)
        elif analysis_type == "morning_review":
            result = analyze_morning_review(context)
        elif analysis_type == "evening_review":
            result = analyze_evening_review(context)
        elif analysis_type == "extract_suggestions":
            result = extract_suggestions_from_analysis_deep(context)
        elif analysis_type == "browser_article":
            result = analyze_browser_article(context)
        else:
            result = {
                "error": f"Unknown analysis type: {analysis_type}",
                "timestamp": datetime.now().isoformat()
            }
        
        # Save result (for extract_suggestions, we save a summary, not the full result)
        if analysis_type == "extract_suggestions":
            # For suggestion extraction, just log the result
            if result.get("success"):
                print(f"✅ Extracted {result.get('suggestions_created', 0)} suggestion(s) from {result.get('source_file', 'unknown')}")
            else:
                print(f"⚠️  Suggestion extraction failed: {result.get('error', 'Unknown error')}")
            # Don't save result file or send notifications for suggestion extraction
            # (it's a background task that creates suggestions, not a main analysis result)
        elif analysis_type == "browser_article" and result.get("status") == "queued":
            # Browser article analysis handles its own saving in async callback
            # Just log that it was queued
            print(f"✅ Browser article analysis queued: {result.get('title', 'Untitled')}")
        else:
            # Save result for other analysis types
            # (browser_article in blocking mode will be saved by analyze_browser_article)
            if analysis_type != "browser_article" or result.get("status") != "queued":
                result_file = RESULT_DIR / f"{analysis_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
                with open(result_file, 'w') as f:
                    json.dump(result, f, indent=2)
                
                # Send Discord notification
                send_discord_notification_for_result(analysis_type, result, result_file)
                
                # Send macOS/local notification
                send_local_notification_for_result(analysis_type, result, result_file)
            
            # Optionally auto-scan and create suggestions
            auto_scan_enabled = os.getenv("DEEP_ANALYSIS_AUTO_SCAN_SUGGESTIONS", "false").lower() == "true"
            if auto_scan_enabled:
                try:
                    auto_scan_and_create_suggestions(result_file, analysis_type)
                except Exception as e:
                    print(f"Auto-scan failed (non-critical): {e}")
        
        return result
    
    except Exception as e:
        error_result = {
            "error": str(e),
            "type": analysis_type,
            "timestamp": datetime.now().isoformat()
        }
        error_file = RESULT_DIR / f"error_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(error_file, 'w') as f:
            json.dump(error_result, f, indent=2)
        return error_result


def process_rabbitmq_queue():
    """Process messages from RabbitMQ queue with automatic reconnection."""
    if not RABBITMQ_AVAILABLE:
        print("RabbitMQ not available. Install with: pip install pika")
        return
    
    max_retries = 5
    retry_delay = 15  # seconds between reconnection attempts (increased to avoid rate limiting)
    
    retry_count = 0
    while retry_count < max_retries:
        try:
            # Add connection timeout to avoid hanging
            params = pika.URLParameters(RABBITMQ_URL)
            params.connection_attempts = 3
            params.retry_delay = 2
            params.socket_timeout = 10  # Increased from 5 to 10 seconds
            # Add heartbeat to keep connection alive during long operations
            # Deep analysis can take 5-10 minutes, so use longer heartbeat
            try:
                params.heartbeat = 900  # 15 minutes - long enough for deep analysis
                params.blocked_connection_timeout = 900  # 15 minutes
            except:
                # If heartbeat setting fails, continue without it
                pass
            
            print(f"Connecting to RabbitMQ... (attempt {retry_count + 1}/{max_retries})")
            sys.stdout.flush()
            try:
                connection = pika.BlockingConnection(params)
            except Exception as conn_ex:
                # Log detailed error information
                error_type = type(conn_ex).__name__
                error_msg = str(conn_ex) if conn_ex else "Unknown error"
                print(f"⚠️  Connection exception: {error_type}: {error_msg}", file=sys.stderr)
                import traceback
                traceback.print_exc(file=sys.stderr)
                raise  # Re-raise to be caught by outer handler
            channel = connection.channel()
            channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
            
            print(f"✅ Connected to RabbitMQ at {datetime.now()}")
            sys.stdout.flush()
            retry_count = 0  # Reset retry count on successful connection
            
            # Flag to track connection errors from callbacks
            connection_error_occurred = False
            
            # Add connection error callback to detect connection loss
            def on_connection_error(connection, error):
                nonlocal connection_error_occurred
                print(f"⚠️  Connection error callback triggered: {error}")
                connection_error_occurred = True
                try:
                    if channel and not channel.is_closed:
                        channel.stop_consuming()
                except:
                    pass
            
            # Note: BlockingConnection doesn't support on_close_callbacks directly
            # We'll rely on exception handling and connection state checks
            
            def callback(ch, method, properties, body):
                nonlocal connection_error_occurred
                
                try:
                    # Check connection state before processing
                    if connection.is_closed:
                        print("⚠️  Connection is closed, skipping message")
                        connection_error_occurred = True
                        return
                    
                    # Check if body is empty
                    if not body:
                        print(f"Error: Received empty message body")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    # Decode and parse JSON
                    try:
                        body_str = body.decode('utf-8')
                    except UnicodeDecodeError as e:
                        print(f"Error: Cannot decode message body: {e}")
                        print(f"Body (first 100 bytes): {body[:100]}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    # Check if body is empty after decoding
                    if not body_str.strip():
                        print(f"Error: Message body is empty after decoding")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    try:
                        message = json.loads(body_str)
                    except json.JSONDecodeError as e:
                        print(f"Error: Invalid JSON in message: {e}")
                        print(f"Message body (first 200 chars): {body_str[:200]}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    # Validate message structure
                    if not isinstance(message, dict):
                        print(f"Error: Message is not a dictionary: {type(message)}")
                        print(f"Message: {message}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    print(f"📥 Processing: {message.get('type', 'unknown')} at {datetime.now()}")
                    try:
                        result = process_analysis_request(message)
                        print(f"✅ Completed: {message.get('type', 'unknown')}")
                    except Exception as proc_err:
                        print(f"❌ Error in process_analysis_request: {proc_err}")
                        import traceback
                        traceback.print_exc()
                        # Re-raise to be caught by outer exception handler
                        raise
                    
                    # Try to ack - catch connection errors
                    try:
                        ch.basic_ack(delivery_tag=method.delivery_tag)
                    except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, BrokenPipeError) as conn_err:
                        print(f"⚠️  Connection lost while acknowledging message: {conn_err}")
                        connection_error_occurred = True
                        # Stop consuming to trigger reconnection
                        try:
                            ch.stop_consuming()
                        except:
                            pass
                        return
                        
                except KeyboardInterrupt:
                    print("\n⚠️  Interrupted during message processing")
                    connection_error_occurred = True
                    try:
                        ch.stop_consuming()
                    except:
                        pass
                    return
                except Exception as e:
                    print(f"❌ Error processing message: {e}")
                    import traceback
                    print("Full traceback:")
                    traceback.print_exc()
                    # Try to nack - catch connection errors
                    try:
                        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                    except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, BrokenPipeError) as conn_err:
                        print(f"⚠️  Connection lost while nacking message: {conn_err}")
                        connection_error_occurred = True
                        # Stop consuming to trigger reconnection
                        try:
                            ch.stop_consuming()
                        except:
                            pass
                        return
                    # Don't re-raise - continue processing other messages
            
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
            
            print(f"✅ Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
            sys.stdout.flush()
            try:
                # Start consuming - this will block until connection is lost or stopped
                # Note: pika may detect connection loss internally and return normally
                # We check connection state after consuming stops
                channel.start_consuming()
            except (pika.exceptions.AMQPConnectionError, pika.exceptions.StreamLostError, OSError, BrokenPipeError) as e:
                # Connection lost - this is expected and will trigger reconnection
                print(f"\n⚠️  Connection lost detected: {e}")
                connection_error_occurred = True
            except Exception as e:
                # Other exceptions - check if it's connection-related
                error_str = str(e).lower()
                if any(keyword in error_str for keyword in ['connection', 'stream', 'broken pipe', 'socket']):
                    print(f"\n⚠️  Connection error detected: {e}")
                    connection_error_occurred = True
                else:
                    # Re-raise unexpected exceptions
                    raise
            except KeyboardInterrupt:
                print("\nStopping worker...")
                channel.stop_consuming()
                connection.close()
                break
            
            # After consuming stops, check if it was due to connection error
            # pika may detect broken pipe internally and return normally, so check connection state
            if connection_error_occurred:
                raise pika.exceptions.StreamLostError("Connection lost during message processing")
            elif connection.is_closed:
                print(f"\n⚠️  Connection closed detected after consuming stopped")
                raise pika.exceptions.StreamLostError("Connection closed during message processing")
                
        except (pika.exceptions.AMQPConnectionError, pika.exceptions.StreamLostError, OSError, ConnectionRefusedError, BrokenPipeError) as e:
            # Ensure old connection is closed before retrying
            try:
                if 'connection' in locals() and connection and not connection.is_closed:
                    connection.close()
            except:
                pass
            
            retry_count += 1
            error_msg = str(e) if e else "Unknown connection error"
            if retry_count < max_retries:
                print(f"\n⚠️  Failed to connect to RabbitMQ: {error_msg}")
                print(f"   Retrying in {retry_delay} seconds... (attempt {retry_count}/{max_retries})")
                sys.stdout.flush()
                time.sleep(retry_delay)
                continue
            else:
                print(f"\n❌ Failed to connect after {max_retries} attempts")
                print(f"   Last error: {error_msg}")
                print(f"   RabbitMQ URL: {RABBITMQ_URL}")
                print(f"   Queue: {RABBITMQ_QUEUE}")
                # Fall back to file queue instead of raising
                print(f"\n⚠️  Falling back to file queue...")
                process_file_queue()
                return


def process_file_queue():
    """Process messages from file-based queue (fallback). Runs continuously, checking for new messages."""
    import time
    
    # Ensure queue file exists (create if it doesn't)
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not QUEUE_FILE.exists():
        QUEUE_FILE.touch()
        print(f"✓ Created job queue file: {QUEUE_FILE}")
        print("  Purpose: Stores background analysis jobs (weekly reviews, energy analysis, insights)")
    else:
        print(f"✓ Queue file ready: {QUEUE_FILE}")
    
    print(f"Waiting for messages. To exit press CTRL+C")
    print("")
    
    # Keep processing in a loop
    while True:
        try:
            processed = []
            
            # Read and process messages
            if QUEUE_FILE.exists() and os.path.getsize(QUEUE_FILE) > 0:
                with open(QUEUE_FILE, 'r') as f:
                    lines = f.readlines()
                
                for line in lines:
                    if line.strip():
                        try:
                            message = json.loads(line)
                            print(f"Processing: {message.get('type')} at {datetime.now()}")
                            result = process_analysis_request(message)
                            print(f"Completed: {message.get('type')}")
                            processed.append(line)
                        except json.JSONDecodeError as e:
                            print(f"Error decoding message: {e}")
                            processed.append(line)  # Remove invalid messages
                        except Exception as e:
                            print(f"Error processing message: {e}")
                            # Don't remove failed messages - keep for retry
                
                # Remove processed messages
                if processed:
                    remaining = [l for l in lines if l not in processed]
                    
                    with open(QUEUE_FILE, 'w') as f:
                        f.writelines(remaining)
                    
                    print(f"Processed {len(processed)} message(s)")
                    print("")
            
            # Wait before checking again
            time.sleep(5)  # Check every 5 seconds
            
        except KeyboardInterrupt:
            print("\nStopping worker...")
            break
        except Exception as e:
            print(f"Error in file queue processing: {e}")
            time.sleep(10)  # Wait longer on error before retrying


if __name__ == "__main__":
    import sys
    import traceback
    
    # Add signal handlers to catch termination signals
    import signal
    
    def signal_handler(signum, frame):
        print(f"\n⚠️  Received signal {signum}, shutting down gracefully...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    # Wrap everything in a try-except to catch any unhandled exceptions
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "file":
            # Process file queue
            process_file_queue()
        else:
            # Try RabbitMQ, fallback to file
            if RABBITMQ_AVAILABLE:
                try:
                    process_rabbitmq_queue()
                except KeyboardInterrupt:
                    print("\n⚠️  Interrupted by user")
                    sys.exit(0)
                except Exception as e:
                    print(f"\n❌ RabbitMQ error: {e}")
                    print("Full traceback:")
                    traceback.print_exc()
                    print("\nFalling back to file queue...")
                    try:
                        process_file_queue()
                    except Exception as file_e:
                        print(f"\n❌ File queue also failed: {file_e}")
                        traceback.print_exc()
                        sys.exit(1)
            else:
                process_file_queue()
    except Exception as e:
        print(f"\n❌ Fatal error in worker: {e}")
        print("Full traceback:")
        traceback.print_exc()
        sys.exit(1)

