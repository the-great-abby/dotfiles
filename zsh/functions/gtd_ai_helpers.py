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
                
                # Debug: Log response structure (only on first poll or every 5 polls to avoid spam, but show full info)
                poll_count = int((time.time() - start_poll_time) / poll_interval)
                if poll_count == 1 or poll_count % 5 == 0:
                    response_keys = list(status_data.keys()) if isinstance(status_data, dict) else "not a dict"
                    
                    # Get actual values (not just check existence)
                    response_status_val = status_data.get('status') if isinstance(status_data, dict) else None
                    has_choices = 'choices' in status_data if isinstance(status_data, dict) else False
                    choices_len = len(status_data.get('choices', [])) if isinstance(status_data, dict) and 'choices' in status_data else 0
                    
                    detail_status_val = None
                    detail_error_status_val = None
                    detail_keys = None
                    if isinstance(status_data.get('detail'), dict):
                        detail = status_data['detail']
                        detail_keys = list(detail.keys())
                        detail_status_val = detail.get('status')
                        # Also check detail.error.status (common Ollama Controller format)
                        if 'error' in detail and isinstance(detail['error'], dict):
                            detail_error_status_val = detail['error'].get('status')
                    
                    # Output the actual values - full details
                    print(f"  🔍 Status check response (full details):", file=sys.stderr, flush=True)
                    print(f"    All keys: {response_keys}", file=sys.stderr, flush=True)
                    
                    # Print the full status_data structure (formatted JSON for readability)
                    import json as json_module
                    try:
                        formatted_json = json_module.dumps(status_data, indent=2, default=str)
                        print(f"    Full response JSON:\n{formatted_json}", file=sys.stderr, flush=True)
                    except Exception as e:
                        # Fallback to str representation if JSON serialization fails
                        print(f"    Full response (str): {str(status_data)[:1000]}", file=sys.stderr, flush=True)
                        print(f"    (JSON formatting failed: {e})", file=sys.stderr, flush=True)
                    
                    print(f"    Summary:", file=sys.stderr, flush=True)
                    print(f"      - status field value: {repr(response_status_val)} (type: {type(response_status_val).__name__})", file=sys.stderr, flush=True)
                    print(f"      - has choices: {has_choices}, choices length: {choices_len}", file=sys.stderr, flush=True)
                    
                    # Check for usage field (indicator of completion)
                    has_usage = 'usage' in status_data if isinstance(status_data, dict) else False
                    if has_usage:
                        usage_val = status_data.get('usage', {})
                        print(f"      - has usage: True, usage: {usage_val}", file=sys.stderr, flush=True)
                    
                    # Check for request_id and status_url
                    if 'request_id' in status_data:
                        print(f"      - request_id: {status_data.get('request_id')}", file=sys.stderr, flush=True)
                    if 'status_url' in status_data:
                        print(f"      - status_url: {status_data.get('status_url')}", file=sys.stderr, flush=True)
                    
                    if detail_keys:
                        print(f"      - detail keys: {detail_keys}", file=sys.stderr, flush=True)
                        print(f"      - detail.status: {detail_status_val}", file=sys.stderr, flush=True)
                        if detail_error_status_val is not None:
                            print(f"      - detail.error.status: {detail_error_status_val} ⚠️ (this is the actual status!)", file=sys.stderr, flush=True)
                        # Print full detail content
                        if isinstance(status_data.get('detail'), dict):
                            detail_json = json_module.dumps(status_data['detail'], indent=4, default=str)
                            print(f"      - Full detail content:\n{detail_json}", file=sys.stderr, flush=True)
                
                # Check if we have choices FIRST - this is the definitive completion indicator
                # The response has choices but status might be None or missing
                # BUT: if choices exists but is empty (length 0), it's still processing!
                if 'choices' in status_data:
                    choices_list = status_data.get('choices', [])
                    if len(choices_list) > 0:
                        # Request is completed - we have choices!
                        # Log what we found
                        first_choice = choices_list[0] if choices_list else {}
                        message = first_choice.get('message', {})
                        delta = first_choice.get('delta', {})
                        content = message.get('content') or delta.get('content')
                        
                        # Log completion details
                        print(f"  ✅✅✅ REQUEST COMPLETED! ✅✅✅", file=sys.stderr, flush=True)
                        print(f"     Found {len(choices_list)} choice(s)", file=sys.stderr, flush=True)
                        print(f"     First choice keys: {list(first_choice.keys())}", file=sys.stderr, flush=True)
                        print(f"     Message keys: {list(message.keys())}", file=sys.stderr, flush=True)
                        if content:
                            content_preview = content[:100] + "..." if len(str(content)) > 100 else content
                            print(f"     Content preview: {content_preview}", file=sys.stderr, flush=True)
                        else:
                            print(f"     ⚠️  No content found in message (might be in different format)", file=sys.stderr, flush=True)
                            print(f"     First choice structure: {json_module.dumps(first_choice, indent=2, default=str)[:500]}", file=sys.stderr, flush=True)
                        
                        # Return the response even if content is empty (might be tool calls or other format)
                        # The caller can handle empty content appropriately
                        return (status_data, None)
                    
                    # If choices exists but is empty, check if this is actually a completed response
                    # Some responses might be complete but have no choices (error case or empty response)
                    # If we have the completion structure (id, object, created, model) but everything is null/empty,
                    # and we've been polling for a while, it might be a completed empty response
                    has_completion_structure = (
                        'id' in status_data and 
                        'object' in status_data and 
                        status_data.get('object') == 'chat.completion' and
                        'created' in status_data and
                        'model' in status_data
                    )
                    
                    if has_completion_structure:
                        # We have the OpenAI completion structure
                        # Check if all request tracking fields are null (suggests it's done)
                        tracking_fields_null = (
                            status_data.get('request_id') is None and
                            status_data.get('status_url') is None and
                            status_data.get('status') is None
                        )
                        
                        if tracking_fields_null:
                            # Has completion structure but all tracking is null
                            # This might be a completed response with no content
                            # But if we've been polling for less than 30 seconds, give it more time
                            # elapsed is already calculated at the top of the while loop
                            if elapsed < 30.0:
                                # Still early - probably still processing
                                if poll_count == 1 or poll_count % 5 == 0:
                                    print(f"  ⏳ Empty completion structure (polling {elapsed:.0f}s) - might still be processing, continuing...", file=sys.stderr, flush=True)
                                continue
                            else:
                                # Been polling for a while and we keep getting empty structure
                                # This might be a completed response with no content, or it's stuck
                                # Check if we also got a detail.error.status: processing recently
                                if poll_count == 1 or poll_count % 10 == 0:
                                    print(f"  ⚠️  Empty completion structure after {elapsed:.0f}s - might be stuck or completed with no content", file=sys.stderr, flush=True)
                                    print(f"  ⚠️  Returning empty response structure - caller should handle this", file=sys.stderr, flush=True)
                                # Return the empty structure - caller can decide if this is an error
                                return (status_data, None)
                    
                    # If choices exists but is empty, and it's not a clear completion structure, still processing
                    if poll_count == 1 or poll_count % 5 == 0:
                        print(f"  ⏳ Response has empty choices array - still processing, continuing to poll", file=sys.stderr, flush=True)
                    continue
                
                # Check for other completion indicators
                # Sometimes the response is complete but doesn't have choices in the expected format
                # Check for 'usage' field - this usually indicates completion
                if 'usage' in status_data and isinstance(status_data.get('usage'), dict):
                    # Usage field suggests the request completed (tokens were used)
                    # But if we don't have choices, it might be in a different format
                    if 'id' in status_data and 'model' in status_data:
                        # Has request metadata and usage - likely completed, even without choices
                        # Check if there's content elsewhere
                        if 'message' in status_data or 'content' in status_data:
                            if poll_count == 1 or poll_count % 5 == 0:
                                print(f"  ✅ Request completed (has usage and content, but no choices array)", file=sys.stderr, flush=True)
                            return (status_data, None)
                        # Has usage but no clear content - might be transitional
                        if poll_count == 1 or poll_count % 5 == 0:
                            print(f"  ⏳ Has usage field but no clear content - continuing to poll", file=sys.stderr, flush=True)
                        continue
                
                # Check status field (new Ollama Controller format)
                # HTTP 200 can now contain status information
                # IMPORTANT: Check status BEFORE checking for None
                response_status = status_data.get('status')
                
                # If status is explicitly the string 'completed', treat as completed
                # even if choices is empty (might be a different response format)
                if response_status == 'completed':
                    # Explicitly marked as completed
                    if poll_count == 1 or poll_count % 5 == 0:
                        print(f"  ✅ Status field is 'completed' - request finished", file=sys.stderr, flush=True)
                    # Return the response even if choices is empty (some formats might not use choices)
                    return (status_data, None)
                
                # If status field exists but value is None, check if we can infer from other fields
                if response_status is None:
                    # Check if status field key exists at all (even if value is None)
                    # If it exists, the response structure suggests it might be transitioning
                    if 'status' in status_data:
                        # Status field exists but is None - might be in transition
                        # Check other indicators
                        if 'request_id' in status_data and 'status_url' in status_data:
                            # Has request metadata but no status - likely still processing
                            response_status = 'processing'
                        else:
                            response_status = 'unknown'
                    else:
                        response_status = 'unknown'
                
                # Also check for nested status in detail (some formats might use this)
                # Ollama Controller often returns status inside detail
                if response_status == 'unknown' and isinstance(status_data, dict):
                    detail = status_data.get('detail', {})
                    if isinstance(detail, dict):
                        # Check for status in detail directly
                        detail_status = detail.get('status')
                        if detail_status is not None:
                            response_status = detail_status
                        # Check for status inside detail.error (Ollama Controller format)
                        # Structure: detail.error.status = 'queued' means it's processing, NOT an error
                        elif 'error' in detail and isinstance(detail['error'], dict):
                            error_obj = detail['error']
                            # Check if error.status indicates processing (not a real error)
                            error_status = error_obj.get('status')
                            error_code = error_obj.get('code', '')
                            error_type = error_obj.get('type', '')
                            
                            # Log when we detect processing status from detail.error
                            if poll_count == 1 or poll_count % 5 == 0:
                                print(f"  🔍 Found detail.error.status: {error_status}, code: {error_code}, type: {error_type}", file=sys.stderr, flush=True)
                            
                            if error_status in ['queued', 'processing']:
                                # This is a processing status, not an error - continue polling
                                response_status = error_status
                                if poll_count == 1 or poll_count % 5 == 0:
                                    print(f"  ✅ Detected {response_status} status from detail.error - will continue polling", file=sys.stderr, flush=True)
                            elif error_code == 'request_not_completed' and error_status:
                                # Request not completed yet - treat status from error object
                                response_status = error_status
                                if poll_count == 1 or poll_count % 5 == 0:
                                    print(f"  ✅ Detected {response_status} status from request_not_completed - will continue polling", file=sys.stderr, flush=True)
                            elif 'request_processing' in error_type:
                                # Type indicates processing - continue polling
                                if error_status:
                                    response_status = error_status
                                else:
                                    response_status = 'processing'
                                if poll_count == 1 or poll_count % 5 == 0:
                                    print(f"  ✅ Detected processing from request_processing type - will continue polling", file=sys.stderr, flush=True)
                            # Only treat as error if it's not a processing status
                            elif error_status not in ['queued', 'processing'] and error_status not in [None, '']:
                                response_status = 'error'
                                if poll_count == 1 or poll_count % 5 == 0:
                                    print(f"  ⚠️  Detected error status: {error_status}", file=sys.stderr, flush=True)
                
                # Note: We already checked for choices above (line 100-108), so if we get here,
                # choices either doesn't exist or is empty. No need to check again.
                
                # Check if completed via status
                if response_status == 'completed':
                    # Request completed - return the response (might have choices or be in detail)
                    # If choices are in detail, extract them
                    if isinstance(status_data.get('detail'), dict) and 'choices' in status_data['detail']:
                        return (status_data['detail'], None)
                    return (status_data, None)
                
                # Check if failed/error
                if response_status in ['failed', 'error']:
                    # Request failed - extract error message
                    error_msg = 'Request failed'
                    # Check detail.error.message first (most common format)
                    if isinstance(status_data.get('detail'), dict):
                        detail_error = status_data['detail'].get('error', {})
                        if isinstance(detail_error, dict):
                            error_msg = detail_error.get('message', 'Request failed')
                        elif isinstance(detail_error, str):
                            error_msg = detail_error
                    # Fallback to top-level error
                    if error_msg == 'Request failed' and 'error' in status_data:
                        top_error = status_data['error']
                        if isinstance(top_error, dict):
                            error_msg = top_error.get('message', 'Request failed')
                        else:
                            error_msg = str(top_error)
                    return (None, f"Request failed: {error_msg}")
                
                # Check if queued/processing
                if response_status in ['queued', 'processing']:
                    # Still processing - continue polling
                    # Log queue position if available
                    queue_pos = status_data.get('queue_position') or (status_data.get('detail', {}).get('queue_position') if isinstance(status_data.get('detail'), dict) else None)
                    # Also check detail.error for queue position
                    if queue_pos is None and isinstance(status_data.get('detail'), dict) and 'error' in status_data['detail']:
                        error_obj = status_data['detail']['error']
                        if isinstance(error_obj, dict):
                            queue_pos = error_obj.get('queue_position')
                    
                    if poll_count == 1 or poll_count % 5 == 0:
                        if queue_pos is not None:
                            print(f"  ⏳ Request {response_status} (position: {queue_pos}) - continuing to poll", file=sys.stderr, flush=True)
                        else:
                            print(f"  ⏳ Request {response_status} - continuing to poll", file=sys.stderr, flush=True)
                    continue
                
                # Check for error at top level (legacy format)
                if 'error' in status_data:
                    error_msg = status_data['error'].get('message', 'Request failed') if isinstance(status_data['error'], dict) else str(status_data['error'])
                    return (None, f"Request failed: {error_msg}")
                
                # Check for error in detail (but skip if it's a processing status)
                if isinstance(status_data.get('detail'), dict) and 'error' in status_data['detail']:
                    detail_error = status_data['detail']['error']
                    if isinstance(detail_error, dict):
                        # Check if this is actually a processing status, not a real error
                        error_status = detail_error.get('status')
                        error_code = detail_error.get('code', '')
                        error_type = detail_error.get('type', '')
                        
                        # If status is queued/processing or code is request_not_completed, continue polling
                        if error_status in ['queued', 'processing'] or error_code == 'request_not_completed' or 'request_processing' in error_type:
                            # This is a processing status message, not a real error - continue polling
                            queue_pos = status_data.get('queue_position') or detail_error.get('queue_position')
                            if queue_pos is not None and (poll_count == 1 or poll_count % 5 == 0):
                                print(f"  ⏳ Request queued/processing (position: {queue_pos if queue_pos else 'N/A'})", file=sys.stderr, flush=True)
                            continue
                        
                        # Otherwise, it's a real error
                        error_msg = detail_error.get('message', 'Request failed')
                        return (None, f"Request failed: {error_msg}")
                    else:
                        # Non-dict error - treat as real error
                        error_msg = str(detail_error)
                        return (None, f"Request failed: {error_msg}")
                
                # If we have detail but no recognized status, check if detail has status-like info
                if isinstance(status_data.get('detail'), dict):
                    detail = status_data['detail']
                    # Check for common patterns that indicate processing
                    if 'message' in detail or 'queue_position' in detail or 'elapsed_time' in detail:
                        # Looks like a status response, continue polling
                        if poll_count == 1 or poll_count % 10 == 0:
                            print(f"  ⏳ Request processing (detail has status info, continuing to poll)", file=sys.stderr, flush=True)
                        continue
                
                # If we have request_id and status_url but no clear status, it's likely still processing
                if 'request_id' in status_data or 'status_url' in status_data:
                    if poll_count == 1 or poll_count % 5 == 0:
                        print(f"  ⏳ Request metadata present (request_id/status_url) but no clear status - continuing to poll", file=sys.stderr, flush=True)
                    continue
                
                # If status field exists but is None (transitional state), continue polling
                if 'status' in status_data:
                    if poll_count == 1 or poll_count % 5 == 0:
                        print(f"  ⏳ Status field exists but value is None - likely transitional state, continuing to poll", file=sys.stderr, flush=True)
                    continue
                
                # If we got here and response_status is still 'unknown', and we don't have choices or other indicators,
                # it's likely still processing (better to poll than fail)
                if response_status == 'unknown':
                    if poll_count == 1 or poll_count % 5 == 0:
                        print(f"  ⏳ Status unknown but no error found - likely still processing, continuing to poll", file=sys.stderr, flush=True)
                    continue
                
                # Fallback: if we truly don't recognize the response, log it but continue polling
                # (better to keep polling than fail immediately)
                if poll_count == 1 or poll_count % 5 == 0:
                    print(f"  ⚠️  Unrecognized response format, but continuing to poll (response_status={response_status})", file=sys.stderr, flush=True)
                continue
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


def get_queue_status(
    request_id: str,
    base_url: str,
    timeout: float = 5.0
) -> Dict[str, Any]:
    """
    Get the status of a request in the Ollama Controller queue.
    
    Args:
        request_id: The request ID to check
        base_url: Base URL of the AI service (without /v1/chat/completions)
        timeout: Timeout for the status check in seconds (default: 5.0)
    
    Returns:
        Dictionary with status information:
        {
            "status": "queued" | "processing" | "completed" | "failed" | "not_found",
            "request_id": str,
            "queue_position": Optional[int],  # If available
            "elapsed_time": Optional[float],  # Seconds since request was submitted
            "message": str,  # Human-readable status message
            "error": Optional[str]  # Error message if failed
        }
    """
    status_url = f"{base_url}/v1/chat/completions/{request_id}"
    
    result = {
        "status": "unknown",
        "request_id": request_id,
        "queue_position": None,
        "elapsed_time": None,
        "message": "Unknown status",
        "error": None
    }
    
    try:
        status_req = urllib.request.Request(status_url)
        with urllib.request.urlopen(status_req, timeout=timeout) as status_response:
            status_data = json.loads(status_response.read().decode('utf-8'))
            
            # Request is completed (has choices)
            if 'choices' in status_data and len(status_data.get('choices', [])) > 0:
                result["status"] = "completed"
                result["message"] = "Request completed"
                return result
            
            # Request has error
            if 'error' in status_data:
                error_msg = status_data['error'].get('message', 'Request failed')
                result["status"] = "failed"
                result["error"] = error_msg
                result["message"] = f"Request failed: {error_msg}"
                return result
            
            # Otherwise, still queued/processing
            result["status"] = "processing"
            result["message"] = "Request is being processed"
            return result
            
    except urllib.error.HTTPError as e:
        if e.code == 400:
            # Request not completed yet - read error details for status
            try:
                error_data = json.loads(e.read().decode('utf-8'))
                error_detail = error_data.get('detail', {})
                if isinstance(error_detail, dict):
                    status = error_detail.get('status', 'unknown')
                    queue_position = error_detail.get('queue_position')
                    elapsed_time = error_detail.get('elapsed_time')
                    
                    if status in ['failed', 'error']:
                        error_msg = error_detail.get('error', {}).get('message', 'Request failed')
                        result["status"] = "failed"
                        result["error"] = error_msg
                        result["message"] = f"Request failed: {error_msg}"
                    elif status == 'queued':
                        result["status"] = "queued"
                        if queue_position is not None:
                            result["queue_position"] = queue_position
                            result["message"] = f"Request queued (position: {queue_position})"
                        else:
                            result["message"] = "Request queued"
                    elif status == 'processing':
                        result["status"] = "processing"
                        result["message"] = "Request is being processed"
                    else:
                        result["status"] = "processing"
                        result["message"] = "Request is being processed"
                    
                    if elapsed_time is not None:
                        result["elapsed_time"] = elapsed_time
                    elif queue_position is not None:
                        # Estimate elapsed time (rough estimate: 30 seconds per position)
                        result["elapsed_time"] = queue_position * 30.0
                    
                    return result
            except Exception:
                pass
            
            # Default: still processing
            result["status"] = "processing"
            result["message"] = "Request is being processed"
            return result
            
        elif e.code == 404:
            result["status"] = "not_found"
            result["message"] = "Request not found (may not be submitted yet)"
            return result
        else:
            result["status"] = "unknown"
            result["message"] = f"HTTP error {e.code}"
            return result
            
    except urllib.error.URLError as e:
        result["status"] = "error"
        result["error"] = str(e)
        result["message"] = f"Connection error: {e}"
        return result
    except Exception as e:
        result["status"] = "error"
        result["error"] = str(e)
        result["message"] = f"Error checking status: {e}"
        return result
    
    return result

