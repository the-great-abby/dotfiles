#!/usr/bin/env python3
"""
GTD Task Organization Worker

Background worker that processes task organization requests from the queue.
Analyzes tasks and suggests which projects they belong to, with caching support.
"""

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional, List

try:
    import pika
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))

# Import MCP server functions for caching and AI calls
try:
    from gtd_mcp_server import (
        get_cached_task_analysis,
        cache_task_analysis,
        call_fast_ai,
        GTD_BASE_DIR,
        RABBITMQ_URL,
    )
except ImportError:
    print("Error: Could not import from gtd_mcp_server", file=sys.stderr)
    sys.exit(1)

# Import persona helper for config
try:
    from gtd_persona_helper import read_config
except ImportError:
    def read_config():
        return {}

GTD_CONFIG = read_config()
USER_NAME = os.getenv("GTD_USER_NAME", "Abby")

# RabbitMQ configuration
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
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_TASK_ORG_QUEUE", "gtd_task_organization")

# Fallback queue file
QUEUE_FILE = GTD_BASE_DIR / "task_organization_queue.jsonl"

# Results directory
RESULTS_DIR = GTD_BASE_DIR / "task_organization_results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Status file
STATUS_FILE = GTD_BASE_DIR / ".bulk_organize_status.txt"


def find_task_file(task_id: str) -> Optional[Path]:
    """Find task file by ID."""
    tasks_path = GTD_BASE_DIR / "tasks"
    projects_path = GTD_BASE_DIR / "1-projects"
    
    # Check tasks directory
    task_file = tasks_path / f"{task_id}.md"
    if task_file.exists():
        return task_file
    
    # Search in project directories
    if projects_path.exists():
        for project_dir in projects_path.iterdir():
            if project_dir.is_dir():
                task_file = project_dir / f"{task_id}.md"
                if task_file.exists():
                    return task_file
    
    return None


def get_task_content(task_file: Path) -> Dict[str, str]:
    """Extract task name and content from task file."""
    try:
        with open(task_file, 'r') as f:
            content = f.read()
        
        # Extract task name (first # heading)
        task_name = ""
        for line in content.split('\n'):
            if line.startswith('# '):
                task_name = line[2:].strip()
                # Remove flags from title
                import re
                task_name = re.sub(r'\s*--(context|priority|energy|project|repository|repo|recurring|frequency)(=[^\s]*)?\s*', ' ', task_name)
                task_name = re.sub(r'\s+', ' ', task_name).strip()
                break
        
        if not task_name:
            task_name = task_file.stem
        
        return {
            "name": task_name,
            "content": content
        }
    except Exception as e:
        print(f"Error reading task file {task_file}: {e}", file=sys.stderr)
        return {"name": task_file.stem, "content": ""}


def get_projects_list() -> List[str]:
    """Get list of existing project names."""
    projects = []
    projects_path = GTD_BASE_DIR / "1-projects"
    
    if projects_path.exists():
        for project_dir in projects_path.iterdir():
            if project_dir.is_dir():
                projects.append(project_dir.name)
    
    return projects


def process_project_suggestion_request(message: Dict[str, Any]) -> bool:
    """Process a request to suggest new projects from unassigned tasks.
    
    Groups related tasks and suggests creating projects for them.
    
    Returns True if successful, False otherwise.
    """
    try:
        task_ids = message.get("task_ids", [])
        
        if not task_ids:
            print("No task IDs provided", file=sys.stderr)
            return False
        
        print(f"Analyzing {len(task_ids)} unassigned tasks for project suggestions...")
        
        # Create results file
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        results_file = RESULTS_DIR / f"project_suggestions_{timestamp}.json"
        
        # Get task data
        tasks_data = []
        for task_id in task_ids:
            task_file = find_task_file(task_id)
            if task_file:
                task_info = get_task_content(task_file)
                tasks_data.append({
                    "id": task_id,
                    "name": task_info["name"],
                    "content": task_info["content"][:1000]  # Limit content
                })
        
        if not tasks_data:
            print("No valid tasks found", file=sys.stderr)
            return False
        
        # Get existing projects
        existing_projects = get_projects_list()
        
        # Group related tasks using AI
        tasks_text = "\n".join([f"- {t['name']}: {t['content'][:200]}" for t in tasks_data[:30]])  # Limit for prompt
        
        prompt = f"""Analyze these unassigned tasks and group them by topic/theme. Tasks that are related should be grouped together.

Tasks:
{tasks_text}

Return a JSON array where each group is an object with:
- "task_names": array of task names that belong together
- "theme": brief description of what these tasks have in common
- "suggested_project_name": a short project name (kebab-case, like "work-efficiency")
- "suggested_outcome": what the successful completion of this project achieves

Existing projects to avoid duplicating: {', '.join(existing_projects[:10]) if existing_projects else 'none'}

Only group tasks that are clearly related. Return ONLY the JSON array."""

        system_prompt = "You are a GTD organization assistant. Group related tasks and suggest project names."
        
        try:
            response = call_fast_ai(prompt, system_prompt)
            
            # Extract JSON from response
            import re
            json_match = re.search(r'\[.*?\]', response, re.DOTALL)
            if json_match:
                groups = json.loads(json_match.group())
                
                # Map task names to IDs
                name_to_id = {t['name'].lower(): t['id'] for t in tasks_data}
                
                result_groups = []
                for group in groups:
                    task_names = group.get('task_names', [])
                    task_ids_in_group = []
                    
                    # Match task names to IDs (fuzzy matching)
                    for task_name in task_names:
                        task_name_lower = task_name.lower()
                        for t in tasks_data:
                            if (task_name_lower in t['name'].lower() or 
                                t['name'].lower() in task_name_lower):
                                if t['id'] not in task_ids_in_group:
                                    task_ids_in_group.append(t['id'])
                                    break
                    
                    if task_ids_in_group:
                        suggested_name = group.get('suggested_project_name', '').strip().lower().replace(' ', '-')
                        suggested_name = re.sub(r'[^a-z0-9-]', '', suggested_name)
                        
                        result_groups.append({
                            'task_ids': task_ids_in_group,
                            'task_names': [t['name'] for t in tasks_data if t['id'] in task_ids_in_group],
                            'theme': group.get('theme', ''),
                            'suggested_project_name': suggested_name,
                            'suggested_outcome': group.get('suggested_outcome', ''),
                            'project_exists': suggested_name in existing_projects
                        })
                
                # Save results
                results = {
                    'groups': result_groups,
                    'analyzed_count': len(tasks_data),
                    'groups_found': len(result_groups),
                    'timestamp': datetime.now().isoformat()
                }
                
                with open(results_file, 'w') as f:
                    json.dump(results, f, indent=2)
                
                print(f"✓ Found {len(result_groups)} project suggestion(s)")
                print(f"Results saved to: {results_file}")
                
                return True
            else:
                print("Failed to parse AI response", file=sys.stderr)
                return False
                
        except Exception as e:
            print(f"Error during analysis: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc(file=sys.stderr)
            return False
            
    except Exception as e:
        print(f"Error processing project suggestion request: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return False


def suggest_project_for_task(task_id: str, task_file: Path, force_reanalyze: bool = False) -> Optional[str]:
    """Suggest which project a task belongs to, using cache if available."""
    # Check cache first (unless force_reanalyze is True)
    if not force_reanalyze:
        cached = get_cached_task_analysis(task_id)
        if cached:
            return cached
    
    # Get task content
    task_data = get_task_content(task_file)
    task_name = task_data["name"]
    task_content = task_data["content"]
    
    # Get projects list
    projects = get_projects_list()
    projects_list = ",".join(projects) if projects else "none"
    
    # Build prompt
    prompt = f"""Task: {task_name}

Task content:
{task_content[:1000]}  # Limit content length

Available projects: {projects_list}

Based on the task description, suggest which project this task belongs to. If it doesn't fit any existing project, suggest 'none' or a new project name.

Return ONLY the project name (or 'none'), nothing else."""
    
    system_prompt = f"You are a GTD organization assistant. Analyze tasks and suggest which project they belong to. Return only the project name, or 'none' if it doesn't fit any project."
    
    # Call AI
    try:
        response = call_fast_ai(prompt, system_prompt)
        
        # Clean up response
        suggested_project = response.strip().lower().replace(' ', '-')
        # Remove any non-alphanumeric except hyphens
        import re
        suggested_project = re.sub(r'[^a-z0-9-]', '', suggested_project)
        
        # Check if it matches an existing project
        if suggested_project and suggested_project != "none":
            for project in projects:
                if project == suggested_project:
                    # Cache the result
                    cache_task_analysis(task_id, suggested_project)
                    return suggested_project
        
        # Cache even if it's "none"
        if suggested_project:
            cache_task_analysis(task_id, suggested_project)
            return suggested_project
        
        return None
    except Exception as e:
        print(f"Error calling AI for task {task_id}: {e}", file=sys.stderr)
        return None


def process_task_organization_request(message: Dict[str, Any]) -> bool:
    """Process a task organization request.
    
    Supports two modes:
    - "bulk_organize": Analyze tasks and suggest projects for them
    - "suggest_projects": Group unassigned tasks and suggest new projects
    
    Returns True if successful, False otherwise.
    """
    try:
        request_type = message.get("request_type", "bulk_organize")
        
        # Handle project suggestion requests differently
        if request_type == "suggest_projects":
            return process_project_suggestion_request(message)
        
        # Default: bulk organization
        task_ids = message.get("task_ids", [])
        force_reanalyze = message.get("force_reanalyze", False)
        
        if not task_ids:
            print("No task IDs provided", file=sys.stderr)
            return False
        
        # Create results file
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        results_file = RESULTS_DIR / f"task_org_results_{timestamp}.json"
        status_file = GTD_BASE_DIR / f".bulk_organize_status_{timestamp}.txt"
        
        suggestions = []
        total = len(task_ids)
        
        # Update status
        with open(status_file, 'w') as f:
            f.write(f"Starting analysis of {total} tasks...\n")
            f.write("0\n")
        
        for idx, task_id in enumerate(task_ids, 1):
            # Update status
            with open(status_file, 'w') as f:
                f.write(f"[{idx}/{total}] Analyzing: {task_id}\n")
                f.write(f"{idx}\n")
            
            # Find task file
            task_file = find_task_file(task_id)
            if not task_file:
                print(f"Task file not found for {task_id}", file=sys.stderr)
                suggestions.append({
                    "task_id": task_id,
                    "task_name": task_id,
                    "suggested_project": "none",
                    "error": "Task file not found"
                })
                continue
            
            # Get task name
            task_data = get_task_content(task_file)
            task_name = task_data["name"]
            
            # Suggest project
            suggested_project = suggest_project_for_task(task_id, task_file, force_reanalyze)
            if not suggested_project:
                suggested_project = "none"
            
            suggestions.append({
                "task_id": task_id,
                "task_name": task_name,
                "suggested_project": suggested_project
            })
        
        # Save results
        results = {
            "total_tasks": total,
            "analyzed_at": datetime.now().isoformat(),
            "suggestions": suggestions
        }
        
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        # Also save in simple text format for compatibility
        text_results_file = GTD_BASE_DIR / f".bulk_organize_results_{timestamp}.txt"
        with open(text_results_file, 'w') as f:
            f.write(f"TOTAL:{total}\n")
            for suggestion in suggestions:
                f.write(f"{suggestion['task_id']}|{suggestion['task_name']}|{suggestion['suggested_project']}\n")
        
        # Mark as complete
        with open(status_file, 'w') as f:
            f.write(f"✓ Analysis complete! {total} tasks analyzed.\n")
            f.write(f"{total}\n")
        
        print(f"✓ Processed {total} tasks, results saved to {results_file}")
        return True
        
    except Exception as e:
        print(f"Error processing task organization request: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return False


def process_file_queue():
    """Process messages from file queue."""
    if not QUEUE_FILE.exists():
        return False
    
    # Read first line (oldest message)
    with open(QUEUE_FILE, 'r') as f:
        lines = f.readlines()
    
    if not lines:
        return False
    
    # Process first message
    try:
        message = json.loads(lines[0].strip())
        success = process_task_organization_request(message)
        
        if success:
            # Remove processed message
            with open(QUEUE_FILE, 'w') as f:
                f.writelines(lines[1:])
            return True
        else:
            # Move to end for retry
            with open(QUEUE_FILE, 'w') as f:
                f.writelines(lines[1:] + [lines[0]])
            return False
    except json.JSONDecodeError as e:
        # Invalid JSON, remove the line
        print(f"Invalid JSON in queue file: {e}", file=sys.stderr)
        with open(QUEUE_FILE, 'w') as f:
            f.writelines(lines[1:])
        return False


def process_rabbitmq_queue():
    """Process messages from RabbitMQ queue."""
    if not RABBITMQ_AVAILABLE:
        return False
    
    try:
        params = pika.URLParameters(RABBITMQ_URL)
        params.blocked_connection_timeout = 5
        connection = pika.BlockingConnection(params)
        channel = connection.channel()
        channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
        
        def callback(ch, method, properties, body):
            try:
                message = json.loads(body.decode('utf-8'))
                success = process_task_organization_request(message)
                
                if success:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                else:
                    # Reject and requeue
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
            except Exception as e:
                print(f"Error processing message: {e}", file=sys.stderr)
                # Reject and don't requeue on error
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        
        channel.basic_qos(prefetch_count=1)  # Process one message at a time
        channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
        
        print(f"✅ Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
        channel.start_consuming()
        
    except KeyboardInterrupt:
        print("\n⏹️  Stopping worker...")
        channel.stop_consuming()
        connection.close()
        return True
    except Exception as e:
        print(f"RabbitMQ error: {e}", file=sys.stderr)
        return False


def main():
    """Main worker loop."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Task Organization Worker")
    parser.add_argument("mode", choices=["rabbitmq", "file"], default="rabbitmq", nargs="?",
                       help="Queue mode: rabbitmq or file")
    args = parser.parse_args()
    
    if args.mode == "rabbitmq":
        if not RABBITMQ_AVAILABLE:
            print("⚠️  RabbitMQ not available (pika not installed), falling back to file queue", file=sys.stderr)
            args.mode = "file"
        else:
            process_rabbitmq_queue()
            return
    
    # File queue mode
    print("📁 Processing file queue...")
    while True:
        processed = process_file_queue()
        if not processed:
            # No messages, wait a bit
            time.sleep(5)
        else:
            # Processed a message, continue immediately
            pass


if __name__ == "__main__":
    main()

