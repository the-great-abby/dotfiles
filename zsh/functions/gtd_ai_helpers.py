#!/usr/bin/env python3
"""
GTD AI Helpers - Shared utilities for AI backend interactions

This module provides shared functions for handling AI requests, including
async response polling for Ollama Controller.
"""

import json
import time
import sys
import urllib.request
import urllib.error
from typing import Dict, Any, Optional, Tuple


def poll_async_response(
    request_id: str,
    base_url: str,
    max_poll_time: float = 60.0,
    poll_interval: float = 0.5,
    timeout: float = 5.0
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Poll for completion of an async request from Ollama Controller.
    
    Args:
        request_id: The request ID from the queued response
        base_url: Base URL of the AI service (without /v1/chat/completions)
        max_poll_time: Maximum time to poll in seconds (default: 60)
        poll_interval: Time between polls in seconds (default: 0.5)
        timeout: Timeout for each status check in seconds (default: 5.0)
    
    Returns:
        Tuple of (result_dict, error_message):
        - If successful: (result_dict, None) where result_dict has 'choices'
        - If error: (None, error_message)
        - If timeout: (None, f"Request timed out after {max_poll_time}s")
    """
    # Use OpenAI-compatible status endpoint
    status_url = f"{base_url}/v1/chat/completions/{request_id}"
    
    start_poll_time = time.time()
    last_progress_update = 0.0
    progress_interval = 30.0  # Update progress every 30 seconds
    
    while time.time() - start_poll_time < max_poll_time:
        elapsed = time.time() - start_poll_time
        
        # Show progress every 30 seconds (so user knows it's still working)
        if elapsed - last_progress_update >= progress_interval:
            elapsed_min = int(elapsed // 60)
            elapsed_sec = int(elapsed % 60)
            print(f"⏳ Still waiting... ({elapsed_min}m {elapsed_sec}s elapsed)", file=sys.stderr, flush=True)
            last_progress_update = elapsed
        
        time.sleep(poll_interval)
        try:
            status_req = urllib.request.Request(status_url)
            with urllib.request.urlopen(status_req, timeout=timeout) as status_response:
                status_data = json.loads(status_response.read().decode('utf-8'))
                
                # Check if request is completed (has choices)
                if 'choices' in status_data and len(status_data.get('choices', [])) > 0:
                    # Request completed - return the OpenAI format response
                    return (status_data, None)
                elif 'error' in status_data:
                    error_msg = status_data['error'].get('message', 'Request failed')
                    return (None, f"Request failed: {error_msg}")
                # If still queued/processing, continue polling
        except urllib.error.HTTPError as e:
            if e.code == 400:
                # Request not completed yet (400 = "request_not_completed")
                # Read the error to check status
                try:
                    error_data = json.loads(e.read().decode('utf-8'))
                    error_detail = error_data.get('detail', {})
                    if isinstance(error_detail, dict):
                        status = error_detail.get('status', 'unknown')
                        if status in ['failed', 'error']:
                            error_msg = error_detail.get('error', {}).get('message', 'Request failed')
                            return (None, f"Request failed: {error_msg}")
                        # Otherwise continue polling (queued/processing)
                except Exception:
                    pass
                continue
            elif e.code == 404:
                # Request not found yet, continue polling
                continue
            else:
                # Other HTTP error - continue polling
                continue
        except urllib.error.URLError:
            # Continue polling on connection errors
            continue
        except Exception:
            # Continue polling on other errors
            continue
    
    # Timeout
    return (None, f"Request timed out after {max_poll_time}s")


def handle_ai_response(
    result: Dict[str, Any],
    base_url: str,
    max_poll_time: float = 60.0,
    poll_interval: float = 0.5,
    use_async: bool = False
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    """
    Handle an AI response, checking for async/queued responses and polling if needed.
    
    This is a convenience wrapper that:
    1. Checks if the response is a queued async response
    2. If queued, polls for completion (blocking) or submits to async manager (non-blocking)
    3. Returns the final result or error
    
    Args:
        result: The initial response from the AI service
        base_url: Base URL of the AI service (without /v1/chat/completions)
        max_poll_time: Maximum time to poll in seconds (default: 60)
        poll_interval: Time between polls in seconds (default: 0.5)
        use_async: If True, use non-blocking async manager instead of blocking poll
    
    Returns:
        Tuple of (result_dict, error_message):
        - If successful: (result_dict, None) where result_dict has 'choices'
        - If error: (None, error_message)
        - If queued and use_async=True: (request_id, None) - returns immediately
        - If queued and completed: (result_dict, None)
        - If queued and timeout: (None, timeout_error_message)
    """
    # Check if this is an async/queued response from Ollama Controller
    if result.get('status') == 'queued' and result.get('request_id'):
        if use_async:
            # Use non-blocking async manager - return request_id immediately
            # Background worker will handle polling
            request_id = result['request_id']
            return ({"request_id": request_id, "status": "queued"}, None)
        else:
            # Blocking poll (original behavior)
            request_id = result['request_id']
            return poll_async_response(request_id, base_url, max_poll_time, poll_interval)
    
    # Not a queued response - return as-is
    return (result, None)


def is_ollama_controller_url(url: str) -> bool:
    """
    Check if a URL points to Ollama Controller (port 31080).
    
    Args:
        url: The URL to check
    
    Returns:
        True if the URL is for Ollama Controller, False otherwise
    """
    return ":31080" in url or "31080" in url

