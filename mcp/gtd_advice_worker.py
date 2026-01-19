#!/usr/bin/env python3
"""
GTD Advice Worker - Processes advice requests from RabbitMQ

Consumes messages from RabbitMQ queue and processes persona advice requests.
Uses the deep analysis worker's thinking model for comprehensive advice.
"""

import json
import sys
import os
import time
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, Any, Optional

# Add parent directories to path
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent
sys.path.insert(0, str(dotfiles_dir))

try:
    from zsh.functions.gtd_vector_db import read_database_config
    from zsh.functions.gtd_vectorization import search_similar
except ImportError:
    # Try alternative path
    sys.path.insert(0, str(dotfiles_dir / "zsh" / "functions"))
    from gtd_vector_db import read_database_config
    from gtd_vectorization import search_similar

# Import deep analysis worker's call_deep_ai function
try:
    from mcp.gtd_deep_analysis_worker import call_deep_ai
except ImportError:
    # Try alternative import path
    sys.path.insert(0, str(dotfiles_dir / "mcp"))
    from gtd_deep_analysis_worker import call_deep_ai

# Import persona definitions
try:
    from zsh.functions.gtd_persona_helper import PERSONAS, read_config as read_gtd_config
except ImportError:
    # Try alternative path
    sys.path.insert(0, str(dotfiles_dir / "zsh" / "functions"))
    from gtd_persona_helper import PERSONAS, read_config as read_gtd_config

# Check for pika (RabbitMQ client)
try:
    import pika
    import pika.exceptions
    PIKA_AVAILABLE = True
except ImportError:
    PIKA_AVAILABLE = False

# Read config
def get_rabbitmq_config():
    """Get RabbitMQ enabled status and URL.
    
    Returns:
        Tuple of (enabled: bool, url: str)
    """
    db_config = read_database_config()
    rabbitmq_enabled = db_config.get("rabbitmq_enabled", False)
    
    # Also check environment variable
    if os.getenv("GTD_RABBITMQ_ENABLED", "").lower() == "true":
        rabbitmq_enabled = True
    
    url = os.getenv("GTD_RABBITMQ_URL", db_config.get("rabbitmq_url", "amqp://localhost:5672"))
    
    # If URL already has credentials, use it as-is
    if "//" in url:
        url_parts = url.split("//", 1)
        if len(url_parts) == 2 and "@" in url_parts[1]:
            return (rabbitmq_enabled, url)  # Already has credentials
    
    # Otherwise, check for separate username/password
    username = os.getenv("RABBITMQ_USER") or os.getenv("GTD_RABBITMQ_USER") or db_config.get("rabbitmq_user", "guest")
    password = os.getenv("RABBITMQ_PASS") or os.getenv("GTD_RABBITMQ_PASS") or db_config.get("rabbitmq_pass", "")
    
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
    
    return (rabbitmq_enabled, url)

RABBITMQ_ENABLED, RABBITMQ_URL = get_rabbitmq_config()
RABBITMQ_AVAILABLE = PIKA_AVAILABLE and RABBITMQ_ENABLED
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_ADVICE_QUEUE", "gtd_advice")
QUEUE_FILE = Path.home() / "Documents" / "gtd" / "advice_queue.jsonl"
RESULTS_DIR = Path.home() / "Documents" / "gtd" / "advice_results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# Read GTD config for user name
GTD_CONFIG = read_gtd_config()
USER_NAME = GTD_CONFIG.get("name", os.getenv("GTD_USER_NAME", "User")).strip()


def get_persona_system_prompt(persona_key: str, mode: str) -> str:
    """Get system prompt for a persona.
    
    Args:
        persona_key: Persona identifier (e.g., "hank", "david", "random")
        mode: Request mode ("normal", "simple", "random", "all", "daily-log")
    
    Returns:
        System prompt string
    """
    if mode == "random":
        # For random mode, pick a random persona
        import random
        available_personas = [k for k in PERSONAS.keys() if k not in ["random", "all"]]
        persona_key = random.choice(available_personas)
    
    if persona_key in PERSONAS:
        persona_info = PERSONAS[persona_key]
        base_prompt = persona_info.get("system_prompt", "")
        
        # Add user name if available
        if USER_NAME and USER_NAME != "User":
            # Try to personalize the prompt
            if "{name}" in base_prompt or "{user}" in base_prompt:
                base_prompt = base_prompt.replace("{name}", USER_NAME).replace("{user}", USER_NAME)
            else:
                # Add user context at the beginning
                base_prompt = f"You are helping {USER_NAME}. {base_prompt}"
        
        return base_prompt
    else:
        # Default prompt for unknown personas
        return f"You are a helpful assistant providing advice to {USER_NAME if USER_NAME != 'User' else 'the user'}."


def process_tool_execution_request(message: Dict[str, Any]) -> bool:
    """
    Process a tool execution request from Ollama Controller.
    
    Args:
        message: Message dictionary with type="tool_execution", tool_calls, request_id
    
    Returns:
        True if successful, False otherwise
    """
    request_id = message.get("request_id", "unknown")
    tool_calls = message.get("tool_calls", [])
    
    if not tool_calls:
        print(f"Error: No tool calls in tool execution request {request_id}")
        return False
    
    print(f"Processing tool execution request: {request_id} ({len(tool_calls)} tool(s))")
    
    # Import tool registry
    functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
    if not functions_dir.exists():
        functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
    
    if not functions_dir.exists():
        print(f"Error: Tool registry not found at {functions_dir}")
        return False
    
    if str(functions_dir) not in sys.path:
        sys.path.insert(0, str(functions_dir))
    
    try:
        from gtd_tool_registry import execute_tool
    except ImportError as e:
        print(f"Error: Failed to import tool registry: {e}")
        return False
    
    # Execute each tool call
    tool_results = []
    for tool_call in tool_calls:
        function_info = tool_call.get("function", {})
        function_name = function_info.get("name", "")
        function_args = function_info.get("arguments", {})
        tool_call_id = tool_call.get("id", "")
        
        if not function_name:
            print(f"  ⚠️  Skipping tool call with no function name (id: {tool_call_id})")
            continue
        
        # Parse arguments if they're a string
        if isinstance(function_args, str):
            try:
                function_args = json.loads(function_args)
            except json.JSONDecodeError:
                function_args = {}
        
        # Execute the tool
        try:
            print(f"  🔧 Executing tool: {function_name}({json.dumps(function_args)})")
            tool_result = execute_tool(function_name, function_args)
            print(f"  ✅ Tool {function_name} executed successfully ({len(tool_result)} chars)")
            
            tool_results.append({
                "role": "tool",
                "tool_call_id": tool_call_id,
                "name": function_name,
                "content": tool_result
            })
        except Exception as e:
            error_msg = f"Error executing tool '{function_name}': {str(e)}"
            print(f"  ❌ {error_msg}")
            tool_results.append({
                "role": "tool",
                "tool_call_id": tool_call_id,
                "name": function_name,
                "content": error_msg
            })
    
    # Note: Tool execution results are typically sent back to Ollama Controller via callback URL
    # This function just executes them - the controller handles the response
    print(f"✅ Tool execution request {request_id} completed ({len(tool_results)} result(s))")
    return True


def process_panel_discussion_request(
    request_id: str,
    question: str,
    panel_size: int,
    manual_personas: Optional[str],
    thread_id: Optional[str],
    result_file: Path,
    answer_file: Path
) -> bool:
    """Process a panel discussion request.
    
    Args:
        request_id: Request identifier
        question: User's question
        panel_size: Number of personas for panel
        manual_personas: Comma-separated persona keys (optional)
        thread_id: Conversation thread ID (optional)
        result_file: Path to result JSON file
        answer_file: Path to answer text file
    
    Returns:
        True if successful, False otherwise
    """
    print(f"Processing panel discussion request: {request_id}")
    
    start_time = datetime.now()
    created_at = datetime.now(timezone.utc).isoformat()
    
    try:
        # Import panel discussion module
        functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
        if not functions_dir.exists():
            functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
        
        if not functions_dir.exists():
            error_msg = f"Error: Panel discussion module not found at {functions_dir}"
            print(error_msg)
            result_data = {
                "id": request_id,
                "status": "error",
                "persona": "panel",
                "question": question,
                "mode": "panel",
                "error": error_msg,
                "created_at": created_at,
                "completed_at": datetime.now().isoformat() + "Z",
                "duration_seconds": 0
            }
            with open(result_file, 'w') as f:
                json.dump(result_data, f, indent=2)
            return False
        
        if str(functions_dir) not in sys.path:
            sys.path.insert(0, str(functions_dir))
        
        from gtd_panel_discussion import run_panel_discussion_cli
        
        # Run panel discussion
        # Capture both stdout and stderr (progress messages go to stderr)
        import io
        from contextlib import redirect_stdout, redirect_stderr
        
        output_buffer = io.StringIO()
        error_buffer = io.StringIO()
        
        with redirect_stdout(output_buffer), redirect_stderr(error_buffer):
            run_panel_discussion_cli(question, panel_size, manual_personas)
        
        stdout_output = output_buffer.getvalue()
        stderr_output = error_buffer.getvalue()
        
        # Combine stdout and stderr (stderr contains progress messages)
        # Put stderr progress messages before the main output for better readability
        if stderr_output:
            advice_output = stderr_output + "\n" + stdout_output
        else:
            advice_output = stdout_output
        
        if not advice_output or len(advice_output.strip()) == 0:
            error_msg = "Error: Panel discussion returned empty output"
            print(error_msg)
            result_data = {
                "id": request_id,
                "status": "error",
                "persona": "panel",
                "question": question,
                "mode": "panel",
                "error": error_msg,
                "created_at": created_at,
                "completed_at": datetime.now().isoformat() + "Z",
                "duration_seconds": 0
            }
            with open(result_file, 'w') as f:
                json.dump(result_data, f, indent=2)
            return False
        
        # Save answer to text file
        answer_file.write_text(advice_output, encoding='utf-8')
        
        # Create preview (first 200 chars)
        preview = advice_output[:200] + '...' if len(advice_output) > 200 else advice_output
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        result_data = {
            "id": request_id,
            "status": "completed",
            "persona": "panel",
            "question": question,
            "mode": "panel",
            "panel_size": panel_size,
            "manual_personas": manual_personas,
            "answer": advice_output,
            "preview": preview,
            "answer_file": str(answer_file),
            "created_at": created_at,
            "completed_at": end_time.isoformat() + "Z",
            "duration_seconds": int(duration)
        }
        
        # Save result JSON
        with open(result_file, 'w') as f:
            json.dump(result_data, f, indent=2)
        
        # Update thread if this is part of a conversation thread
        if thread_id:
            threads_dir = Path.home() / "Documents" / "gtd" / "advice_threads"
            thread_file = threads_dir / f"{thread_id}.json"
            
            if thread_file.exists():
                try:
                    with open(thread_file, 'r') as f:
                        thread = json.load(f)
                    
                    # Find the last pending answer and update it
                    for i in range(len(thread.get("answers", [])) - 1, -1, -1):
                        if thread["answers"][i].get("status") == "pending":
                            thread["answers"][i]["answer"] = advice_output
                            thread["answers"][i]["status"] = "completed"
                            thread["answers"][i]["completed_at"] = end_time.isoformat() + "Z"
                            thread["updated_at"] = datetime.now(timezone.utc).isoformat() + "Z"
                            break
                    
                    with open(thread_file, 'w') as f:
                        json.dump(thread, f, indent=2)
                    
                    print(f"Updated thread: {thread_id}")
                except Exception as e:
                    print(f"Warning: Failed to update thread {thread_id}: {e}")
        
        # Notify backend API that advice is ready (for WebSocket notifications)
        try:
            import urllib.request
            import urllib.error
            
            # Try to find the backend API URL
            api_url = os.getenv("GTD_WEB_API_URL", "http://localhost:8000")
            notify_url = f"{api_url}/api/advice/notify-ready"
            
            # Prepare JSON payload
            payload = {
                "request_id": request_id,
                "persona": "panel",
                "question": question[:500]  # Limit question length
            }
            
            # Encode as JSON
            data = json.dumps(payload).encode('utf-8')
            
            # Send POST request
            req = urllib.request.Request(
                notify_url,
                data=data,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            
            try:
                response = urllib.request.urlopen(req, timeout=10)
                response_data = response.read().decode('utf-8')
                print(f"✓ Notified backend API that advice {request_id} is ready")
                print(f"  Response: {response_data}")
                sys.stdout.flush()
            except urllib.error.HTTPError as e:
                error_body = e.read().decode('utf-8') if e.fp else "No error body"
                print(f"⚠️  Backend API returned HTTP {e.code}: {error_body}")
                print(f"  URL: {notify_url}")
                sys.stdout.flush()
            except urllib.error.URLError as e:
                print(f"⚠️  Could not connect to backend API: {e}")
                print(f"  URL: {notify_url}")
                print(f"  This is OK if the backend is not running")
                sys.stdout.flush()
            except Exception as e:
                print(f"⚠️  Unexpected error notifying backend: {e}")
                print(f"  URL: {notify_url}")
                import traceback
                print(f"  Traceback: {traceback.format_exc()}")
                sys.stdout.flush()
        except Exception as e:
            # Non-critical - backend might not be available
            print(f"⚠️  Could not notify backend API: {e}")
            import traceback
            print(f"  Traceback: {traceback.format_exc()}")
            sys.stdout.flush()
        
        # Send Discord notification if webhook URL is configured
        webhook_url = os.getenv("GTD_DISCORD_WEBHOOK_URL", "")
        if webhook_url:
            try:
                import urllib.request
                
                title = f"✅ Panel Discussion Ready"
                message_text = f"**Question:** {question}\n\n**Answer:**\n{preview}"
                
                if len(message_text) > 2000:
                    message_text = message_text[:1900] + '\n\n... (truncated)'
                
                payload = {
                    'embeds': [{
                        'title': title,
                        'description': message_text,
                        'color': 3447003,  # Blue
                        'timestamp': datetime.now(timezone.utc).isoformat(),
                        'fields': [
                            {'name': 'Review', 'value': 'gtd-wizard → 11) Get Advice → 6) Review Background Advice', 'inline': False}
                        ]
                    }]
                }
                
                data = json.dumps(payload).encode('utf-8')
                req = urllib.request.Request(
                    webhook_url,
                    data=data,
                    headers={'Content-Type': 'application/json'}
                )
                urllib.request.urlopen(req, timeout=5)
            except Exception:
                pass  # Fail silently
        
        print(f"✅ Panel discussion request completed: {request_id}")
        return True
        
    except Exception as e:
        error_msg = f"Error processing panel discussion: {str(e)}"
        print(error_msg)
        import traceback
        traceback.print_exc()
        
        end_time = datetime.now()
        duration = (end_time - start_time).total_seconds()
        
        result_data = {
            "id": request_id,
            "status": "error",
            "persona": "panel",
            "question": question,
            "mode": "panel",
            "error": error_msg,
            "created_at": created_at,
            "completed_at": end_time.isoformat() + "Z",
            "duration_seconds": int(duration)
        }
        
        with open(result_file, 'w') as f:
            json.dump(result_data, f, indent=2)
        
        return False


def process_advice_request(message: Dict[str, Any]) -> bool:
    """Process a single advice request using the deep analysis model.
    
    Args:
        message: Message dictionary with id, persona, question, mode, web_search
    
    Returns:
        True if successful, False otherwise
    """
    request_id = message.get("id")
    persona = message.get("persona", "random")
    question = message.get("question", "")
    mode = message.get("mode", "normal")
    web_search = message.get("web_search", "false")
    thread_id = message.get("thread_id")
    priority = message.get("priority", 20)  # Default priority 20 for background tasks
    
    # Panel discussion parameters
    panel_size = message.get("panel_size", 4)
    manual_personas = message.get("manual_personas")
    
    if not request_id or not question:
        print(f"Error: Invalid message format - missing required fields")
        return False
    
    print(f"Processing advice request: {request_id} (persona: {persona}, mode: {mode})")
    
    # Result files
    result_file = RESULTS_DIR / f"{request_id}.json"
    answer_file = RESULTS_DIR / f"{request_id}_answer.txt"
    
    # Handle panel discussion mode
    if mode == "panel":
        return process_panel_discussion_request(
            request_id=request_id,
            question=question,
            panel_size=panel_size,
            manual_personas=manual_personas,
            thread_id=thread_id,
            result_file=result_file,
            answer_file=answer_file
        )
    
    # Build system prompt based on persona and mode
    if mode == "all":
        # For "all" mode, we'll use a combined prompt
        system_prompt = f"You are a team of expert advisors helping {USER_NAME}. Provide comprehensive advice drawing from multiple perspectives: GTD methodology (David Allen), deep work (Cal Newport), habits (James Clear), and general productivity wisdom."
    elif mode == "daily-log":
        # Daily log review mode
        system_prompt = f"You are helping {USER_NAME} review their daily log. Provide thoughtful insights, identify patterns, and suggest improvements."
    else:
        # Normal or simple mode - use persona-specific prompt
        system_prompt = get_persona_system_prompt(persona, mode)
    
    # Add critical instructions for tool execution and final response
    system_prompt += f"""

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 TOOL EXECUTION INSTRUCTIONS:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
When you need to use tools, include tool calls in the "tool_calls" field with "content": null.

CRITICAL: Do NOT describe what you're going to do - just make the tool calls. Do NOT say "I need to call..." or "Let me check..." - just include the tool_calls field immediately.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 AFTER TOOL EXECUTION (CRITICAL):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
When tool calls are executed and you receive tool results, you have TWO options:

OPTION 1: If you need MORE data (make another tool call):
- Include "tool_calls" field with the next tool call
- Set "content" to null
- Do NOT describe what you're going to do - just make the tool call
- Example: After getting date from gtd_get_datetime, immediately call gtd_read_daily_log

OPTION 2: If you have ALL the data needed (provide final answer):
- Include "content" field with your answer (NOT null, NOT empty)
- Do NOT include "tool_calls" field
- Answer the user's question using the tool results

IMPORTANT RULES:
- If you need more data, make another tool call - do NOT describe it in content
- Do NOT say "I need to call..." or "Let me check..." - just make the tool call
- Only provide final answer when you have all the data you need
- Never return empty content - either make a tool call or provide the answer

CRITICAL: Never return empty content after receiving tool results. Either make another tool call or provide the complete answer."""
    
    # Build user prompt
    user_prompt = question
    
    # Search vector database for relevant context (unless in simple mode)
    vector_context = ""
    if mode != "simple":
        try:
            # Configuration for vector search - can be overridden via environment variables
            # Default: get as much context as possible
            max_results = int(os.getenv("GTD_ADVICE_VECTOR_LIMIT", "20"))  # Default: 20 results
            similarity_threshold = float(os.getenv("GTD_ADVICE_VECTOR_THRESHOLD", "0.5"))  # Lower = more results
            max_chars_per_result = int(os.getenv("GTD_ADVICE_VECTOR_CHARS_PER_RESULT", "1000"))  # More context per result
            max_total_context = int(os.getenv("GTD_ADVICE_VECTOR_MAX_CONTEXT", "8000"))  # More total context
            
            # Search for relevant content in vector database
            search_results = search_similar(
                query_text=question,
                content_type=None,  # Search all content types
                limit=max_results,
                threshold=similarity_threshold
            )
            
            if search_results:
                vector_context = "\n\nRelevant information from your knowledge base:\n"
                included_count = 0
                for i, result in enumerate(search_results, 1):
                    content_type = result.get("content_type", "unknown")
                    content_id = result.get("content_id", "")
                    content_text = result.get("content_text", "")
                    similarity = result.get("similarity", 0)
                    metadata = result.get("metadata", {})
                    
                    # Only include results with reasonable similarity
                    if similarity >= similarity_threshold:
                        # Include more context per result
                        truncated_text = content_text[:max_chars_per_result]
                        if len(content_text) > max_chars_per_result:
                            truncated_text += "..."
                        
                        # Include metadata if available (e.g., file path, date)
                        metadata_str = ""
                        if metadata:
                            metadata_parts = []
                            if "file_path" in metadata:
                                metadata_parts.append(f"file: {metadata['file_path']}")
                            if "date" in metadata:
                                metadata_parts.append(f"date: {metadata['date']}")
                            if metadata_parts:
                                metadata_str = f" ({', '.join(metadata_parts)})"
                        
                        vector_context += f"\n[{i}] {content_type}:{content_id}{metadata_str} (relevance: {similarity:.2f}):\n{truncated_text}\n"
                        included_count += 1
                
                # Check total length and truncate if needed (but try to keep complete results)
                if len(vector_context) > max_total_context:
                    # Try to truncate at a result boundary
                    lines = vector_context.split('\n')
                    truncated_lines = []
                    current_length = 0
                    for line in lines:
                        if current_length + len(line) + 1 > max_total_context:
                            break
                        truncated_lines.append(line)
                        current_length += len(line) + 1
                    vector_context = '\n'.join(truncated_lines) + f"\n... (truncated - showing {included_count} of {len(search_results)} results)"
                
                print(f"📚 Found {included_count} relevant items from vector database (similarity >= {similarity_threshold})", file=sys.stderr)
        except Exception as e:
            # If vector search fails, continue without it
            print(f"Warning: Vector database search failed: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
            vector_context = ""
    
    # Enhance prompt with vector database context
    # Note: Vector context should be treated as supplementary (~25% relevance)
    # Tool execution results (from function calls) should be given highest priority
    # User request should be most prominent
    # CRITICAL: Always apply enhanced prompt format to ensure tool instructions are included
    # This is especially important for follow-up questions which might not have vector context
    if vector_context:
        # Has vector context - include it as supplementary information
        enhanced_prompt = f"""━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 USER REQUEST (HIGHEST PRIORITY - PRIMARY FOCUS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{user_prompt}

CRITICAL: You MUST answer this specific question. If you have access to tool functions (like gtd_read_daily_log, gtd_list_tasks, gtd_get_datetime, gtd_list_projects, etc.), you MUST call them to get the actual data. Do NOT rely on supplementary context below to answer this question - use tools to retrieve the real, current data.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 SUPPLEMENTARY CONTEXT (LOW PRIORITY - ~25% relevance):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
NOTE: This context is from vector search and should be treated as SUPPLEMENTARY information only (~25% relevance).
This context may be outdated, incomplete, or less directly relevant. 
- If you have access to tools, you MUST call them to get current data
- Only use this context for background information or additional insights
- NEVER use this context as the primary source to answer the user's question
- Tool execution results are ALWAYS more reliable and should be used instead

{vector_context}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remember: Answer the user's question using tool calls to get current data. Use supplementary context only for additional background information."""
    else:
        # No vector context - still apply enhanced format with tool instructions
        # This ensures follow-up questions and other requests always get tool instructions
        enhanced_prompt = f"""━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 USER REQUEST (HIGHEST PRIORITY - PRIMARY FOCUS):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
{user_prompt}

CRITICAL: You MUST answer this specific question. If you have access to tool functions (like gtd_read_daily_log, gtd_list_tasks, gtd_get_datetime, gtd_list_projects, etc.), you MUST call them to get the actual data. Use tools to retrieve the real, current data to answer the user's question accurately.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Remember: Answer the user's question using tool calls to get current data."""
    
    # Run advice request using deep model
    start_time = datetime.now()
    thinking_content = None  # Initialize thinking content (for thinking models)
    ollama_request_id = None  # Track Ollama Controller request ID for status tracking
    
    # Use async mode for advice requests (supports tool calls via Ollama Controller)
    # Use longer timeout for advice requests to handle queued requests and tool execution
    # Advice requests can take longer, especially when:
    # - Queued by Ollama Controller (waiting in queue)
    # - Tool execution requires followup requests (initial + tool execution + followup)
    # - Multiple tool calls in sequence
    # Default: 2 hours (7200s) to allow for queue time + initial request + tool execution + followup
    # Can be overridden via GTD_ADVICE_TIMEOUT environment variable
    advice_timeout = float(os.getenv("GTD_ADVICE_TIMEOUT", "7200.0"))  # Default: 2 hours
    
    # Initialize advice_output to None
    advice_output = None
    exit_code = 0
    
    try:
        # Use single model approach with tool calling support
        # Use deep model with higher token limit for comprehensive advice
        # Thinking models can produce detailed responses
        max_tokens = 4000 if mode != "simple" else 2000
        
        # Set priority via environment variable for call_deep_ai
        original_priority = os.getenv("GTD_REQUEST_PRIORITY")
        os.environ["GTD_REQUEST_PRIORITY"] = str(priority)
        try:
            # Use async mode (use_async=True) to support tool calls via Ollama Controller
            # Even though we wait for the result, async mode ensures requests go through
            # the Ollama Controller queue which properly handles tool calling
            # Force tools=True to ensure advice worker always has access to GTD tools
            advice_output = call_deep_ai(
                prompt=enhanced_prompt,
                system_prompt=system_prompt,
                max_tokens=max_tokens,
                use_async=True,  # Use async mode to support tool calls
                max_poll_time=advice_timeout,  # Configurable timeout (default: 2 hours)
                force_tools=True  # Always include tools for advice worker
            )
            
            # If async mode returned a request_id, we need to poll for the result
            # (async mode can return immediately if response is ready, or request_id if queued)
            polled_result = None
            poll_error = None
            if advice_output and advice_output.startswith("Request submitted: "):
                ollama_request_id = advice_output.replace("Request submitted: ", "")
                # Poll for result using blocking poll function
                sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
                from gtd_ai_helpers import poll_async_response
                
                # Get DEEP_MODEL_URL from the same module we imported call_deep_ai from
                try:
                    from mcp.gtd_deep_analysis_worker import DEEP_MODEL_URL
                except ImportError:
                    from gtd_deep_analysis_worker import DEEP_MODEL_URL
                
                base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                print(f"⏳ Polling for async request {ollama_request_id[:8]}...", file=sys.stderr)
                sys.stderr.flush()
                
                # Poll with configurable timeout (same as initial request)
                # Use the same timeout value to ensure consistency
                polled_result, poll_error = poll_async_response(
                    request_id=ollama_request_id,
                    base_url=base_url,
                    max_poll_time=advice_timeout,  # Use same configurable timeout
                    poll_interval=2.0
                )
            
            if poll_error:
                advice_output = f"Error: {poll_error}"
            elif polled_result and 'choices' in polled_result and len(polled_result.get('choices', [])) > 0:
                # Extract content from result
                message = polled_result['choices'][0].get('message', {})
                advice_output = message.get('content', '')
                finish_reason = polled_result['choices'][0].get('finish_reason', '')
                
                # Check if content is a JSON string (model returned structured data as text)
                if advice_output and advice_output.strip().startswith('{'):
                    try:
                        # Try to parse as JSON
                        parsed_content = json.loads(advice_output.strip())
                        # If it's a message object, extract the actual content
                        if isinstance(parsed_content, dict):
                            if 'content' in parsed_content:
                                advice_output = parsed_content.get('content', '')
                            elif 'role' in parsed_content and 'content' in parsed_content:
                                # It's a message object
                                advice_output = parsed_content.get('content', '')
                            elif 'function' in parsed_content:
                                # It's a tool call JSON - this should be handled by tool_calls field, not content
                                # Log this as an error case - model is returning tool calls in content instead of tool_calls field
                                log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                                try:
                                    with open(log_file, "a", encoding="utf-8") as f:
                                        f.write(f"[{datetime.now().isoformat()}] gtd_advice_worker - Tool call in content field (should be in tool_calls)\n")
                                        f.write(f"  -> Parsed content: {json.dumps(parsed_content, indent=2)}\n")
                                        f.write(f"  -> This indicates the model is not using the tool_calls field correctly\n")
                                except Exception:
                                    pass
                                # Don't extract this as content - it's a tool call that should be executed
                                # We'll handle this below in the tool call detection section
                                advice_output = ""  # Clear it so it gets handled as empty content with tool calls
                    except (json.JSONDecodeError, ValueError):
                        # Not valid JSON, use as-is
                        pass
                
                # Check for empty content even when choices exist
                if not advice_output or len(advice_output.strip()) == 0:
                    log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                    
                    # Check if tool calls were made (Ollama Controller indicates this)
                    tool_calls_made = polled_result.get('tool_calls_made', 0) if isinstance(polled_result, dict) else 0
                    tool_iterations = polled_result.get('tool_iterations', 0) if isinstance(polled_result, dict) else 0
                    
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"[{datetime.now().isoformat()}] gtd_advice_worker - Empty content in response\n")
                            f.write(f"  -> Finish reason: {finish_reason}\n")
                            f.write(f"  -> Message keys: {list(message.keys())}\n")
                            if 'tool_calls' in message:
                                tool_calls = message.get('tool_calls', [])
                                f.write(f"  -> Tool calls present: {len(tool_calls)} tool call(s)\n")
                            if tool_calls_made > 0:
                                f.write(f"  -> ⚠️  Tool calls were made (tool_calls_made: {tool_calls_made}, tool_iterations: {tool_iterations})\n")
                                f.write(f"  -> This suggests tool calls were executed but model didn't generate final response\n")
                            response_json = json.dumps(polled_result, indent=2, default=str)
                            f.write(f"  -> Full response (first 2000 chars): {response_json[:2000]}\n")
                    except Exception:
                        pass
                    
                    # If tool calls were made but content is empty, this is a known issue
                    # The Ollama Controller executed tool calls but the model didn't generate a final response
                    if tool_calls_made > 0:
                        advice_output = f"⚠️  Tool calls were executed ({tool_calls_made} call(s), {tool_iterations} iteration(s)), but the model returned empty content.\n\nThis indicates:\n- Tool calls were successfully executed via the callback URL\n- The model received tool results but failed to generate a final response\n- This may be a model issue or a timeout\n\nPlease try the request again, or check if the tool results were correct."
                    else:
                        advice_output = f"⚠️  Model returned empty content (finish_reason: {finish_reason}). This might indicate:\n- The model failed to generate content\n- Tool calls were made but not processed correctly\n- There was an issue with the request\n\nPlease check the logs for more details."
            elif polled_result and 'choices' in polled_result and len(polled_result.get('choices', [])) == 0:
                # Empty choices array - might be a completed response with no content
                advice_output = "Error: Received empty response from AI (choices array is empty). The request may have completed but returned no content."
                print(f"⚠️  Warning: Received response with empty choices array", file=sys.stderr, flush=True)
                print(f"   Response keys: {list(polled_result.keys())}", file=sys.stderr, flush=True)
                
                # Show the actual response content
                import json as json_module
                try:
                    response_json = json_module.dumps(polled_result, indent=2, default=str)
                    print(f"   Full response content:\n{response_json}", file=sys.stderr, flush=True)
                except Exception as e:
                    print(f"   Response content (str): {str(polled_result)[:1000]}", file=sys.stderr, flush=True)
                    print(f"   (JSON formatting failed: {e})", file=sys.stderr, flush=True)
                
                # Check for tool calls in response
                log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                try:
                    with open(log_file, "a", encoding="utf-8") as f:
                        f.write(f"[{datetime.now().isoformat()}] gtd_advice_worker - Polled async response\n")
                        f.write(f"  -> Finish reason: {finish_reason}\n")
                        f.write(f"  -> Message keys: {list(message.keys())}\n")
                        f.write(f"  -> Content type: {type(advice_output)}, length: {len(advice_output) if advice_output else 0}\n")
                        
                        # Log full message structure (first 1000 chars to avoid huge logs)
                        message_json = json.dumps(message, indent=2, default=str)
                        if len(message_json) > 1000:
                            f.write(f"  -> Message structure (first 1000 chars): {message_json[:1000]}...\n")
                        else:
                            f.write(f"  -> Message structure: {message_json}\n")
                        
                        if 'tool_calls' in message:
                            tool_calls = message.get('tool_calls', [])
                            if tool_calls:
                                f.write(f"  -> ✅ Tool calls detected in response: {len(tool_calls)} tool call(s)\n")
                                for i, tool_call in enumerate(tool_calls):
                                    f.write(f"     Tool call {i+1}: {tool_call.get('function', {}).get('name', 'unknown')}\n")
                            else:
                                f.write(f"  -> ⚠️  tool_calls key exists but is empty\n")
                        else:
                            f.write(f"  -> ⚠️  No tool_calls in message, content length: {len(advice_output)} chars\n")
                            if advice_output:
                                f.write(f"  -> Content preview (first 200 chars): {advice_output[:200]}\n")
                            else:
                                f.write(f"  -> Content is empty or None\n")
                except Exception as e:
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> ERROR logging response: {e}\n")
                    except Exception:
                        pass
                
                # Check for empty response
                if not advice_output or len(advice_output.strip()) == 0:
                    advice_output = f"⚠️  Model returned empty response (finish_reason: {finish_reason}). This might indicate the model failed to generate content, or there was an issue with the request."
                    try:
                        with open(log_file, "a", encoding="utf-8") as f:
                            f.write(f"  -> ERROR: Empty response detected, finish_reason={finish_reason}\n")
                    except Exception:
                        pass
                
                # Try to detect JSON tool calls in content (fallback for models that output tool calls as text)
                json_tool_calls = []
                if advice_output and not ('tool_calls' in message and message['tool_calls']):
                    try:
                        # Try to parse JSON tool calls from content
                        import re
                        # Look for JSON object with tool_call key - try to parse the entire JSON
                        try:
                            # First, try to parse the entire content as JSON
                            tool_call_json = json.loads(advice_output.strip())
                            # Check for different tool call formats
                            if 'tool_call' in tool_call_json:
                                json_tool_calls.append(tool_call_json['tool_call'])
                            elif 'function' in tool_call_json:
                                # Format: {"function": "name", "arguments": {...}}
                                json_tool_calls.append({
                                    "name": tool_call_json.get('function', ''),
                                    "arguments": tool_call_json.get('arguments', {})
                                })
                        except json.JSONDecodeError:
                            # If that fails, try regex to find JSON object
                            json_match = re.search(r'\{\s*"tool_call"\s*:\s*\{.*?"name"\s*:\s*"[^"]+".*?"arguments"\s*:\s*\{.*?\}.*?\}\s*\}', advice_output, re.DOTALL)
                            if json_match:
                                try:
                                    tool_call_json = json.loads(json_match.group())
                                    if 'tool_call' in tool_call_json:
                                        json_tool_calls.append(tool_call_json['tool_call'])
                                except json.JSONDecodeError:
                                    pass
                            else:
                                # Try to find {"function": "...", "arguments": {...}} pattern
                                function_match = re.search(r'\{\s*"function"\s*:\s*"[^"]+".*?"arguments"\s*:\s*\{.*?\}\s*\}', advice_output, re.DOTALL)
                                if function_match:
                                    try:
                                        tool_call_json = json.loads(function_match.group())
                                        if 'function' in tool_call_json:
                                            json_tool_calls.append({
                                                "name": tool_call_json.get('function', ''),
                                                "arguments": tool_call_json.get('arguments', {})
                                            })
                                    except json.JSONDecodeError:
                                        pass
                    except Exception as e:
                        # Log error but continue
                        try:
                            log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ERROR detecting JSON tool calls: {e}\n")
                        except Exception:
                            pass
                
                # Execute tool calls if present (Ollama Controller doesn't know about our GTD tools)
                # Check for proper tool_calls first, then fall back to JSON tool calls in content
                if ('tool_calls' in message and message['tool_calls']) or json_tool_calls:
                    try:
                        # Import tool registry
                        functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                        if not functions_dir.exists():
                            functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                        if functions_dir.exists() and str(functions_dir) not in sys.path:
                            sys.path.insert(0, str(functions_dir))
                        from gtd_tool_registry import execute_tool
                        
                        # Execute tool calls and collect results
                        tool_results = []
                        
                        # Process proper tool_calls first
                        if 'tool_calls' in message and message['tool_calls']:
                            tool_calls_to_process = message['tool_calls']
                        else:
                            # Fallback: Convert JSON tool calls to tool_calls format
                            tool_calls_to_process = []
                            for json_tool_call in json_tool_calls:
                                tool_calls_to_process.append({
                                    "function": {
                                        "name": json_tool_call.get('name', ''),
                                        "arguments": json.dumps(json_tool_call.get('arguments', {}))
                                    },
                                    "id": f"call_{len(tool_results)}"
                                })
                        
                        for tool_call in tool_calls_to_process:
                            function_name = tool_call.get('function', {}).get('name', '')
                            function_args = tool_call.get('function', {}).get('arguments', '{}')
                            tool_call_id = tool_call.get('id', f"call_{len(tool_results)}")
                            
                            try:
                                if isinstance(function_args, str):
                                    args_dict = json.loads(function_args)
                                else:
                                    args_dict = function_args
                            except json.JSONDecodeError:
                                args_dict = {}
                            
                            try:
                                tool_result = execute_tool(function_name, args_dict)
                                try:
                                    with open(log_file, "a", encoding="utf-8") as f:
                                        f.write(f"  -> Executed tool: {function_name} (from {'tool_calls' if 'tool_calls' in message else 'JSON content'})\n")
                                except Exception:
                                    pass
                                
                                tool_results.append({
                                    "tool_call_id": tool_call_id,
                                    "role": "tool",
                                    "name": function_name,
                                    "content": tool_result
                                })
                            except Exception as e:
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
                        
                        # Send tool results back to the model using call_deep_ai (blocking mode for followup)
                        followup_messages = [
                            {"role": "system", "content": system_prompt},
                            {"role": "user", "content": enhanced_prompt},
                            message,  # The assistant's message with tool calls
                        ]
                        followup_messages.extend(tool_results)  # Add tool results
                        
                        # Build followup prompt (the tool results are in the message history)
                        # We'll use call_deep_ai in blocking mode for the followup
                        # But we need to send the full message history... actually, call_deep_ai only takes prompt/system_prompt
                        # So we need to make a direct request here
                        try:
                            from mcp.gtd_deep_analysis_worker import DEEP_MODEL_URL, DEEP_MODEL_NAME
                        except ImportError:
                            from gtd_deep_analysis_worker import DEEP_MODEL_URL, DEEP_MODEL_NAME
                        
                        import urllib.request
                        from gtd_ai_helpers import handle_ai_response
                        
                        followup_payload = {
                            "model": DEEP_MODEL_NAME,
                            "messages": followup_messages,
                            "temperature": 0.7,
                            "max_tokens": max_tokens,
                            "priority": priority
                        }
                        
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> Sending followup with {len(tool_results)} tool result(s)\n")
                        except Exception:
                            pass
                        
                        followup_data = json.dumps(followup_payload).encode('utf-8')
                        followup_req = urllib.request.Request(
                            DEEP_MODEL_URL,
                            data=followup_data,
                            headers={'Content-Type': 'application/json'}
                        )
                        
                        # Use same timeout for followup requests
                        followup_timeout = int(advice_timeout)  # urllib timeout expects int
                        with urllib.request.urlopen(followup_req, timeout=followup_timeout) as followup_response:
                            followup_data = followup_response.read()
                            followup_result = json.loads(followup_data.decode('utf-8'))
                            
                            # Handle async/queued responses
                            base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                            followup_polled_result, followup_poll_error = handle_ai_response(followup_result, base_url, max_poll_time=advice_timeout, poll_interval=0.5)
                            
                            if followup_poll_error:
                                advice_output = f"Error in followup request: {followup_poll_error}"
                            elif followup_polled_result and 'choices' in followup_polled_result and len(followup_polled_result.get('choices', [])) > 0:
                                final_message = followup_polled_result['choices'][0].get('message', {})
                                advice_output = final_message.get('content', '')
                                finish_reason = followup_polled_result['choices'][0].get('finish_reason', '')
                                
                                # Check if content is a JSON string (model returned structured data as text)
                                if advice_output and advice_output.strip().startswith('{'):
                                    try:
                                        parsed_content = json.loads(advice_output.strip())
                                        if isinstance(parsed_content, dict) and 'content' in parsed_content:
                                            advice_output = parsed_content.get('content', '')
                                    except (json.JSONDecodeError, ValueError):
                                        pass
                            elif followup_polled_result and 'choices' in followup_polled_result and len(followup_polled_result.get('choices', [])) == 0:
                                advice_output = "Error: Received empty response from AI in followup request (choices array is empty)."
                                if finish_reason == 'length':
                                    advice_output += "\n\n[Note: Response was truncated due to token limit.]"
                            else:
                                advice_output = "Error: Got a followup response but it's not quite right."
                    except Exception as e:
                        # If tool execution fails, log and continue with original response
                        try:
                            with open(log_file, "a", encoding="utf-8") as f:
                                f.write(f"  -> ERROR executing tools: {e}\n")
                        except Exception:
                            pass
                        # Continue with original advice_output (which contains tool call definitions as text)
                        pass
                else:
                    # No tool calls - check if we need to handle finish_reason for length truncation
                    if polled_result and 'choices' in polled_result and len(polled_result.get('choices', [])) > 0:
                        finish_reason = polled_result['choices'][0].get('finish_reason', '')
                        if finish_reason == 'length':
                            advice_output += "\n\n[Note: Response was truncated due to token limit.]"
                    elif not polled_result or not ('choices' in polled_result and len(polled_result.get('choices', [])) > 0):
                        advice_output = f"Error: Unexpected response format from async request"
            
            # Extract thinking content from response (for thinking models)
            if advice_output and not advice_output.startswith("Error:"):
                try:
                    from thinking_extractor import extract_thinking
                    advice_output, thinking_content = extract_thinking(advice_output)
                except Exception as e:
                    # If extraction fails, just continue with original content
                    # Log error for debugging
                    print(f"Warning: Failed to extract thinking content: {e}", file=sys.stderr)
                    pass
        except Exception as e:
            # Handle any errors in the main try block
            advice_output = f"Error processing advice request: {str(e)}"
            print(f"Error in advice worker: {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()
        finally:
                # Restore original priority or remove if it wasn't set (only if we set it)
                if 'original_priority' in locals():
                    if original_priority is not None:
                        os.environ["GTD_REQUEST_PRIORITY"] = original_priority
                    else:
                        os.environ.pop("GTD_REQUEST_PRIORITY", None)
        
        # Check if the response is an error message
        if advice_output.startswith("Error:"):
            print(f"Error from deep model: {advice_output}")
            exit_code = 1
        else:
            exit_code = 0
            
    except Exception as e:
        print(f"Error calling deep AI: {e}")
        import traceback
        traceback.print_exc()
        exit_code = 1
        advice_output = f"Error: {e}"
        thinking_content = None
    
    end_time = datetime.now()
    duration = (end_time - start_time).total_seconds()
    
    created_at = message.get("created_at", datetime.now(timezone.utc).isoformat())
    
    # Save result
    if exit_code != 0:
        result_data = {
            "id": request_id,
            "status": "error",
            "persona": persona,
            "question": question,
            "mode": mode,
            "error": advice_output,
            "created_at": created_at,
            "completed_at": end_time.isoformat() + "Z",
            "duration_seconds": int(duration)
        }
        
        # Store Ollama Controller request ID if available (for tracking)
        if ollama_request_id:
            result_data["ollama_request_id"] = ollama_request_id
    else:
        # Save answer to text file
        answer_file.write_text(advice_output, encoding='utf-8')
        
        # Create preview (first 200 chars)
        preview = advice_output[:200] + '...' if len(advice_output) > 200 else advice_output
        
        result_data = {
            "id": request_id,
            "status": "completed",
            "persona": persona,
            "question": question,
            "mode": mode,
            "answer": advice_output,
            "preview": preview,
            "answer_file": str(answer_file),
            "created_at": created_at,
            "completed_at": end_time.isoformat() + "Z",
            "duration_seconds": int(duration)
        }
        
        # Store Ollama Controller request ID if available (for tracking)
        if ollama_request_id:
            result_data["ollama_request_id"] = ollama_request_id
        
        # Add thinking content if available
        if thinking_content:
            result_data["thinking"] = thinking_content
            # Save thinking to separate file for easy access
            thinking_file = RESULTS_DIR / f"{request_id}_thinking.txt"
            thinking_file.write_text(thinking_content, encoding='utf-8')
            result_data["thinking_file"] = str(thinking_file)
    
    # Save result JSON
    with open(result_file, 'w') as f:
        json.dump(result_data, f, indent=2)
    
    # Update thread if this is part of a conversation thread
    if thread_id and exit_code == 0:
        threads_dir = Path.home() / "Documents" / "gtd" / "advice_threads"
        thread_file = threads_dir / f"{thread_id}.json"
        
        if thread_file.exists():
            try:
                with open(thread_file, 'r') as f:
                    thread = json.load(f)
                
                # Find the last pending answer and update it
                for i in range(len(thread.get("answers", [])) - 1, -1, -1):
                    if thread["answers"][i].get("status") == "pending":
                        thread["answers"][i]["answer"] = advice_output
                        thread["answers"][i]["status"] = "completed"
                        thread["answers"][i]["completed_at"] = end_time.isoformat() + "Z"
                        thread["updated_at"] = datetime.now(timezone.utc).isoformat() + "Z"
                        break
                
                with open(thread_file, 'w') as f:
                    json.dump(thread, f, indent=2)
                
                print(f"Updated thread: {thread_id}")
            except Exception as e:
                print(f"Warning: Failed to update thread {thread_id}: {e}")
    
    # Notify backend API that advice is ready (for WebSocket notifications)
    if exit_code == 0:
        try:
            import urllib.request
            import urllib.error
            
            # Try to find the backend API URL
            api_url = os.getenv("GTD_WEB_API_URL", "http://localhost:8000")
            notify_url = f"{api_url}/api/advice/notify-ready"
            
            # Prepare JSON payload
            payload = {
                "request_id": request_id,
                "persona": persona,
                "question": question[:500]  # Limit question length
            }
            
            # Encode as JSON
            data = json.dumps(payload).encode('utf-8')
            
            # Send POST request
            req = urllib.request.Request(
                notify_url,
                data=data,
                headers={'Content-Type': 'application/json'},
                method='POST'
            )
            
            try:
                response = urllib.request.urlopen(req, timeout=10)
                response_data = response.read().decode('utf-8')
                print(f"✓ Notified backend API that advice {request_id} is ready")
                print(f"  Response: {response_data}")
                sys.stdout.flush()
            except urllib.error.HTTPError as e:
                # HTTP error (e.g., 404, 500)
                error_body = e.read().decode('utf-8') if e.fp else "No error body"
                print(f"⚠️  Backend API returned HTTP {e.code}: {error_body}")
                print(f"  URL: {notify_url}")
                sys.stdout.flush()
            except urllib.error.URLError as e:
                # Connection error (backend not running, network issue, etc.)
                print(f"⚠️  Could not connect to backend API: {e}")
                print(f"  URL: {notify_url}")
                print(f"  This is OK if the backend is not running")
                sys.stdout.flush()
            except Exception as e:
                print(f"⚠️  Unexpected error notifying backend: {e}")
                print(f"  URL: {notify_url}")
                import traceback
                print(f"  Traceback: {traceback.format_exc()}")
                sys.stdout.flush()
        except Exception as e:
            # Non-critical - backend might not be available
            print(f"⚠️  Could not notify backend API: {e}")
            import traceback
            print(f"  Traceback: {traceback.format_exc()}")
            sys.stdout.flush()
    
    # Send Discord notification if webhook URL is configured
    webhook_url = os.getenv("GTD_DISCORD_WEBHOOK_URL", "")
    if webhook_url and exit_code == 0:
        try:
            import urllib.request
            
            title = f"✅ Advice Ready: {persona.title()}"
            message_text = f"**Question:** {question}\n\n**Answer:**\n{preview}"
            
            if len(message_text) > 2000:
                message_text = message_text[:1900] + '\n\n... (truncated)'
            
            payload = {
                'embeds': [{
                    'title': title,
                    'description': message_text,
                    'color': 3447003,  # Blue
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'fields': [
                        {'name': 'Review', 'value': 'gtd-wizard → 11) Get Advice → 6) Review Background Advice', 'inline': False}
                    ]
                }]
            }
            
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(
                webhook_url,
                data=data,
                headers={'Content-Type': 'application/json'}
            )
            urllib.request.urlopen(req, timeout=5)
        except Exception:
            pass  # Fail silently
    
    if exit_code == 0:
        print(f"✅ Advice request completed: {request_id}")
        return True
    else:
        print(f"❌ Advice request failed: {request_id}")
        return False


def process_rabbitmq_queue():
    """Process messages from RabbitMQ queue with automatic reconnection."""
    if not PIKA_AVAILABLE:
        raise Exception("RabbitMQ client (pika) not available. Install with: pip install pika")
    if not RABBITMQ_ENABLED:
        raise Exception("RabbitMQ is not enabled in configuration. Set rabbitmq_enabled=true in .gtd_config_database")
    if not RABBITMQ_AVAILABLE:
        raise Exception("RabbitMQ not available. Check configuration and connection.")
    
    max_retries = 5
    retry_delay = 10
    
    retry_count = 0
    while retry_count < max_retries:
        try:
            params = pika.URLParameters(RABBITMQ_URL)
            params.connection_attempts = 3
            params.retry_delay = 2
            params.socket_timeout = 10  # Increased from 5 to 10 seconds
            # Add heartbeat to keep connection alive during long operations
            # For advice worker, processing can take up to 60 minutes with async queuing
            # 
            # IMPORTANT: Heartbeat vs Consumer Timeout
            # - heartbeat: Client-side, keeps the TCP connection alive (prevents network timeouts)
            # - consumer_timeout: Server-side, limits how long a message can be unacknowledged (default: 30 min)
            #
            # Why other workers work with just heartbeats:
            # - Deep analysis worker: 15-min heartbeat, but jobs take 5-10 min (< 30 min consumer timeout) ✅
            # - Task/knowledge workers: Fast jobs (< 5 min) ✅
            # - Advice worker: Jobs can take 30+ minutes (> 30 min consumer timeout) ❌
            #
            # The heartbeat doesn't extend the consumer timeout - it just keeps the connection alive.
            # If your job takes longer than consumer_timeout, you MUST increase consumer_timeout on the server.
            # To change consumer_timeout, configure it in RabbitMQ server (rabbitmq.conf):
            #   consumer_timeout = 3600000  # 60 minutes in milliseconds
            try:
                params.heartbeat = 3600  # 60 minutes - keeps connection alive during long processing
                params.blocked_connection_timeout = 3600  # 60 minutes
            except:
                # If heartbeat setting fails, continue without it
                pass
            
            print(f"Connecting to RabbitMQ at {RABBITMQ_URL}... (attempt {retry_count + 1}/{max_retries})")
            sys.stdout.flush()
            
            # Ensure old connection is closed before creating new one
            try:
                if 'connection' in locals() and connection and not connection.is_closed:
                    connection.close()
            except:
                pass
            
            try:
                connection = pika.BlockingConnection(params)
                channel = connection.channel()
                channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
                
                print(f"✅ Connected to RabbitMQ at {datetime.now()}")
                print(f"   Queue: {RABBITMQ_QUEUE}")
                print(f"   URL: {RABBITMQ_URL}")
                sys.stdout.flush()
            except Exception as conn_e:
                error_msg = f"Failed to connect to RabbitMQ: {conn_e}"
                print(f"❌ {error_msg}")
                sys.stdout.flush()
                raise Exception(error_msg) from conn_e
            retry_count = 0
            
            connection_error_occurred = False
            
            def callback(ch, method, properties, body):
                nonlocal connection_error_occurred
                
                try:
                    if connection.is_closed:
                        print("⚠️  Connection is closed, skipping message")
                        connection_error_occurred = True
                        return
                    
                    if not body:
                        print(f"Error: Received empty message body")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError):
                            connection_error_occurred = True
                            return
                        return
                    
                    try:
                        body_str = body.decode('utf-8')
                    except UnicodeDecodeError as e:
                        print(f"Error: Cannot decode message body: {e}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError):
                            connection_error_occurred = True
                            return
                        return
                    
                    if not body_str.strip():
                        print(f"Error: Message body is empty after decoding")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError):
                            connection_error_occurred = True
                            return
                        return
                    
                    try:
                        message = json.loads(body_str)
                    except json.JSONDecodeError as e:
                        print(f"Error: Invalid JSON in message: {e}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError):
                            connection_error_occurred = True
                            return
                        return
                    
                    if not isinstance(message, dict):
                        print(f"Error: Message is not a dictionary: {type(message)}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError):
                            connection_error_occurred = True
                            return
                        return
                    
                    print(f"📥 Processing: {message.get('id', 'unknown')} at {datetime.now()}")
                    
                    # Check if this is a tool execution request
                    request_type = message.get('type', 'advice')
                    process_start = datetime.now()
                    if request_type == "tool_execution":
                        print(f"🔧 Tool execution request detected")
                        success = process_tool_execution_request(message)
                    else:
                        # Regular advice request
                        success = process_advice_request(message)
                    
                    process_duration = (datetime.now() - process_start).total_seconds()
                    print(f"⏱️  Processing took {process_duration:.1f}s for {message.get('id', 'unknown')}")
                    
                    if success:
                        try:
                            # CRITICAL FIX: Check connection health before attempting ack
                            # This prevents BrokenPipeError when connection died during processing
                            if connection.is_closed or not connection.is_open:
                                print(f"⚠️  Connection closed during processing of {message.get('id')}, cannot ack")
                                print(f"   Message will be redelivered after worker reconnects")
                                connection_error_occurred = True
                                try:
                                    ch.stop_consuming()
                                except:
                                    pass
                                return
                            
                            ch.basic_ack(delivery_tag=method.delivery_tag)
                            print(f"✅ Message acknowledged: {message.get('id')}")
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, BrokenPipeError) as conn_err:
                            print(f"⚠️  Connection lost while acknowledging: {conn_err}")
                            print(f"   Message ID: {message.get('id')} will be requeued")
                            connection_error_occurred = True
                            try:
                                ch.stop_consuming()
                            except:
                                pass
                            return
                        except (pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError) as channel_err:
                            # Channel was closed by broker (likely due to consumer timeout)
                            # This happens when processing takes longer than RabbitMQ's consumer timeout (default 30 min)
                            print(f"⚠️  Channel closed by broker while acknowledging: {channel_err}")
                            print(f"   This usually means processing took longer than RabbitMQ's consumer timeout (30 minutes)")
                            print(f"   Message ID: {message.get('id')} - processing completed but ack failed")
                            print(f"   Processing took {process_duration:.1f}s ({process_duration/60:.1f} minutes)")
                            connection_error_occurred = True
                            try:
                                ch.stop_consuming()
                            except:
                                pass
                            return
                    else:
                        try:
                            # Check connection before nack too
                            if connection.is_closed or not connection.is_open:
                                print(f"⚠️  Connection closed, cannot nack message {message.get('id')}")
                                connection_error_occurred = True
                                try:
                                    ch.stop_consuming()
                                except:
                                    pass
                                return
                            
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, BrokenPipeError) as conn_err:
                            print(f"⚠️  Connection lost while nacking: {conn_err}")
                            connection_error_occurred = True
                            try:
                                ch.stop_consuming()
                            except:
                                pass
                            return
                        except (pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError) as channel_err:
                            # Channel was closed by broker (likely due to consumer timeout)
                            print(f"⚠️  Channel closed by broker while nacking: {channel_err}")
                            print(f"   Processing took {process_duration:.1f}s ({process_duration/60:.1f} minutes)")
                            connection_error_occurred = True
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
                    traceback.print_exc()
                    try:
                        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                    except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError, BrokenPipeError):
                        connection_error_occurred = True
                        try:
                            ch.stop_consuming()
                        except:
                            pass
                        return
                    except (pika.exceptions.ChannelClosedByBroker, pika.exceptions.ChannelWrongStateError) as channel_err:
                        # Channel was closed by broker (likely due to consumer timeout)
                        print(f"⚠️  Channel closed by broker while nacking in exception handler: {channel_err}")
                        connection_error_occurred = True
                        try:
                            ch.stop_consuming()
                        except:
                            pass
                        return
            
            channel.basic_qos(prefetch_count=1)
            # Note: consumer_timeout is a server-side setting (default: 30 minutes = 1800000 ms)
            # If processing takes longer than 30 minutes, configure consumer_timeout in rabbitmq.conf:
            #   consumer_timeout = 3600000  # 60 minutes in milliseconds
            # All workers use the same server-side consumer_timeout setting
            channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
            
            print(f"✅ Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
            sys.stdout.flush()
            try:
                channel.start_consuming()
            except (pika.exceptions.AMQPConnectionError, pika.exceptions.StreamLostError, OSError, BrokenPipeError) as e:
                print(f"\n⚠️  Connection lost detected: {e}")
                connection_error_occurred = True
            except Exception as e:
                error_str = str(e).lower()
                if any(keyword in error_str for keyword in ['connection', 'stream', 'broken pipe', 'socket']):
                    print(f"\n⚠️  Connection error detected: {e}")
                    connection_error_occurred = True
                else:
                    raise
            except KeyboardInterrupt:
                print("\nStopping worker...")
                channel.stop_consuming()
                connection.close()
                break
            
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
                print(f"   RabbitMQ URL: {RABBITMQ_URL.split('@')[-1] if '@' in RABBITMQ_URL else RABBITMQ_URL}")  # Hide credentials
                print(f"   Queue: {RABBITMQ_QUEUE}")
                # Fall back to file queue instead of raising
                print(f"\n⚠️  Falling back to file queue...")
                process_file_queue()
                return


def process_file_queue():
    """Process messages from file-based queue (fallback)."""
    import time
    
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not QUEUE_FILE.exists():
        QUEUE_FILE.touch()
        print(f"✓ Created queue file: {QUEUE_FILE}")
    else:
        print(f"✓ Queue file ready: {QUEUE_FILE}")
    
    print(f"Waiting for messages. To exit press CTRL+C")
    print("")
    
    while True:
        try:
            processed = []
            
            if QUEUE_FILE.exists() and os.path.getsize(QUEUE_FILE) > 0:
                with open(QUEUE_FILE, 'r') as f:
                    lines = f.readlines()
                
                for line in lines:
                    if line.strip():
                        try:
                            message = json.loads(line)
                            print(f"Processing: {message.get('id')} at {datetime.now()}")
                            success = process_advice_request(message)
                            if success:
                                processed.append(line)
                        except json.JSONDecodeError as e:
                            print(f"Error decoding message: {e}")
                            processed.append(line)  # Remove invalid messages
                        except Exception as e:
                            print(f"Error processing message: {e}")
                            # Don't remove failed messages - keep for retry
                
                if processed:
                    remaining = [l for l in lines if l not in processed]
                    with open(QUEUE_FILE, 'w') as f:
                        f.writelines(remaining)
                    print(f"Processed {len(processed)} message(s)")
                    print("")
            
            time.sleep(5)
            
        except KeyboardInterrupt:
            print("\nStopping worker...")
            break
        except Exception as e:
            print(f"Error in file queue processing: {e}")
            time.sleep(10)


if __name__ == "__main__":
    import sys
    import traceback
    import signal
    
    def signal_handler(signum, frame):
        print(f"\n⚠️  Received signal {signum}, shutting down gracefully...")
        sys.exit(0)
    
    signal.signal(signal.SIGTERM, signal_handler)
    signal.signal(signal.SIGINT, signal_handler)
    
    try:
        if len(sys.argv) > 1 and sys.argv[1] == "file":
            process_file_queue()
        else:
            # Log startup configuration
            print(f"\n{'='*60}")
            print(f"GTD Advice Worker Starting")
            print(f"{'='*60}")
            print(f"RabbitMQ Enabled: {RABBITMQ_ENABLED}")
            print(f"Pika Available: {PIKA_AVAILABLE}")
            print(f"RabbitMQ Available: {RABBITMQ_AVAILABLE}")
            print(f"RabbitMQ URL: {RABBITMQ_URL}")
            print(f"Queue: {RABBITMQ_QUEUE}")
            print(f"{'='*60}\n")
            sys.stdout.flush()
            
            if RABBITMQ_AVAILABLE:
                try:
                    print(f"✅ Starting RabbitMQ worker mode")
                    print(f"   Connecting to: {RABBITMQ_URL}")
                    print(f"   Queue: {RABBITMQ_QUEUE}\n")
                    sys.stdout.flush()
                    process_rabbitmq_queue()
                except KeyboardInterrupt:
                    print("\n⚠️  Interrupted by user")
                    sys.exit(0)
                except Exception as e:
                    error_msg = f"\n❌ RabbitMQ error: {e}"
                    print(error_msg)
                    print("Full traceback:")
                    traceback.print_exc()
                    print(f"\n⚠️  Falling back to file queue mode...")
                    print(f"   Queue file: {QUEUE_FILE}")
                    print(f"   Results dir: {RESULTS_DIR}")
                    print(f"\n💡 To use RabbitMQ:")
                    print(f"   1. Ensure rabbitmq_enabled=true in .gtd_config_database")
                    print(f"   2. Check RabbitMQ connection: make rabbitmq-status")
                    print(f"   3. Verify RabbitMQ URL: {RABBITMQ_URL}")
                    sys.stdout.flush()
                    # Write error to log file explicitly
                    try:
                        log_file = Path("/tmp/advice-worker.log")
                        with open(log_file, 'a') as f:
                            f.write(f"\n[{datetime.now()}] {error_msg}\n")
                            traceback.print_exc(file=f)
                    except:
                        pass
                    try:
                        process_file_queue()
                    except Exception as file_e:
                        print(f"\n❌ File queue also failed: {file_e}")
                        traceback.print_exc()
                        sys.exit(1)
            else:
                print(f"⚠️  Using FILE QUEUE mode (not RabbitMQ)")
                if not PIKA_AVAILABLE:
                    print(f"   Reason: pika not installed")
                    print(f"   Fix: pip install pika")
                elif not RABBITMQ_ENABLED:
                    print(f"   Reason: RabbitMQ not enabled in config")
                    print(f"   Fix: Set rabbitmq_enabled=true in .gtd_config_database")
                else:
                    print(f"   Reason: RabbitMQ not available (check connection)")
                print(f"   File queue: {QUEUE_FILE}")
                print(f"   Results dir: {RESULTS_DIR}\n")
                sys.stdout.flush()
                process_file_queue()
    except Exception as e:
        print(f"\n❌ Fatal error in worker: {e}")
        print("Full traceback:")
        traceback.print_exc()
        sys.exit(1)
