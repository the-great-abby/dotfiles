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
    content_type = message.get("content_type")
    content_id = message.get("content_id")
    content_text = message.get("content_text")
    metadata = message.get("metadata", {})
    
    if not all([content_type, content_id, content_text]):
        print(f"Error: Invalid message format - missing required fields")
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
            success = process_vectorization_request(message)
            if success:
                ch.basic_ack(delivery_tag=method.delivery_tag)
            else:
                # Requeue on failure
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
        except json.JSONDecodeError as e:
            print(f"Error decoding message: {e}")
            ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
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
