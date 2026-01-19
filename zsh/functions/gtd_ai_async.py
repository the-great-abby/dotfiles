#!/usr/bin/env python3
"""
GTD AI Async Request Manager - Non-blocking async request handling

This module provides non-blocking async request submission and background
polling for Ollama Controller requests. Instead of blocking for up to 30
minutes, requests are submitted and polled in a background loop.
"""

import json
import time
import os
import sys
import threading
from pathlib import Path
from typing import Dict, Any, Optional, Callable, Tuple
from datetime import datetime
import urllib.request
import urllib.error

# Storage for pending requests
PENDING_REQUESTS_FILE = Path.home() / ".gtd" / "pending_ai_requests.json"
RESULTS_DIR = Path.home() / ".gtd" / "ai_results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)

# In-memory cache for active requests
_pending_requests: Dict[str, Dict[str, Any]] = {}
_polling_thread: Optional[threading.Thread] = None
_polling_active = False
_lock = threading.Lock()


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
        # Try to get API key from environment variable
        api_key = os.getenv("OLLAMA_API_KEY")
        if api_key:
            headers['Authorization'] = f'Bearer {api_key}'
    
    return headers


def submit_ai_request_async(
    url: str,
    payload: Dict[str, Any],
    callback: Optional[Callable[[str, Optional[str]], None]] = None,
    max_poll_time: float = 3600.0,  # 60 minutes default
    poll_interval: float = 2.0,  # Check every 2 seconds
    result_file: Optional[str] = None
) -> Tuple[Optional[str], Optional[str]]:
    """
    Submit an AI request asynchronously and return immediately.
    
    This function:
    1. Makes the initial request
    2. If queued, stores the request_id and returns immediately
    3. If immediate response, returns the result
    4. Background worker polls for completion
    
    Args:
        url: The AI service URL (e.g., http://127.0.0.1:31080/v1/chat/completions)
        payload: Request payload (model, messages, etc.)
        callback: Optional callback function(result, error) called when complete
        max_poll_time: Maximum time to poll in seconds (default: 3600 = 60 min)
        poll_interval: Time between polls in seconds (default: 2.0)
        result_file: Optional file path to save result when complete
    
    Returns:
        Tuple of (request_id_or_result, error):
        - If immediate response: (result_dict as JSON string, None)
        - If queued: (request_id, None)
        - If error: (None, error_message)
    """
    global _pending_requests, _polling_thread, _polling_active
    
    try:
        # Log payload before sending (for debugging tool inclusion)
        log_file = Path.home() / ".gtd_logs" / "tool_calls.log"
        try:
            from datetime import datetime
            log_file.parent.mkdir(parents=True, exist_ok=True)
            with open(log_file, "a", encoding="utf-8") as f:
                f.write(f"[{datetime.now().isoformat()}] submit_ai_request_async - About to send request\n")
                f.write(f"  -> URL: {url}\n")
                if "tools" in payload:
                    tool_count = len(payload["tools"]) if isinstance(payload.get("tools"), list) else 0
                    tool_names = []
                    if isinstance(payload.get("tools"), list):
                        for tool in payload["tools"]:
                            if isinstance(tool, dict) and "function" in tool:
                                tool_names.append(tool["function"].get("name", "unknown"))
                    f.write(f"  -> ✅ Tools in payload before sending: {tool_count} tool(s): {', '.join(tool_names) if tool_names else 'N/A'}\n")
                    # Log first 500 chars of tools JSON for verification
                    tools_json = json.dumps(payload["tools"], indent=2)
                    f.write(f"  -> Tools JSON (first 500 chars): {tools_json[:500]}\n")
                else:
                    f.write(f"  -> ⚠️  NO TOOLS in payload before sending!\n")
        except Exception:
            pass  # Don't fail if logging fails
        
        # Make initial request
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            url,
            data=data,
            headers=_build_ollama_headers(url)
        )
        
        with urllib.request.urlopen(req, timeout=10) as response:
            result = json.loads(response.read().decode('utf-8'))
            
            # Check if immediate response (has choices)
            if 'choices' in result and len(result.get('choices', [])) > 0:
                # Immediate response - return it
                result_str = json.dumps(result)
                if result_file:
                    _save_result(result_file, result_str, None)
                if callback:
                    callback(result_str, None)
                return (result_str, None)
            
            # Check if queued
            if result.get('status') == 'queued' and result.get('request_id'):
                request_id = result['request_id']
                base_url = url.rsplit('/v1', 1)[0]
                
                # Store pending request
                # Note: processing_started_at will be set when we first get a response from the
                # status endpoint (even if HTTP 400/404, meaning the request exists in the system).
                # This ensures the timeout timer starts from when processing begins (or when the
                # request is known to exist in the system), not from when it was first submitted
                # to the queue. This prevents timeouts from expiring while requests are still
                # waiting in the queue.
                with _lock:
                    _pending_requests[request_id] = {
                        'request_id': request_id,
                        'base_url': base_url,
                        'url': url,
                        'payload': payload,
                        'callback': callback,
                        'result_file': result_file,
                        'max_poll_time': max_poll_time,
                        'poll_interval': poll_interval,
                        'submitted_at': time.time(),
                        'processing_started_at': None,  # Will be set when processing starts
                        'last_poll': time.time()
                    }
                    _save_pending_requests()
                
                # Start polling thread if not running
                _ensure_polling_thread()
                
                return (request_id, None)
            
            # Error response
            error_msg = result.get('error', {}).get('message', 'Unknown error')
            if callback:
                callback(None, error_msg)
            return (None, error_msg)
            
    except urllib.error.HTTPError as e:
        error_msg = f"HTTP {e.code}: {e.reason}"
        if callback:
            callback(None, error_msg)
        return (None, error_msg)
    except Exception as e:
        error_msg = str(e)
        if callback:
            callback(None, error_msg)
        return (None, error_msg)


def check_request_status(request_id: str) -> Tuple[Optional[Dict[str, Any]], Optional[str], bool]:
    """
    Check the status of a single request (non-blocking).
    
    Args:
        request_id: The request ID to check
    
    Returns:
        Tuple of (result_dict, error_message, is_complete):
        - If complete: (result_dict, None, True)
        - If error: (None, error_message, True)
        - If still pending: (None, None, False)
    """
    with _lock:
        if request_id not in _pending_requests:
            return (None, "Request not found", True)
        
        request_info = _pending_requests[request_id]
    
    base_url = request_info['base_url']
    status_url = f"{base_url}/v1/chat/completions/{request_id}"
    
    try:
        status_req = urllib.request.Request(status_url, headers=_build_ollama_headers(status_url))
        with urllib.request.urlopen(status_req, timeout=5) as status_response:
            status_data = json.loads(status_response.read().decode('utf-8'))
            
            # Request exists in system - mark processing as started if not already set
            # This means the timeout timer starts from when processing begins, not submission
            with _lock:
                if request_id in _pending_requests and _pending_requests[request_id].get('processing_started_at') is None:
                    _pending_requests[request_id]['processing_started_at'] = time.time()
            
            # Check if completed
            if 'choices' in status_data and len(status_data.get('choices', [])) > 0:
                # Completed - remove from pending and return
                with _lock:
                    _pending_requests.pop(request_id, None)
                    _save_pending_requests()
                
                # Save result if requested
                if request_info.get('result_file'):
                    _save_result(request_info['result_file'], json.dumps(status_data), None)
                
                # Call callback if provided
                if request_info.get('callback'):
                    request_info['callback'](json.dumps(status_data), None)
                
                return (status_data, None, True)
            
            # Check for error
            if 'error' in status_data:
                error_msg = status_data['error'].get('message', 'Request failed')
                with _lock:
                    _pending_requests.pop(request_id, None)
                    _save_pending_requests()
                
                if request_info.get('callback'):
                    request_info['callback'](None, error_msg)
                
                return (None, error_msg, True)
            
            # Still pending
            with _lock:
                _pending_requests[request_id]['last_poll'] = time.time()
            return (None, None, False)
            
    except urllib.error.HTTPError as e:
        if e.code in [400, 404]:
            # Request exists in system (HTTP 400/404 means queued/processing, not missing)
            # Mark processing as started if not already set - timeout starts from here
            with _lock:
                if request_id in _pending_requests and _pending_requests[request_id].get('processing_started_at') is None:
                    _pending_requests[request_id]['processing_started_at'] = time.time()
                _pending_requests[request_id]['last_poll'] = time.time()
            return (None, None, False)
        else:
            error_msg = f"HTTP {e.code}: {e.reason}"
            with _lock:
                _pending_requests.pop(request_id, None)
                _save_pending_requests()
            
            if request_info.get('callback'):
                request_info['callback'](None, error_msg)
            
            return (None, error_msg, True)
    except Exception as e:
        # Continue polling on errors
        # Don't set processing_started_at here - we don't know if processing has started
        # Only set it when we get a response from the status endpoint
        with _lock:
            _pending_requests[request_id]['last_poll'] = time.time()
        return (None, None, False)


def _poll_pending_requests():
    """Background worker that polls all pending requests."""
    global _polling_active
    
    _polling_active = True
    
    while _polling_active:
        try:
            # Get copy of pending requests
            with _lock:
                pending = list(_pending_requests.keys())
            
            if not pending:
                time.sleep(1)  # No requests, sleep briefly
                continue
            
            # Check each pending request
            for request_id in pending:
                with _lock:
                    if request_id not in _pending_requests:
                        continue
                    request_info = _pending_requests[request_id]
                
                # Check if expired
                # Use processing_started_at if set (timeout starts when processing begins),
                # otherwise fall back to submitted_at (for backward compatibility)
                timeout_start_time = request_info.get('processing_started_at') or request_info['submitted_at']
                elapsed = time.time() - timeout_start_time
                if elapsed > request_info['max_poll_time']:
                    # Timeout - remove and call callback with error
                    with _lock:
                        _pending_requests.pop(request_id, None)
                        _save_pending_requests()
                    
                    # Format timeout message to show when timer started
                    timeout_source = "processing start" if request_info.get('processing_started_at') else "submission"
                    error_msg = f"Request timed out after {request_info['max_poll_time']}s (timer started from {timeout_source})"
                    if request_info.get('callback'):
                        request_info['callback'](None, error_msg)
                    continue
                
                # Check status (non-blocking)
                result, error, is_complete = check_request_status(request_id)
                
                if is_complete:
                    # Request completed or errored - already handled in check_request_status
                    continue
            
            # Sleep before next poll cycle
            time.sleep(0.5)  # Check every 0.5 seconds
            
        except Exception as e:
            print(f"Error in polling loop: {e}", file=sys.stderr)
            time.sleep(1)


def _ensure_polling_thread():
    """Ensure the polling thread is running."""
    global _polling_thread, _polling_active
    
    if _polling_thread is None or not _polling_thread.is_alive():
        _polling_thread = threading.Thread(target=_poll_pending_requests, daemon=True)
        _polling_thread.start()


def stop_polling():
    """Stop the background polling thread."""
    global _polling_active
    _polling_active = False


def get_pending_requests() -> Dict[str, Dict[str, Any]]:
    """Get a copy of all pending requests."""
    with _lock:
        return dict(_pending_requests)


def _save_pending_requests():
    """Save pending requests to file."""
    try:
        PENDING_REQUESTS_FILE.parent.mkdir(parents=True, exist_ok=True)
        with open(PENDING_REQUESTS_FILE, 'w') as f:
            # Only save essential info (not callbacks)
            save_data = {}
            for req_id, req_info in _pending_requests.items():
                save_data[req_id] = {
                    k: v for k, v in req_info.items()
                    if k != 'callback'  # Can't serialize callbacks
                }
            json.dump(save_data, f, indent=2)
    except Exception as e:
        print(f"Error saving pending requests: {e}", file=sys.stderr)


def _load_pending_requests():
    """Load pending requests from file."""
    global _pending_requests
    
    if not PENDING_REQUESTS_FILE.exists():
        return
    
    try:
        with open(PENDING_REQUESTS_FILE, 'r') as f:
            _pending_requests = json.load(f)
        
        # Start polling if there are pending requests
        if _pending_requests:
            _ensure_polling_thread()
    except Exception as e:
        print(f"Error loading pending requests: {e}", file=sys.stderr)


def _save_result(result_file: str, result: str, error: Optional[str]):
    """Save result to file."""
    try:
        result_path = RESULTS_DIR / result_file
        result_path.parent.mkdir(parents=True, exist_ok=True)
        with open(result_path, 'w') as f:
            if error:
                json.dump({'error': error}, f)
            else:
                json.dump(json.loads(result), f, indent=2)
    except Exception as e:
        print(f"Error saving result: {e}", file=sys.stderr)


# Load pending requests on import
_load_pending_requests()
_ensure_polling_thread()

