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
except (ImportError, Exception):
    # Fallback: read config manually
    GTD_CONFIG = {}
    config_paths = [
        Path.home() / ".gtd_config",
        Path.home() / ".daily_log_config",
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
                        if key == "LM_STUDIO_URL":
                            GTD_CONFIG["url"] = value
            break

DEEP_MODEL_URL = os.getenv("GTD_DEEP_MODEL_URL", GTD_CONFIG.get("url", "http://localhost:1234/v1/chat/completions"))
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME", os.getenv("GTD_DEEP_MODEL", "gpt-oss-20b"))
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


def call_deep_ai(prompt: str, system_prompt: str = None, max_tokens: int = 2000) -> str:
    """Call the deep AI model (GPT-OSS 20b) for comprehensive analysis."""
    import urllib.request
    
    if system_prompt is None:
        system_prompt = f"You are {USER_NAME}'s deep thinking GTD analyst. You provide comprehensive, thoughtful analysis."
    
    payload = {
        "model": DEEP_MODEL_NAME,
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
    
    timeout = 120  # Longer timeout for deep analysis
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                return f"Error: {result['error'].get('message', 'Unknown error')}"
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            return "No response from AI"
    except Exception as e:
        return f"Error calling deep AI: {e}"


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
    
    insights = call_deep_ai(prompt, system_prompt, max_tokens=2500)
    
    result = {
        "type": "insights",
        "focus": focus,
        "insights": insights,
        "logs_analyzed": len(logs),
        "tasks_analyzed": len(tasks),
        "timestamp": datetime.now().isoformat()
    }
    
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
        else:
            result = {
                "error": f"Unknown analysis type: {analysis_type}",
                "timestamp": datetime.now().isoformat()
            }
        
        # Save result
        result_file = RESULT_DIR / f"{analysis_type}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(result_file, 'w') as f:
            json.dump(result, f, indent=2)
        
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
    if not QUEUE_FILE.exists():
        print(f"Queue file not found: {QUEUE_FILE}")
        return
    
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

