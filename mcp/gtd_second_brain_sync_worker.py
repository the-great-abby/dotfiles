#!/usr/bin/env python3
"""
GTD Second Brain Sync Worker

Background worker that processes second brain sync requests from the queue.
Syncs GTD items (projects, areas, references, daily logs) to Second Brain (Obsidian).
"""

import json
import os
import sys
import time
import subprocess
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, Optional

try:
    import pika
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))

# Import MCP server functions
try:
    from gtd_mcp_server import GTD_BASE_DIR, RABBITMQ_URL
except ImportError:
    print("Error: Could not import from gtd_mcp_server", file=sys.stderr)
    sys.exit(1)

# RabbitMQ configuration
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_SECOND_BRAIN_SYNC_QUEUE", "gtd_second_brain_sync")

# Fallback queue file
QUEUE_FILE = GTD_BASE_DIR / "second_brain_sync_queue.jsonl"

# Results directory
RESULTS_DIR = GTD_BASE_DIR / "second_brain_sync_results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def get_rabbitmq_url() -> str:
    """Get RabbitMQ URL with optional credentials."""
    url = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
    
    # If URL already has credentials, use it as-is
    if "//" in url:
        return url
    
    # Otherwise, try to get credentials from env vars
    username = os.getenv("GTD_RABBITMQ_USERNAME")
    password = os.getenv("GTD_RABBITMQ_PASSWORD")
    
    if username and password:
        # Insert credentials into URL
        if "://" in url:
            protocol, rest = url.split("://", 1)
            url = f"{protocol}://{username}:{password}@{rest}"
        else:
            url = f"amqp://{username}:{password}@{url}"
    
    return url


def process_sync_job(job: Dict[str, Any]) -> Dict[str, Any]:
    """Process a second brain sync job.
    
    Args:
        job: Job dictionary with 'sync_type' and optional 'context'
        
    Returns:
        Result dictionary with sync status and details
    """
    sync_type = job.get("sync_type", "full")
    context = job.get("context", {})
    
    # Get sync command path
    sync_cmd = os.path.expanduser("~/code/dotfiles/bin/gtd-brain-sync")
    if not os.path.exists(sync_cmd):
        sync_cmd = os.path.expanduser("~/code/personal/dotfiles/bin/gtd-brain-sync")
    
    if not os.path.exists(sync_cmd):
        return {
            "success": False,
            "error": "gtd-brain-sync command not found",
            "sync_type": sync_type,
            "timestamp": datetime.now().isoformat()
        }
    
    # Map sync types to command arguments
    sync_args = {
        "full": [],
        "projects": ["projects"],
        "areas": ["areas"],
        "references": ["references"],
        "daily-logs": ["daily-logs"]
    }
    
    args = sync_args.get(sync_type, [])
    
    try:
        # Run the sync command
        result = subprocess.run(
            [sync_cmd] + args,
            capture_output=True,
            text=True,
            timeout=300  # 5 minute timeout
        )
        
        if result.returncode == 0:
            return {
                "success": True,
                "sync_type": sync_type,
                "output": result.stdout,
                "timestamp": datetime.now().isoformat()
            }
        else:
            return {
                "success": False,
                "error": result.stderr or "Unknown error",
                "sync_type": sync_type,
                "output": result.stdout,
                "timestamp": datetime.now().isoformat()
            }
    except subprocess.TimeoutExpired:
        return {
            "success": False,
            "error": "Sync timed out after 5 minutes",
            "sync_type": sync_type,
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e),
            "sync_type": sync_type,
            "timestamp": datetime.now().isoformat()
        }


def save_result(result: Dict[str, Any]) -> Path:
    """Save sync result to file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    sync_type = result.get("sync_type", "unknown")
    result_file = RESULTS_DIR / f"sync_{sync_type}_{timestamp}.json"
    
    with open(result_file, 'w') as f:
        json.dump(result, f, indent=2)
    
    return result_file


def send_notification(result: Dict[str, Any], result_file: Path):
    """Send notification when sync completes."""
    try:
        import subprocess
        
        sync_type = result.get("sync_type", "unknown").replace("_", " ").title()
        
        if result.get("success"):
            title = f"✅ Second Brain Sync Complete"
            message = f"{sync_type} sync completed successfully"
        else:
            title = f"❌ Second Brain Sync Failed"
            message = f"{sync_type} sync failed: {result.get('error', 'Unknown error')}"
        
        # Try to use gtd-notify if available
        notify_cmd = os.path.expanduser("~/code/dotfiles/bin/gtd-notify")
        if not os.path.exists(notify_cmd):
            notify_cmd = os.path.expanduser("~/code/personal/dotfiles/bin/gtd-notify")
        
        if os.path.exists(notify_cmd):
            subprocess.run([
                notify_cmd,
                title,
                message,
                "View results",
                "Glass"
            ], timeout=5, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        elif sys.platform == "darwin":
            applescript = f'''
            display notification "{message}" with title "{title}" sound name "Glass"
            '''
            subprocess.run(
                ["osascript", "-e", applescript],
                timeout=5,
                stderr=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL
            )
    except Exception:
        # Silently fail - notifications are optional
        pass


def process_file_queue():
    """Process jobs from file queue."""
    if not QUEUE_FILE.exists():
        return False
    
    try:
        # Read first line (oldest job)
        with open(QUEUE_FILE, 'r') as f:
            first_line = f.readline()
        
        if not first_line.strip():
            return False
        
        # Parse job
        job = json.loads(first_line)
        
        # Process job
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Processing sync job: {job.get('sync_type', 'unknown')}")
        result = process_sync_job(job)
        
        # Save result
        result_file = save_result(result)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sync complete. Result saved to: {result_file}")
        
        # Send notification
        send_notification(result, result_file)
        
        # Remove processed line from queue
        with open(QUEUE_FILE, 'r') as f:
            lines = f.readlines()
        
        if len(lines) > 1:
            # Write remaining lines back
            with open(QUEUE_FILE, 'w') as f:
                f.writelines(lines[1:])
        else:
            # Empty file
            QUEUE_FILE.unlink()
        
        return True
    except json.JSONDecodeError as e:
        print(f"Error parsing job JSON: {e}", file=sys.stderr)
        # Remove invalid line
        with open(QUEUE_FILE, 'r') as f:
            lines = f.readlines()
        if len(lines) > 1:
            with open(QUEUE_FILE, 'w') as f:
                f.writelines(lines[1:])
        else:
            QUEUE_FILE.unlink()
        return False
    except Exception as e:
        print(f"Error processing file queue: {e}", file=sys.stderr)
        return False


def process_rabbitmq_queue():
    """Process jobs from RabbitMQ queue."""
    if not RABBITMQ_AVAILABLE:
        return False
    
    try:
        url = get_rabbitmq_url()
        params = pika.URLParameters(url)
        params.blocked_connection_timeout = 5
        
        connection = pika.BlockingConnection(params)
        channel = connection.channel()
        channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
        
        # Get one message (non-blocking)
        method, properties, body = channel.basic_get(queue=RABBITMQ_QUEUE, auto_ack=False)
        
        if method is None:
            connection.close()
            return False
        
        # Parse job
        job = json.loads(body)
        
        # Process job
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Processing sync job: {job.get('sync_type', 'unknown')}")
        result = process_sync_job(job)
        
        # Save result
        result_file = save_result(result)
        print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Sync complete. Result saved to: {result_file}")
        
        # Send notification
        send_notification(result, result_file)
        
        # Acknowledge message
        channel.basic_ack(delivery_tag=method.delivery_tag)
        connection.close()
        
        return True
    except (pika.exceptions.AMQPConnectionError,
            pika.exceptions.AMQPChannelError,
            ConnectionRefusedError,
            TimeoutError,
            OSError) as e:
        # RabbitMQ not available, fall back to file queue
        return False
    except Exception as e:
        print(f"Error processing RabbitMQ queue: {e}", file=sys.stderr)
        return False


def main():
    """Main worker loop."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Second Brain Sync Worker")
    parser.add_argument("--once", action="store_true", help="Process one job and exit")
    parser.add_argument("--queue-type", choices=["file", "rabbitmq", "auto"], default="auto",
                       help="Queue type to use (default: auto - tries RabbitMQ first)")
    args = parser.parse_args()
    
    queue_type = args.queue_type
    
    if args.once:
        # Process one job and exit
        if queue_type == "rabbitmq" or queue_type == "auto":
            if process_rabbitmq_queue():
                return
        if queue_type == "file" or queue_type == "auto":
            if process_file_queue():
                return
        # No jobs to process
        return
    
    # Continuous mode
    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] Starting Second Brain Sync Worker")
    print(f"Queue: {RABBITMQ_QUEUE if queue_type != 'file' else 'file'}")
    print(f"Queue file: {QUEUE_FILE}")
    print(f"Results dir: {RESULTS_DIR}")
    print("Waiting for jobs...")
    print()
    
    while True:
        try:
            # Try RabbitMQ first (if auto or rabbitmq)
            if queue_type == "rabbitmq" or queue_type == "auto":
                if process_rabbitmq_queue():
                    continue
            
            # Fall back to file queue
            if queue_type == "file" or queue_type == "auto":
                if process_file_queue():
                    continue
            
            # No jobs available, wait a bit
            time.sleep(5)
        except KeyboardInterrupt:
            print("\nShutting down worker...")
            break
        except Exception as e:
            print(f"Error in worker loop: {e}", file=sys.stderr)
            time.sleep(10)  # Wait before retrying


if __name__ == "__main__":
    main()

