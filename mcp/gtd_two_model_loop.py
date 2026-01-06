#!/usr/bin/env python3
"""
Two-Model Loop System for Tool Calling and Deep Thinking

This module implements a ReAct-style loop where:
1. Tool Calling Model: Executes tools based on user requests
2. Deep Thinking Model: Processes tool results and decides if more processing is needed

The loop continues until the deep thinking model indicates processing is complete.
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple
from datetime import datetime

# Add paths for imports
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent
sys.path.insert(0, str(dotfiles_dir))

try:
    from mcp.gtd_deep_analysis_worker import call_deep_ai, DEEP_MODEL_URL, DEEP_MODEL_NAME
except ImportError:
    sys.path.insert(0, str(dotfiles_dir / "mcp"))
    from gtd_deep_analysis_worker import call_deep_ai, DEEP_MODEL_URL, DEEP_MODEL_NAME

# Import tool registry
try:
    from zsh.functions.gtd_tool_registry import execute_tool, get_tool_definitions
except ImportError:
    sys.path.insert(0, str(dotfiles_dir / "zsh" / "functions"))
    from gtd_tool_registry import execute_tool, get_tool_definitions

# Read tool calling model name from config
def get_tool_calling_model_name() -> str:
    """Get the tool calling model name from config."""
    config_paths = [
        Path.home() / ".gtd_config_ai",
        Path.home() / ".gtd_config",
        dotfiles_dir / "zsh" / ".gtd_config_ai",
        dotfiles_dir / "zsh" / ".gtd_config",
    ]
    
    # Check for mode-specific setting
    computer_mode = os.getenv("GTD_COMPUTER_MODE", "home").lower()
    mode_prefix = "WORK_" if computer_mode == "work" else "HOME_"
    
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        if value.startswith("${") and ":-" in value:
                            value = value.split(":-", 1)[1].rstrip("}")
                        
                        # Check mode-specific first
                        if key.startswith(mode_prefix):
                            mode_key = key[len(mode_prefix):]
                            if mode_key == "TOOL_CALLING_MODEL_NAME" and value:
                                return value
                        
                        # Then check general
                        if key == "TOOL_CALLING_MODEL_NAME" and value:
                            return value
                        if key == "HOME_TOOL_CALLING_MODEL_NAME" and value:
                            return value
                        if key == "GTD_TOOL_CALLING_MODEL_NAME" and value:
                            return value
    
    # Default
    return os.getenv("GTD_TOOL_CALLING_MODEL_NAME", "qwen2.5-7b-instruct")

TOOL_CALLING_MODEL_NAME = get_tool_calling_model_name()

# Use same URL as deep model (Ollama Controller or LM Studio)
TOOL_CALLING_MODEL_URL = DEEP_MODEL_URL


def warm_up_model(model_name: str, model_url: str, max_retries: int = 1, retry_delay: float = 0.5) -> bool:
    """
    Warm up a model by making a small synchronous test request.
    This is a quick check - if the model responds quickly, great. If not, we skip warm-up.
    NO ASYNC POLLING - we want this to be fast or skip it entirely.
    
    Args:
        model_name: Name of the model to warm up
        model_url: URL of the model endpoint
        max_retries: Maximum number of retry attempts (default: 1, just try once)
        retry_delay: Delay between retries in seconds (unused if max_retries=1)
    
    Returns:
        True if model responded quickly, False otherwise (warm-up is optional, so False is OK)
    """
    import urllib.request
    import urllib.error
    import time
    import sys
    
    # Small test payload to warm up the model
    test_payload = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": "ping"}
        ],
        "max_tokens": 1,  # Minimal tokens for fast response
        "temperature": 0.1
    }
    
    data = json.dumps(test_payload).encode('utf-8')
    
    for attempt in range(max_retries):
        try:
            req = urllib.request.Request(
                model_url,
                data=data,
                headers={'Content-Type': 'application/json'}
            )
            
            # Make a synchronous request with SHORT timeout (3 seconds)
            # If model is already loaded, it responds quickly
            # If not, we don't wait - just skip warm-up
            try:
                with urllib.request.urlopen(req, timeout=3) as response:
                    result_data = json.loads(response.read().decode('utf-8'))
                    
                    # Check if we got a successful response
                    if 'choices' in result_data and len(result_data.get('choices', [])) > 0:
                        # Model responded quickly - warm-up successful
                        return True
                    elif 'error' in result_data:
                        # Got an error response - model is loaded but error occurred
                        # This is OK for warm-up - model is ready to accept requests
                        return True
                    else:
                        # Unexpected response format - skip warm-up
                        return False
                        
            except urllib.error.HTTPError as e:
                # HTTP 202 (queued) or other errors - skip warm-up, don't poll
                # Warm-up is optional - if it gets queued, that's fine, we'll skip it
                return False
            except (urllib.error.URLError, OSError) as e:
                # Connection timeout or error - skip warm-up
                # This is expected if model isn't loaded yet - that's OK
                return False
                
        except json.JSONDecodeError:
            # Invalid JSON - skip warm-up
            return False
        except Exception:
            # Any other error - skip warm-up
            return False
    
    return False


def call_tool_calling_model(
    user_prompt: str,
    system_prompt: str,
    conversation_history: List[Dict[str, str]],
    tools: List[Dict[str, Any]],
    max_tokens: int = 2000,
    temperature: float = 0.7
) -> Tuple[Optional[Dict[str, Any]], Optional[List[Dict[str, Any]]], Optional[str]]:
    """
    Call the tool calling model to execute tools.
    
    Args:
        user_prompt: The user's question/prompt
        system_prompt: System prompt for the tool calling model
        conversation_history: Previous messages in the conversation
        tools: List of available tools
        max_tokens: Maximum tokens for response
        temperature: Temperature for generation
    
    Returns:
        Tuple of (response_message, tool_calls, error_string)
        - response_message: The model's response message dict
        - tool_calls: List of tool calls to execute (if any)
        - error_string: Error message if something went wrong
    """
    try:
        # Warm up the tool calling model (optional - quick synchronous check only)
        # Use environment variable to disable warm-up if needed: GTD_DISABLE_WARMUP=true
        if os.getenv("GTD_DISABLE_WARMUP", "false").lower() != "true":
            print(f"🔄 Warming up tool calling model: {TOOL_CALLING_MODEL_NAME}", file=sys.stderr, flush=True)
            warm_up_success = warm_up_model(TOOL_CALLING_MODEL_NAME, TOOL_CALLING_MODEL_URL, max_retries=1, retry_delay=0.5)
            if warm_up_success:
                print(f"✅ Tool calling model warmed up", file=sys.stderr, flush=True)
            # Don't print warning if warm-up fails - it's optional and silent failure is OK
        else:
            print(f"⏭️  Warm-up disabled via GTD_DISABLE_WARMUP", file=sys.stderr, flush=True)
        
        # Build messages for tool calling model
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        # Add conversation history
        messages.extend(conversation_history)
        
        # Add current user prompt
        messages.append({"role": "user", "content": user_prompt})
        
        # Build payload
        # Try "required" first - if backend doesn't support it, we'll fall back to "auto"
        # Some backends (like vLLM) don't support "required", so we need to handle that
        payload = {
            "model": TOOL_CALLING_MODEL_NAME,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens,
            "tools": tools
        }
        
        # Use "auto" for tool_choice - "required" causes HTTP 500 errors on Ollama Controller
        # The backend has a bug that triggers when using tool_choice="required"
        if tools:
            payload["tool_choice"] = "auto"
            print(f"  🔧 Tool choice: auto (backend doesn't support 'required')", file=sys.stderr, flush=True)
        else:
            payload["tool_choice"] = "auto"
        
        # Add priority (priority 30 for tool calls - high priority for interactive requests)
        priority = os.getenv("GTD_REQUEST_PRIORITY", "30")
        try:
            payload["priority"] = int(priority)
        except (ValueError, TypeError):
            payload["priority"] = 30  # Fallback to 30 if invalid
        
        # Log payload details for debugging
        tool_names_in_payload = []
        if "tools" in payload and payload["tools"]:
            for tool in payload["tools"]:
                if isinstance(tool, dict) and "function" in tool:
                    tool_names_in_payload.append(tool["function"].get("name", "unknown"))
            print(f"  📦 Payload includes {len(payload['tools'])} tool(s): {', '.join(tool_names_in_payload)}", file=sys.stderr, flush=True)
            print(f"  📦 Tool choice in payload: {payload.get('tool_choice', 'not set')}", file=sys.stderr, flush=True)
        else:
            print(f"  ⚠️  WARNING: No tools in payload!", file=sys.stderr, flush=True)
        
        # Make request (using async support if available)
        import urllib.request
        import urllib.error
        from gtd_ai_helpers import handle_ai_response, poll_async_response
        
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            TOOL_CALLING_MODEL_URL,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        timeout = 120
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                result_data = json.loads(response.read().decode('utf-8'))
                
                # Check if HTTP 200 response contains status information (new Ollama Controller format)
                # HTTP 200 can now contain status: "queued", "processing", "failed", or "completed"
                response_status = result_data.get('status', 'unknown')
                
                if response_status == 'queued' and result_data.get('request_id'):
                    # Request was queued - poll for completion
                    request_id = result_data['request_id']
                    base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                    result_data, poll_error = poll_async_response(
                        request_id,
                        base_url,
                        max_poll_time=300.0,
                        poll_interval=1.0
                    )
                    if poll_error:
                        return (None, None, f"Error polling async response: {poll_error}")
                    if not result_data:
                        return (None, None, "No response from async polling")
                elif response_status in ['failed', 'error']:
                    # Request failed - extract error message
                    error_msg = result_data.get('error', {}).get('message', 'Request failed') if isinstance(result_data.get('error'), dict) else str(result_data.get('error', 'Request failed'))
                    return (None, None, f"Tool calling model error: {error_msg}")
                elif response_status in ['processing']:
                    # Request is processing - should have request_id to poll
                    request_id = result_data.get('request_id')
                    if request_id:
                        base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                        result_data, poll_error = poll_async_response(
                            request_id,
                            base_url,
                            max_poll_time=300.0,
                            poll_interval=1.0
                        )
                        if poll_error:
                            return (None, None, f"Error polling async response: {poll_error}")
                        if not result_data:
                            return (None, None, "No response from async polling")
                    # If no request_id but status is processing, continue to handle_ai_response
                # If status is 'completed' or has 'choices', continue normally
        except urllib.error.HTTPError as e:
            # Handle HTTP 500 errors (backend might not support tool_choice=required)
            if e.code == 500:
                error_body = e.read().decode('utf-8')
                if 'tool_choice' in error_body.lower() or 'required' in error_body.lower() or 'ChatMessage' in error_body:
                    print(f"  ⚠️  Backend returned HTTP 500 (likely doesn't support tool_choice=required), retrying with auto", file=sys.stderr, flush=True)
                    payload["tool_choice"] = "auto"
                    # Retry the request
                    data = json.dumps(payload).encode('utf-8')
                    req = urllib.request.Request(
                        TOOL_CALLING_MODEL_URL,
                        data=data,
                        headers={'Content-Type': 'application/json'}
                    )
                    try:
                        with urllib.request.urlopen(req, timeout=timeout) as response:
                            result_data = json.loads(response.read().decode('utf-8'))
                    except urllib.error.HTTPError as retry_e:
                        if retry_e.code == 202:
                            request_id = retry_e.headers.get('X-Request-ID')
                            if request_id:
                                base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                                result_data, poll_error = poll_async_response(
                                    request_id,
                                    base_url,
                                    max_poll_time=300.0,
                                    poll_interval=1.0
                                )
                                if poll_error or not result_data:
                                    return (None, None, f"Error polling async response after retry: {poll_error}")
                            else:
                                return (None, None, "Async request queued but no request ID returned")
                        else:
                            return (None, None, f"HTTP error {retry_e.code} after retry: {retry_e.read().decode('utf-8')}")
                else:
                    return (None, None, f"HTTP error 500: {error_body}")
            # Handle async/queued responses (HTTP 202)
            elif e.code == 202:  # Accepted (queued)
                request_id = e.headers.get('X-Request-ID')
                if request_id:
                    base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                    result_data, poll_error = poll_async_response(
                        request_id,
                        base_url,
                        max_poll_time=300.0,
                        poll_interval=1.0
                    )
                    if poll_error:
                        return (None, None, f"Error polling async response: {poll_error}")
                    if not result_data:
                        return (None, None, "No response from async polling")
                else:
                    return (None, None, "Async request queued but no request ID returned")
            else:
                return (None, None, f"HTTP error {e.code}: {e.read().decode('utf-8')}")
        
        # Handle async/queued responses using the helper function
        # This handles responses that have status: 'queued' in the JSON body
        base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
        polled_result, poll_error = handle_ai_response(
            result_data,
            base_url,
            max_poll_time=300.0,
            poll_interval=1.0
        )
        
        if poll_error:
            return (None, None, f"Error handling async response: {poll_error}")
        
        if polled_result:
            result_data = polled_result
        
        # Extract response
        if 'error' in result_data:
            error_msg = result_data['error'].get('message', 'Unknown error')
            # If error is about tool_choice not being supported, try again with "auto"
            if 'tool_choice' in error_msg.lower() or 'required' in error_msg.lower():
                print(f"  ⚠️  Backend doesn't support tool_choice=required, retrying with auto", file=sys.stderr, flush=True)
                payload["tool_choice"] = "auto"
                # Retry the request
                data = json.dumps(payload).encode('utf-8')
                req = urllib.request.Request(
                    TOOL_CALLING_MODEL_URL,
                    data=data,
                    headers={'Content-Type': 'application/json'}
                )
                try:
                    with urllib.request.urlopen(req, timeout=timeout) as response:
                        result_data = json.loads(response.read().decode('utf-8'))
                except urllib.error.HTTPError as e:
                    if e.code == 202:
                        request_id = e.headers.get('X-Request-ID')
                        if request_id:
                            base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                            result_data, poll_error = poll_async_response(
                                request_id,
                                base_url,
                                max_poll_time=300.0,
                                poll_interval=1.0
                            )
                            if poll_error or not result_data:
                                return (None, None, f"Error polling async response after retry: {poll_error}")
                # Handle async responses again
                base_url = TOOL_CALLING_MODEL_URL.rsplit('/v1', 1)[0]
                polled_result, poll_error = handle_ai_response(
                    result_data,
                    base_url,
                    max_poll_time=300.0,
                    poll_interval=1.0
                )
                if poll_error:
                    return (None, None, f"Error handling async response after retry: {poll_error}")
                if polled_result:
                    result_data = polled_result
            else:
                return (None, None, f"Tool calling model error: {error_msg}")
        
        if 'choices' in result_data and len(result_data.get('choices', [])) > 0:
            message = result_data['choices'][0].get('message', {})
            tool_calls = message.get('tool_calls')
            
            # Log the response structure for debugging
            if tool_calls is None:
                print(f"  ⚠️  No 'tool_calls' key in message response", file=sys.stderr, flush=True)
                print(f"  📝 Message keys: {list(message.keys())}", file=sys.stderr, flush=True)
                content_preview = str(message.get('content', ''))[:200]
                print(f"  📝 Message content preview: {content_preview}", file=sys.stderr, flush=True)
                
                # Check if content contains JSON that looks like a tool call
                # Some models return tool calls as JSON strings in content instead of using tool_calls
                content = message.get('content', '').strip()
                if content:
                    try:
                        # Try to parse as JSON
                        parsed_content = json.loads(content)
                        # Check if it looks like a tool call (has 'name' or 'function_name' and 'arguments')
                        if isinstance(parsed_content, dict):
                            function_name = parsed_content.get('name') or parsed_content.get('function_name')
                            arguments = parsed_content.get('arguments') or parsed_content.get('args', {})
                            if function_name and arguments is not None:
                                print(f"  🔍 Detected tool call in content field: {function_name}", file=sys.stderr, flush=True)
                                # Convert to proper tool_calls format
                                tool_calls = [{
                                    "id": f"call_{0}",
                                    "type": "function",
                                    "function": {
                                        "name": function_name,
                                        "arguments": json.dumps(arguments) if not isinstance(arguments, str) else arguments
                                    }
                                }]
                                print(f"  ✅ Converted JSON tool call to proper format", file=sys.stderr, flush=True)
                                # IMPORTANT: Clear the content field so the deep thinking model doesn't see the JSON
                                # We'll add a note that tools were called instead
                                message = message.copy()  # Don't modify original
                                message['content'] = f"[Tool call to {function_name} detected and will be executed]"
                                print(f"  🧹 Cleaned message content to prevent confusion", file=sys.stderr, flush=True)
                    except (json.JSONDecodeError, KeyError, AttributeError):
                        # Not a JSON tool call, that's fine
                        pass
            elif tool_calls == []:
                print(f"  ⚠️  'tool_calls' is an empty list (model chose not to use tools)", file=sys.stderr, flush=True)
                print(f"  📝 Message content: {str(message.get('content', ''))[:200]}", file=sys.stderr, flush=True)
            else:
                print(f"  ✅ Found {len(tool_calls)} tool call(s)", file=sys.stderr, flush=True)
            
            return (message, tool_calls if tool_calls else None, None)
        else:
            # Log the response structure for debugging
            # Expected format: OpenAI-compatible response with choices array:
            # {
            #   "choices": [{
            #     "message": {
            #       "role": "assistant",
            #       "content": "...",
            #       "tool_calls": [...]  // optional
            #     }
            #   }]
            # }
            response_keys = list(result_data.keys()) if result_data else []
            choices_len = len(result_data.get('choices', [])) if result_data else 0
            
            # Show the actual response content to help debug
            import json as json_module
            response_preview = json_module.dumps(result_data, indent=2, default=str)[:500] if result_data else "None"
            
            error_msg = (
                f"No response from tool calling model\n"
                f"  Expected: OpenAI-compatible response with non-empty 'choices' array\n"
                f"  Got: response with keys {response_keys}, choices length: {choices_len}\n"
                f"  Response preview:\n{response_preview}"
            )
            print(f"  ⚠️  {error_msg}", file=sys.stderr, flush=True)
            return (None, None, error_msg)
            
    except Exception as e:
        return (None, None, f"Error calling tool calling model: {str(e)}")


def call_deep_thinking_model(
    user_prompt: str,
    system_prompt: str,
    conversation_history: List[Dict[str, str]],
    tool_results: List[Dict[str, Any]],
    max_tokens: int = 4000,
    temperature: float = 0.7,
    vector_context: str = ""
) -> Tuple[Optional[str], bool, Optional[str]]:
    """
    Call the deep thinking model to process tool results and decide if more processing is needed.
    
    Args:
        user_prompt: Original user question
        system_prompt: System prompt for the deep thinking model (includes continuation instructions)
        conversation_history: Previous messages
        tool_results: Results from tool execution (HIGH PRIORITY)
        max_tokens: Maximum tokens for response
        temperature: Temperature for generation
        vector_context: Optional vector search context (LOWER PRIORITY - supplementary only)
    
    Returns:
        Tuple of (response_text, needs_more_processing, error_string)
        - response_text: The model's response (or reason if needs_more_processing is True)
        - needs_more_processing: True if model wants to call more tools
        - error_string: Error message if something went wrong
    """
    try:
        # Warm up the deep thinking model (optional - quick synchronous check only)
        if os.getenv("GTD_DISABLE_WARMUP", "false").lower() != "true":
            print(f"🔄 Warming up deep thinking model: {DEEP_MODEL_NAME}", file=sys.stderr, flush=True)
            warm_up_success = warm_up_model(DEEP_MODEL_NAME, DEEP_MODEL_URL, max_retries=1, retry_delay=0.5)
            if warm_up_success:
                print(f"✅ Deep thinking model warmed up", file=sys.stderr, flush=True)
            # Don't print warning if warm-up fails - it's optional and silent failure is OK
        else:
            print(f"⏭️  Warm-up disabled via GTD_DISABLE_WARMUP", file=sys.stderr, flush=True)
        
        # Build messages (use direct HTTP request since call_deep_ai doesn't support messages)
        messages = []
        if system_prompt:
            messages.append({"role": "system", "content": system_prompt})
        
        messages.extend(conversation_history)
        messages.extend(tool_results)
        
        # Log what we're sending to the deep thinking model
        print(f"  📤 Sending to deep thinking model:", file=sys.stderr, flush=True)
        print(f"    - Conversation history: {len(conversation_history)} messages", file=sys.stderr, flush=True)
        print(f"    - Tool results: {len(tool_results)} results", file=sys.stderr, flush=True)
        for i, tr in enumerate(tool_results):
            content_len = len(str(tr.get('content', '')))
            print(f"      [{i+1}] {tr.get('name', 'unknown')}: {content_len} chars", file=sys.stderr, flush=True)
        
        # Add final instruction - make it conditional based on whether we have tool results
        if tool_results:
            # We have tool results - review them and decide if more tools are needed
            final_instruction = f"{user_prompt}\n\nIMPORTANT: Review the tool results above. If you need additional information or tools to fully answer, respond with ONLY the JSON: {{\"needs_more_processing\": true, \"reason\": \"why more tools are needed\"}}. Otherwise, provide your complete answer."
        else:
            # No tool results - this means tools need to be called
            final_instruction = f"{user_prompt}\n\nIMPORTANT: No tool results were provided above. This means tools need to be called to answer the user's question. Respond with ONLY this JSON: {{\"needs_more_processing\": true, \"reason\": \"Tools need to be called to retrieve the requested information\"}}."
        
        messages.append({
            "role": "user",
            "content": final_instruction
        })
        
        # Make direct HTTP request (like followup requests do)
        import urllib.request
        import urllib.error
        from gtd_ai_helpers import handle_ai_response
        
        payload = {
            "model": DEEP_MODEL_NAME,
            "messages": messages,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        
        # Add priority if available
        priority = os.getenv("GTD_REQUEST_PRIORITY")
        if priority:
            payload["priority"] = int(priority)
        
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            DEEP_MODEL_URL,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        timeout = 300
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                result_data = json.loads(response.read().decode('utf-8'))
                
                # Check if HTTP 200 response contains status information (new Ollama Controller format)
                # HTTP 200 can now contain status: "queued", "processing", "failed", or "completed"
                response_status = result_data.get('status', 'unknown')
                
                if response_status == 'queued' and result_data.get('request_id'):
                    # Request was queued - poll for completion
                    request_id = result_data['request_id']
                    base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                    from gtd_ai_helpers import poll_async_response
                    result_data, poll_error = poll_async_response(
                        request_id,
                        base_url,
                        max_poll_time=300.0,
                        poll_interval=1.0
                    )
                    if poll_error:
                        return (None, False, f"Error polling async response: {poll_error}")
                    if not result_data:
                        return (None, False, "No response from async polling")
                elif response_status in ['failed', 'error']:
                    # Request failed - extract error message
                    error_msg = result_data.get('error', {}).get('message', 'Request failed') if isinstance(result_data.get('error'), dict) else str(result_data.get('error', 'Request failed'))
                    return (None, False, f"Deep thinking model error: {error_msg}")
                elif response_status in ['processing']:
                    # Request is processing - should have request_id to poll
                    request_id = result_data.get('request_id')
                    if request_id:
                        base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                        from gtd_ai_helpers import poll_async_response
                        result_data, poll_error = poll_async_response(
                            request_id,
                            base_url,
                            max_poll_time=300.0,
                            poll_interval=1.0
                        )
                        if poll_error:
                            return (None, False, f"Error polling async response: {poll_error}")
                        if not result_data:
                            return (None, False, "No response from async polling")
                    # If no request_id but status is processing, continue to handle_ai_response
                # If status is 'completed' or has 'choices', continue normally
        except urllib.error.HTTPError as e:
            # Handle async/queued responses (HTTP 202)
            if e.code == 202:  # Accepted (queued)
                request_id = e.headers.get('X-Request-ID')
                if request_id:
                    base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
                    from gtd_ai_helpers import poll_async_response
                    result_data, poll_error = poll_async_response(
                        request_id,
                        base_url,
                        max_poll_time=300.0,
                        poll_interval=1.0
                    )
                    if poll_error:
                        return (None, False, f"Error polling async response: {poll_error}")
                    if not result_data:
                        return (None, False, "No response from async polling")
                else:
                    return (None, False, "Async request queued but no request ID returned")
            else:
                return (None, False, f"HTTP error {e.code}: {e.read().decode('utf-8')}")
        
        # Handle async/queued responses using the helper function
        # This handles responses that have status: 'queued' in the JSON body
        base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
        polled_result, poll_error = handle_ai_response(
            result_data,
            base_url,
            max_poll_time=300.0,
            poll_interval=1.0
        )
        
        if poll_error:
            return (None, False, f"Error handling async response: {poll_error}")
        
        if polled_result:
            result_data = polled_result
        
        # Extract response
        if 'error' in result_data:
            error_msg = result_data['error'].get('message', 'Unknown error')
            return (None, False, f"Deep thinking model error: {error_msg}")
        
        if 'choices' in result_data and len(result_data.get('choices', [])) > 0:
            message = result_data['choices'][0].get('message', {})
            response_text = message.get('content', '')
            
            # Check if response is a tool call JSON (shouldn't happen, but handle it)
            response_clean = response_text.strip()
            # Remove markdown code blocks if present
            if response_clean.startswith("```json"):
                response_clean = response_clean[7:]
            if response_clean.startswith("```"):
                response_clean = response_clean[3:]
            if response_clean.endswith("```"):
                response_clean = response_clean[:-3]
            response_clean = response_clean.strip()
            
            try:
                # Check if response looks like a tool call JSON
                parsed = json.loads(response_clean)
                if isinstance(parsed, dict):
                    # Check if it has tool call structure (name/function_name + arguments)
                    function_name = parsed.get('name') or parsed.get('function_name')
                    arguments = parsed.get('arguments') or parsed.get('args')
                    if function_name and arguments is not None:
                        # This is a tool call, not a final answer - we need more processing
                        print(f"  ⚠️  Deep thinking model returned tool call JSON instead of answer", file=sys.stderr, flush=True)
                        print(f"  📝 Tool call JSON: {response_clean[:200]}", file=sys.stderr, flush=True)
                        print(f"  🔄 Requesting more processing to execute tool: {function_name}", file=sys.stderr, flush=True)
                        # Convert to proper tool call format and add to conversation for next iteration
                        return (f"Tool call detected in response - need to execute {function_name}", True, None)
                    
                    # Check if it's a description of what should be done (like {"answer": "gtd_get_datetime(...)", "explanation": "..."})
                    # This suggests the model is describing actions instead of requesting them
                    answer_field = parsed.get('answer', '') or parsed.get('action', '') or parsed.get('function', '')
                    explanation_field = parsed.get('explanation', '')
                    if answer_field and ('gtd_' in str(answer_field) or '(' in str(answer_field) or 'function' in str(answer_field).lower()):
                        print(f"  ⚠️  Deep thinking model returned action description instead of answer", file=sys.stderr, flush=True)
                        print(f"  📝 Full response: {response_clean[:500]}", file=sys.stderr, flush=True)
                        print(f"  🔄 This looks like a description of what should be done - requesting more processing", file=sys.stderr, flush=True)
                        return (f"Model returned action description instead of answer - tools need to be called", True, None)
                    
                    # If we get JSON that doesn't have needs_more_processing and no tool results were provided,
                    # this is likely a description or incomplete response
                    if not parsed.get("needs_more_processing") and len(tool_results) == 0:
                        print(f"  ⚠️  Deep thinking model returned JSON without tool results", file=sys.stderr, flush=True)
                        print(f"  📝 Response: {response_clean[:500]}", file=sys.stderr, flush=True)
                        print(f"  🔄 No tool results provided - requesting more processing", file=sys.stderr, flush=True)
                        return (f"JSON response provided but no tool results - tools need to be called", True, None)
            except (json.JSONDecodeError, KeyError, AttributeError):
                # Not JSON or not a tool call, continue to check for needs_more_processing
                pass
            
            # Check if response indicates more processing is needed
            try:
                # Try to parse JSON response for needs_more_processing
                if response_clean.startswith("```json"):
                    response_clean = response_clean[7:]
                if response_clean.startswith("```"):
                    response_clean = response_clean[3:]
                if response_clean.endswith("```"):
                    response_clean = response_clean[:-3]
                response_clean = response_clean.strip()
                
                parsed = json.loads(response_clean)
                if isinstance(parsed, dict) and parsed.get("needs_more_processing") is True:
                    reason = parsed.get("reason", "Additional tools needed")
                    return (reason, True, None)
            except (json.JSONDecodeError, KeyError, AttributeError):
                # Not JSON, so it's a regular response - processing is complete
                pass
            
            # Regular response - processing complete
            return (response_text, False, None)
        else:
            return (None, False, "No response from deep thinking model")
        
    except Exception as e:
        return (None, False, f"Error calling deep thinking model: {str(e)}")


def process_with_two_model_loop(
    user_question: str,
    persona_system_prompt: str,
    user_name: str = "User",
    max_iterations: int = 10,
    vector_context: str = ""
) -> Tuple[Optional[str], Optional[str]]:
    """
    Process a user question using the two-model loop system.
    
    Args:
        user_question: The user's question
        persona_system_prompt: Base system prompt (from persona)
        user_name: User's name
        max_iterations: Maximum number of loop iterations
        vector_context: Optional vector search context (given lower priority than tool results)
    
    Returns:
        Tuple of (final_response, error_string)
    """
    # Get available tools (already in OpenAI-compatible format)
    try:
        tools_list = get_tool_definitions()
    except Exception as e:
        return (None, f"Error getting tool definitions: {str(e)}")
    
    # Build system prompts
    # Log available tools for debugging
    tool_names = [tool.get("function", {}).get("name", "unknown") for tool in tools_list]
    print(f"📋 Available tools: {', '.join(tool_names)}", file=sys.stderr, flush=True)
    
    # Log the persona system prompt being used
    print(f"📝 Persona system prompt (first 300 chars): {persona_system_prompt[:300]}...", file=sys.stderr, flush=True)
    
    # If debug mode, log full prompts
    if os.getenv("GTD_DEBUG_PROMPTS", "false").lower() == "true":
        print(f"\n{'='*80}", file=sys.stderr, flush=True)
        print(f"🔍 FULL PERSONA SYSTEM PROMPT:", file=sys.stderr, flush=True)
        print(f"{'='*80}", file=sys.stderr, flush=True)
        print(f"{persona_system_prompt}", file=sys.stderr, flush=True)
        print(f"{'='*80}\n", file=sys.stderr, flush=True)
    
    tool_calling_system_prompt = f"""You are a tool execution assistant helping {user_name}.

{persona_system_prompt}

CRITICAL INSTRUCTIONS - YOU MUST FOLLOW THESE RULES:

1. YOU MUST USE THE FUNCTION CALLING INTERFACE - The backend provides tools in the "tools" parameter. Use the "tool_calls" field in your response.
2. NEVER return tool calls as JSON strings in the "content" field - ALWAYS use the structured "tool_calls" field instead
3. When the user asks about logs, tasks, dates, or projects, you MUST call the appropriate tool(s) using function calling
4. For questions about multiple days of logs, call gtd_read_daily_log multiple times (once per day) or use gtd_get_datetime first to get the dates
5. If the user asks "what were the past X days", you MUST call gtd_read_daily_log for each of those days
6. After calling tools, your response will be processed by a thinking model that will use the tool results
7. DO NOT provide text responses in the "content" field - ONLY use "tool_calls" to call functions
8. The backend supports function calling - use it! Do NOT write JSON strings describing what you would do

AVAILABLE TOOLS (use function calling interface - tools are provided in the "tools" parameter):
- gtd_read_daily_log: Read daily log entries for a specific date (YYYY-MM-DD format). For multiple days, call this tool multiple times.
- gtd_get_datetime: Get date/time information. Use with relative dates like "3 days ago", "yesterday", "today" to calculate dates.
- gtd_list_tasks: List tasks with filters (context, energy, priority, project, status)
- gtd_create_task: Create new tasks
- gtd_list_projects: List projects

EXAMPLES:
- User: "What were the past 5 days of log entries?"
  → Use function calling to call gtd_get_datetime, then call gtd_read_daily_log 5 times (once for each date)
  
- User: "What tasks do I have?"
  → Use function calling to call gtd_list_tasks
  
- User: "What did I do yesterday?"
  → Use function calling to call gtd_get_datetime with "yesterday", then call gtd_read_daily_log with that date

REMEMBER: 
- Use the function calling interface (tool_calls field), NOT text JSON in content field
- The backend will execute your function calls automatically
- Do NOT write JSON strings - use the structured tool_calls format"""
    
    # Log the tool calling system prompt
    print(f"📝 Tool calling system prompt (first 500 chars):", file=sys.stderr, flush=True)
    print(f"{tool_calling_system_prompt[:500]}...", file=sys.stderr, flush=True)
    
    # If debug mode, log full prompt
    if os.getenv("GTD_DEBUG_PROMPTS", "false").lower() == "true":
        print(f"\n{'='*80}", file=sys.stderr, flush=True)
        print(f"🔍 FULL TOOL CALLING SYSTEM PROMPT:", file=sys.stderr, flush=True)
        print(f"{'='*80}", file=sys.stderr, flush=True)
        print(f"{tool_calling_system_prompt}", file=sys.stderr, flush=True)
        print(f"{'='*80}\n", file=sys.stderr, flush=True)
    
    # Build deep thinking system prompt with context weighting instructions
    context_weighting_note = ""
    if vector_context:
        context_weighting_note = """

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CONTEXT PRIORITY AND RELEVANCE:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

IMPORTANT: When multiple sources of context are provided, prioritize them as follows:

1. **TOOL RESULTS (HIGH PRIORITY - ~50% relevance)**: 
   - Tool execution results (from functions like gtd_read_daily_log, gtd_list_tasks, etc.) are the PRIMARY source of information
   - These results come from direct lookups and should be given HIGHEST PRIORITY
   - When tool results are available, they should be the PRIMARY basis for your answer
   - Tool results are more reliable and directly answer the user's question

2. **VECTOR SEARCH CONTEXT (LOWER PRIORITY - ~50% relevance)**: 
   - Vector search results (from knowledge base) are SECONDARY and should be used as SUPPLEMENTARY information
   - These results may be less directly relevant to the current question
   - Use vector context to provide additional context or background, but prioritize tool results when both are available
   - If tool results directly answer the question, vector context should be used only for additional insights

When both tool results and vector context are provided:
- Base your answer PRIMARILY on tool results
- Use vector context as supplementary information only
- If tool results directly answer the question, you may not need to reference vector context heavily
- If there's a conflict, trust tool results over vector context

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"""

    deep_thinking_system_prompt = f"""You are a thoughtful advisor helping {user_name}.

{persona_system_prompt}
{context_weighting_note}

You receive tool execution results and need to:
1. Analyze the tool results (if any were provided) - these are HIGH PRIORITY
2. Determine if additional tools are needed to fully answer the user's question
3. If NO tool results were provided, or if the tool results don't contain enough information, respond with ONLY this JSON: {{"needs_more_processing": true, "reason": "brief reason why more tools are needed"}}
4. If you have enough information from the tool results, provide a complete, helpful answer

The user's question: {user_question}

CRITICAL RULES: 
- If no tool results were provided above, you MUST return {{"needs_more_processing": true, "reason": "Tools need to be called"}}
- DO NOT describe what tools should be called - return needs_more_processing=true instead
- DO NOT return JSON like {{"answer": "gtd_get_datetime(...)", "explanation": "..."}} - return needs_more_processing=true
- Only return a complete answer if the tool results contain sufficient information to fully answer the question
- If tool results are empty, incomplete, or don't answer the question, return needs_more_processing=true
- NEVER describe actions - either request more processing or provide the final answer
- PRIORITIZE tool results over vector search context when both are available

After reviewing tool results, either:
- Return JSON with needs_more_processing=true if you need more tools/data OR if no tools were called yet
- Provide your complete answer ONLY if you have enough information from the tool results"""
    
    # Log the deep thinking system prompt
    print(f"📝 Deep thinking system prompt (first 500 chars):", file=sys.stderr, flush=True)
    print(f"{deep_thinking_system_prompt[:500]}...", file=sys.stderr, flush=True)
    
    # If debug mode, log full prompt
    if os.getenv("GTD_DEBUG_PROMPTS", "false").lower() == "true":
        print(f"\n{'='*80}", file=sys.stderr, flush=True)
        print(f"🔍 FULL DEEP THINKING SYSTEM PROMPT:", file=sys.stderr, flush=True)
        print(f"{'='*80}", file=sys.stderr, flush=True)
        print(f"{deep_thinking_system_prompt}", file=sys.stderr, flush=True)
        print(f"{'='*80}\n", file=sys.stderr, flush=True)
    
    # Conversation history
    conversation_history = []
    
    # Main loop
    for iteration in range(max_iterations):
        print(f"\n🔄 Two-model loop iteration {iteration + 1}/{max_iterations}", file=sys.stderr, flush=True)
        # Step 1: Call tool calling model
        user_prompt_for_this_iteration = user_question if iteration == 0 else "Additional tools needed based on previous results"
        print(f"📞 Calling tool calling model with prompt: {user_prompt_for_this_iteration[:100]}{'...' if len(user_prompt_for_this_iteration) > 100 else ''}", file=sys.stderr, flush=True)
        print(f"  📦 Passing {len(tools_list)} tool definition(s) to model", file=sys.stderr, flush=True)
        tool_response, tool_calls, error = call_tool_calling_model(
            user_prompt=user_prompt_for_this_iteration,
            system_prompt=tool_calling_system_prompt,
            conversation_history=conversation_history,
            tools=tools_list
        )
        
        if error:
            return (None, error)
        
        if not tool_response:
            return (None, "Tool calling model returned no response")
        
        # Log if no tool calls were made
        if not tool_calls:
            print(f"  ⚠️  WARNING: Tool calling model did not call any tools!", file=sys.stderr, flush=True)
            content_preview = str(tool_response.get('content', ''))[:200] if tool_response else 'None'
            print(f"  📝 Model response: {content_preview}", file=sys.stderr, flush=True)
            
            # Check if the content contains JSON that looks like a tool call we might have missed
            # This is a safety check in case our detection didn't work
            if tool_response:
                content = tool_response.get('content', '').strip()
                if content:
                    try:
                        parsed = json.loads(content)
                        if isinstance(parsed, dict):
                            function_name = parsed.get('name') or parsed.get('function_name')
                            if function_name:
                                print(f"  🔍 Found JSON tool call in content that wasn't converted: {function_name}", file=sys.stderr, flush=True)
                                print(f"  ⚠️  This suggests the detection/conversion logic needs to be checked", file=sys.stderr, flush=True)
                    except (json.JSONDecodeError, KeyError, AttributeError):
                        pass
        
        # Add tool calling model's response to history
        # If we cleaned the content (removed JSON), use the cleaned version
        conversation_history.append(tool_response)
        
        # Step 2: Execute tools if any
        tool_results = []
        if tool_calls:
            print(f"🔧 Executing {len(tool_calls)} tool call(s)...", file=sys.stderr, flush=True)
            for tool_call in tool_calls:
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
                
                # Log tool call
                args_str = json.dumps(args_dict) if args_dict else "{}"
                print(f"  📞 Tool: {function_name}({args_str[:200]}{'...' if len(args_str) > 200 else ''})", file=sys.stderr, flush=True)
                
                try:
                    tool_result = execute_tool(function_name, args_dict)
                    # Log tool result (truncate if very long)
                    result_preview = str(tool_result)[:300] + "..." if len(str(tool_result)) > 300 else str(tool_result)
                    print(f"  ✅ Result ({len(str(tool_result))} chars): {result_preview}", file=sys.stderr, flush=True)
                    tool_results.append({
                        "role": "tool",
                        "tool_call_id": tool_call_id,
                        "name": function_name,
                        "content": tool_result
                    })
                except Exception as e:
                    error_msg = f"Error executing tool: {str(e)}"
                    print(f"  ❌ Error: {error_msg}", file=sys.stderr, flush=True)
                    tool_results.append({
                        "role": "tool",
                        "tool_call_id": tool_call_id,
                        "name": function_name,
                        "content": error_msg
                    })
        else:
            print(f"  ℹ️  No tool calls in this iteration", file=sys.stderr, flush=True)
            # If no tools were called, we need to try again with the tool calling model
            # Don't call the deep thinking model yet - go back to tool calling model
            print(f"  🔄 No tools executed - will try tool calling model again on next iteration", file=sys.stderr, flush=True)
            # Add a note to conversation history that tools need to be called
            if iteration == 0:
                # First iteration - add the original tool calling model response
                conversation_history.append(tool_response)
            else:
                # Subsequent iteration - add a note that tools are still needed
                conversation_history.append({
                    "role": "assistant",
                    "content": "Tools need to be called to answer the user's question."
                })
            # Continue to next iteration to try tool calling model again
            continue
        
        # Step 3: Call deep thinking model (only if tools were executed)
        print(f"🧠 Calling deep thinking model with {len(tool_results)} tool result(s)...", file=sys.stderr, flush=True)
        if tool_results:
            for tr in tool_results:
                result_preview = str(tr.get('content', ''))[:200] + "..." if len(str(tr.get('content', ''))) > 200 else str(tr.get('content', ''))
                print(f"  📊 Tool result ({tr.get('name', 'unknown')}): {result_preview}", file=sys.stderr, flush=True)
        
        # Add tool results to history before calling deep thinking model
        conversation_history.extend(tool_results)
        
        thinking_response, needs_more, error = call_deep_thinking_model(
            user_prompt=user_question,
            system_prompt=deep_thinking_system_prompt,
            conversation_history=conversation_history,
            tool_results=tool_results
        )
        
        if error:
            return (None, error)
        
        # Step 4: Check if more processing is needed
        if needs_more:
            print(f"  🔄 More processing needed: {thinking_response or 'Additional tools needed'}", file=sys.stderr, flush=True)
            # Add thinking model's response (reason for more processing) to history
            conversation_history.append({
                "role": "assistant",
                "content": thinking_response or "Additional tools needed"
            })
            # Continue loop to call tool calling model again
            continue
        else:
            # Processing complete - return final response
            print(f"✅ Processing complete! Response length: {len(thinking_response or '')} chars", file=sys.stderr, flush=True)
            return (thinking_response, None)
    
    # Max iterations reached
    return (None, f"Maximum iterations ({max_iterations}) reached without completion")
