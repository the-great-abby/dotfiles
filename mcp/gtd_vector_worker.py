#!/usr/bin/env python3
"""
GTD Vectorization Worker - Processes vectorization queue from RabbitMQ

Consumes messages from RabbitMQ queue and generates embeddings for GTD content.
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

try:
    from zsh.functions.gtd_vectorization import vectorize_content
    from zsh.functions.gtd_vector_db import read_database_config
except ImportError:
    # Try alternative path
    sys.path.insert(0, str(dotfiles_dir / "zsh" / "functions"))
    from gtd_vectorization import vectorize_content
    from gtd_vector_db import read_database_config

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
    url = os.getenv("RABBITMQ_URL", db_config.get("rabbitmq_url", "amqp://localhost:5672"))
    
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
db_config = read_database_config()
RABBITMQ_QUEUE = os.getenv("RABBITMQ_VECTOR_QUEUE", db_config.get("rabbitmq_queue", "gtd_vectorization"))
QUEUE_FILE = Path.home() / "Documents" / "gtd" / "vectorization_queue.jsonl"


def process_vectorization_request(message: Dict[str, Any]) -> bool:
    """Process a vectorization request from the queue.
    
    Args:
        message: Message dictionary with content_type, content_id, content_text, metadata
    
    Returns:
        True if successful, False otherwise
    """
    # Validate message is a dict
    if not isinstance(message, dict):
        print(f"Error: Message is not a dictionary: {type(message)}")
        print(f"Message: {message}")
        return False
    
    if message is None:
        print(f"Error: Message is None")
        return False
    
    content_type = message.get("content_type")
    content_id = message.get("content_id")
    content_text = message.get("content_text")
    metadata = message.get("metadata", {})
    
    if not all([content_type, content_id, content_text]):
        print(f"Error: Invalid message format - missing required fields")
        print(f"  content_type: {content_type}")
        print(f"  content_id: {content_id}")
        print(f"  content_text: {'present' if content_text else 'missing'} (length: {len(content_text) if content_text else 0})")
        print(f"  message keys: {list(message.keys())}")
        return False
    
    print(f"Vectorizing {content_type}:{content_id}...")
    
    # Call vectorization function (synchronous processing)
    success = vectorize_content(
        content_type=content_type,
        content_id=content_id,
        content_text=content_text,
        metadata=metadata,
        async_mode=False  # Process immediately, not queued
    )
    
    if success:
        print(f"✓ Successfully vectorized {content_type}:{content_id}")
    else:
        print(f"✗ Failed to vectorize {content_type}:{content_id}")
    
    return success


def setup_port_forward(port: int) -> bool:
    """Attempt to set up port forwarding for the given port."""
    try:
        script_paths = [
            Path(__file__).parent.parent / "bin" / "setup-port-forward",
            Path.home() / "code" / "dotfiles" / "bin" / "setup-port-forward",
            Path.home() / "code" / "personal" / "dotfiles" / "bin" / "setup-port-forward",
        ]
        
        setup_script = None
        for path in script_paths:
            if path.exists() and path.is_file():
                setup_script = path
                break
        
        if setup_script:
            import subprocess
            result = subprocess.run(
                [str(setup_script), str(port)],
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0
    except Exception:
        pass
    return False


def process_rabbitmq_queue():
    """Process messages from RabbitMQ queue with automatic reconnection."""
    if not RABBITMQ_AVAILABLE:
        raise Exception("RabbitMQ not available. Install with: pip install pika")
    
    max_retries = 5
    retry_delay = 10  # seconds between reconnection attempts
    
    retry_count = 0
    while retry_count < max_retries:
        try:
            # Add connection timeout to avoid hanging (like deep analysis worker)
            params = pika.URLParameters(RABBITMQ_URL)
            params.connection_attempts = 3
            params.retry_delay = 2
            params.socket_timeout = 5
            
            print(f"Connecting to RabbitMQ... (attempt {retry_count + 1}/{max_retries})")
            connection = pika.BlockingConnection(params)
            channel = connection.channel()
            channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
            
            print(f"✅ Connected to RabbitMQ at {datetime.now()}")
            retry_count = 0  # Reset retry count on successful connection
            
            # Flag to track connection errors from callbacks
            connection_error_occurred = False
            
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
                    
                    if message is None:
                        print(f"Error: Message is None after parsing")
                        try:
                            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
                        except (pika.exceptions.StreamLostError, pika.exceptions.AMQPConnectionError, OSError):
                            connection_error_occurred = True
                            return
                        return
                    
                    success = process_vectorization_request(message)
                    if success:
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
                    else:
                        # Don't requeue on processing failure - message format was OK, processing failed
                        print(f"Warning: Processing failed, not requeuing to avoid infinite loop")
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
                        
                except json.JSONDecodeError as e:
                    print(f"Error decoding message: {e}")
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
                except Exception as e:
                    print(f"Error processing message: {e}")
                    import traceback
                    traceback.print_exc()
                    # Don't requeue on exception - likely malformed message
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
            
            channel.basic_qos(prefetch_count=1)
            channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
            
            print(f"Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
            try:
                # Start consuming - this will block until connection is lost or stopped
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
            error_msg = str(e)
            error_type = type(e).__name__
            retry_count += 1
            
            if retry_count < max_retries:
                print(f"\n⚠️  Failed to connect to RabbitMQ: {e}")
                print(f"   Retrying in {retry_delay} seconds... (attempt {retry_count}/{max_retries})")
                time.sleep(retry_delay)
                continue
            else:
                print(f"\n❌ Failed to connect after {max_retries} attempts")
                print("💡 Check if RabbitMQ is running and accessible:")
                print("   - kubectl get pods -n rabbitmq-system")
                print("   - gtd-wizard → Configuration → Setup RabbitMQ → Test Connection")
                raise Exception(f"Failed to connect to RabbitMQ: {e}")


def process_file_queue():
    """Process messages from file-based queue (fallback). Runs continuously, checking for new messages."""
    import time
    
    # Ensure queue file exists
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    if not QUEUE_FILE.exists():
        QUEUE_FILE.touch()
        print(f"✓ Created queue file: {QUEUE_FILE}")
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
                            success = process_vectorization_request(message)
                            if success:
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
