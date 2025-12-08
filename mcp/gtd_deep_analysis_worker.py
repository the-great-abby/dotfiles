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
                        # Remove variable expansion syntax like ${VAR:-default}
                        if value.startswith("${") and ":-" in value:
                            value = value.split(":-", 1)[1].rstrip("}")
                    if key == "LM_STUDIO_URL" and "url" not in GTD_CONFIG:
                            GTD_CONFIG["url"] = value
                    elif key == "GTD_DEEP_MODEL_NAME" and "deep_model_name" not in GTD_CONFIG:
                            GTD_CONFIG["deep_model_name"] = value
                    elif key == "DEEP_MODEL_TIMEOUT" or key == "LM_STUDIO_TIMEOUT":
                        # Always read timeout, override if already set
                        try:
                            GTD_CONFIG["deep_model_timeout"] = int(value)
                        except ValueError:
                            pass
                    elif key == "TIMEOUT" and "deep_model_timeout" not in GTD_CONFIG:
                        # Only use TIMEOUT if DEEP_MODEL_TIMEOUT wasn't found
                            try:
                                GTD_CONFIG["deep_model_timeout"] = int(value)
                            except ValueError:
                                pass
            # Don't break - read from all config files, later ones override earlier ones

DEEP_MODEL_URL = os.getenv("GTD_DEEP_MODEL_URL", GTD_CONFIG.get("url", "http://localhost:1234/v1/chat/completions"))
# Get model name from env var, then config, then default
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME") or os.getenv("GTD_DEEP_MODEL") or GTD_CONFIG.get("deep_model_name") or "gpt-oss-20b"

# Debug: Print config values (remove in production)
if os.getenv("GTD_DEBUG"):
    print(f"DEBUG: GTD_CONFIG keys: {list(GTD_CONFIG.keys())}", file=sys.stderr)
    print(f"DEBUG: deep_model_timeout from config: {GTD_CONFIG.get('deep_model_timeout')}", file=sys.stderr)
    print(f"DEBUG: DEEP_MODEL_TIMEOUT from env: {os.getenv('DEEP_MODEL_TIMEOUT')}", file=sys.stderr)
RABBITMQ_URL = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
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


def call_deep_ai(prompt: str, system_prompt: str = None, max_tokens: int = 2000) -> str:
    """Call the deep AI model (GPT-OSS 20b) for comprehensive analysis."""
    import urllib.request
    import urllib.error
    
    if system_prompt is None:
        system_prompt = f"You are {USER_NAME}'s deep thinking GTD analyst. You provide comprehensive, thoughtful analysis."
    
    # Check if model URL is accessible and find matching model
    actual_model_name = DEEP_MODEL_NAME
    available_models = []
    try:
        test_req = urllib.request.Request(f"{DEEP_MODEL_URL.rsplit('/v1', 1)[0]}/v1/models", headers={'Content-Type': 'application/json'})
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
    except Exception as e:
        return f"Error: Cannot connect to LM Studio at {DEEP_MODEL_URL}. Make sure LM Studio is running and a model is loaded. Error: {e}"
    
    payload = {
        "model": actual_model_name,
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
        headers={'Content-Type': 'application/json'}
    )
    
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
            timeout_source = "config"
        except (ValueError, TypeError):
            pass
    elif GTD_CONFIG.get("timeout"):
        try:
            base_timeout = int(GTD_CONFIG.get("timeout"))
            timeout_source = "config (timeout key)"
        except (ValueError, TypeError):
            pass
    
    # Thinking models get extra time (they do internal reasoning)
    # But don't double if timeout is already high (config should account for thinking models)
    if is_thinking_model and base_timeout < 300:
        # Only double if timeout is still low (user hasn't configured for thinking models)
        timeout = base_timeout * 2
    else:
        # Use configured timeout as-is (user has already accounted for thinking models)
        timeout = base_timeout
    
    # Debug: Log timeout being used (can be removed later)
    import logging
    logging.debug(f"Using timeout: {timeout}s (base: {base_timeout}s, source: {timeout_source}, thinking_model: {is_thinking_model})")
    
    # Try the primary model first
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                error_type = result['error'].get('type', 'unknown')
                # Check if it's a resource/loading error - try fallback models
                if 'insufficient system resources' in error_msg.lower() or 'model loading' in error_msg.lower():
                    return _try_fallback_models(prompt, system_prompt, max_tokens, available_models, actual_model_name, error_msg)
                return f"Error from AI: [{error_type}] {error_msg}"
            if 'choices' in result and len(result['choices']) > 0:
                content = result['choices'][0]['message']['content']
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
            # Check if it's a resource/loading error - try fallback models
            if 'insufficient system resources' in error_msg.lower() or 'model loading' in error_msg.lower() or e.code == 400:
                return _try_fallback_models(prompt, system_prompt, max_tokens, available_models, actual_model_name, error_msg)
        except:
            error_msg = error_body or str(e)
        return f"Error calling deep AI (HTTP {e.code}): {error_msg}. Model: {actual_model_name}, URL: {DEEP_MODEL_URL}"
    except urllib.error.URLError as e:
        # Check if it's a timeout error
        if "timed out" in str(e).lower() or "timeout" in str(e).lower():
            timeout_msg = f"timed out after {timeout}s"
            suggestion = ""
            if is_thinking_model:
                suggestion = f"\n\nThinking models like '{actual_model_name}' may need more time for their reasoning phase. Consider:\n"
                suggestion += f"1. Increase timeout in config: Add 'DEEP_MODEL_TIMEOUT=\"300\"' to your .gtd_config_ai\n"
                suggestion += f"2. Check if model is loaded and responding: curl {DEEP_MODEL_URL.rsplit('/v1', 1)[0]}/v1/models\n"
                suggestion += f"3. Try a smaller model or reduce max_tokens in the request"
            else:
                suggestion = f"\n\nConsider:\n"
                suggestion += f"1. Increase timeout: Add 'DEEP_MODEL_TIMEOUT=\"180\"' to your .gtd_config_ai\n"
                suggestion += f"2. Check if model is loaded in LM Studio\n"
                suggestion += f"3. The model may be processing - try again later"
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
                headers={'Content-Type': 'application/json'}
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
    log_file = DAILY_LOG_DIR / f"{date}.txt"
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
    
    analysis = call_deep_ai(prompt, system_prompt, max_tokens=3000)
    
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
    
    analysis = call_deep_ai(prompt, system_prompt, max_tokens=2500)
    
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
    
    analysis = call_deep_ai(prompt, system_prompt, max_tokens=2500)
    
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
    insights = call_deep_ai(prompt, system_prompt, max_tokens=4000)
    
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
            "generate_insights": "Insights Generation"
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
            
            description += f"\n📁 **Result File:** `{result_file}`\n"
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
        else:
            result = {
                "error": f"Unknown analysis type: {analysis_type}",
                "timestamp": datetime.now().isoformat()
            }
        
        # Save result
        result_file = RESULT_DIR / f"{analysis_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2)
        
        # Send Discord notification
        send_discord_notification_for_result(analysis_type, result, result_file)
        
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
    """Process messages from RabbitMQ queue."""
    if not RABBITMQ_AVAILABLE:
        print("RabbitMQ not available. Install with: pip install pika")
        return
    
    connection = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
    channel = connection.channel()
    channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
    
    def callback(ch, method, properties, body):
        try:
            message = json.loads(body.decode('utf-8'))
            print(f"Processing: {message.get('type')} at {datetime.now()}")
            result = process_analysis_request(message)
            print(f"Completed: {message.get('type')}")
            ch.basic_ack(delivery_tag=method.delivery_tag)
        except Exception as e:
            print(f"Error processing message: {e}")
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
    
    channel.basic_qos(prefetch_count=1)
    channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
    
    print(f"Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
    try:
        channel.start_consuming()
    except KeyboardInterrupt:
        channel.stop_consuming()
        connection.close()


def process_file_queue():
    """Process messages from file-based queue (fallback)."""
    # Ensure queue file exists (create if it doesn't)
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not QUEUE_FILE.exists():
        QUEUE_FILE.touch()
        print(f"✓ Created job queue file: {QUEUE_FILE}")
        print("  Purpose: Stores background analysis jobs (weekly reviews, energy analysis, insights)")
    else:
        print(f"✓ Queue file ready: {QUEUE_FILE}")
    
    processed = []
    with open(QUEUE_FILE, 'r') as f:
        for line in f:
            if line.strip():
                try:
                    message = json.loads(line)
                    print(f"Processing: {message.get('type')} at {datetime.now()}")
                    result = process_analysis_request(message)
                    print(f"Completed: {message.get('type')}")
                    processed.append(line)
                except Exception as e:
                    print(f"Error processing message: {e}")
    
    # Remove processed messages
    if processed:
        with open(QUEUE_FILE, 'r') as f:
            lines = f.readlines()
        
        remaining = [l for l in lines if l not in processed]
        
        with open(QUEUE_FILE, 'w') as f:
            f.writelines(remaining)
        
        print(f"Processed {len(processed)} messages")


if __name__ == "__main__":
    import sys
    
    if len(sys.argv) > 1 and sys.argv[1] == "file":
        # Process file queue
        process_file_queue()
    else:
        # Try RabbitMQ, fallback to file
        if RABBITMQ_AVAILABLE:
            try:
                process_rabbitmq_queue()
            except Exception as e:
                print(f"RabbitMQ error: {e}")
                print("Falling back to file queue...")
                process_file_queue()
        else:
            process_file_queue()

