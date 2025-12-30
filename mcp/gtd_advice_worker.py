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
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

# Read config
def get_rabbitmq_url() -> str:
    """Get RabbitMQ URL with optional credentials."""
    db_config = read_database_config()
    url = os.getenv("GTD_RABBITMQ_URL", db_config.get("rabbitmq_url", "amqp://localhost:5672"))
    
    # If URL already has credentials, use it as-is
    if "//" in url:
        url_parts = url.split("//", 1)
        if len(url_parts) == 2 and "@" in url_parts[1]:
            return url  # Already has credentials
    
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
    
    return url

RABBITMQ_URL = get_rabbitmq_url()
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
    
    if not request_id or not question:
        print(f"Error: Invalid message format - missing required fields")
        return False
    
    print(f"Processing advice request: {request_id} (persona: {persona}, mode: {mode})")
    
    # Result files
    result_file = RESULTS_DIR / f"{request_id}.json"
    answer_file = RESULTS_DIR / f"{request_id}_answer.txt"
    
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
    enhanced_prompt = user_prompt
    if vector_context:
        enhanced_prompt = f"{user_prompt}\n{vector_context}\n\nPlease use the information above to provide a comprehensive answer. Reference specific details from the knowledge base when relevant."
    
    # Run advice request using deep model
    start_time = datetime.now()
    try:
        # Use deep model with higher token limit for comprehensive advice
        # Thinking models can produce detailed responses
        max_tokens = 4000 if mode != "simple" else 2000
        
        # Use longer timeout for advice requests (60 minutes) to handle queued requests
        # Advice requests can take longer, especially when queued by Ollama Controller
        # Set priority via environment variable for call_deep_ai
        original_priority = os.getenv("GTD_REQUEST_PRIORITY")
        os.environ["GTD_REQUEST_PRIORITY"] = str(priority)
        try:
            advice_output = call_deep_ai(
                prompt=enhanced_prompt,
                system_prompt=system_prompt,
                max_tokens=max_tokens,
                max_poll_time=3600.0  # 60 minutes for async polling
            )
        finally:
            # Restore original priority or remove if it wasn't set
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
    if not RABBITMQ_AVAILABLE:
        raise Exception("RabbitMQ not available. Install with: pip install pika")
    
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
            try:
                params.heartbeat = 3600  # 60 minutes - extra long for advice processing
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
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    try:
                        body_str = body.decode('utf-8')
                    except UnicodeDecodeError as e:
                        print(f"Error: Cannot decode message body: {e}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
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
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    if not isinstance(message, dict):
                        print(f"Error: Message is not a dictionary: {type(message)}")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    print(f"📥 Processing: {message.get('id', 'unknown')} at {datetime.now()}")
                    
                    # Store start time to detect long-running operations
                    process_start = datetime.now()
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
            
            channel.basic_qos(prefetch_count=1)
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
            if RABBITMQ_AVAILABLE:
                try:
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
                process_file_queue()
    except Exception as e:
        print(f"\n❌ Fatal error in worker: {e}")
        print("Full traceback:")
        traceback.print_exc()
        sys.exit(1)
