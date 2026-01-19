#!/usr/bin/env python3
"""
Claude Ollama Bridge - Smart router between Ollama (local) and Claude API

Supports two modes:
1. "ollama-only": All requests go to Ollama (local, free, instant)
2. "hybrid": Smart routing - simple tasks to Ollama, complex tasks to Claude (API)

This enables flexible AI processing that can switch between local-only and hybrid setups.
"""

import json
import os
import sys
import urllib.request
import urllib.error
import time
from pathlib import Path
from typing import Dict, Any, Optional, Tuple
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from zsh.functions.gtd_ai_helpers import handle_ai_response
except ImportError:
    # Fallback: basic async handling
    def handle_ai_response(response, base_url, max_poll_time=30):
        """Fallback async response handler"""
        if response.get("status") == "queued":
            request_id = response.get("request_id")
            # Could poll here, but returning for now
            return response, None
        return response, None


class AIMode:
    """Constants for AI mode"""
    OLLAMA_ONLY = "ollama-only"
    HYBRID = "hybrid"


class RouteComplexity:
    """Complexity levels for routing decisions"""
    SIMPLE = 0.2      # Ollama handles well
    MODERATE = 0.5    # Could go either way
    COMPLEX = 0.8     # Needs Claude


class SmartAIRouter:
    """Routes requests between Ollama and Claude based on mode and complexity"""

    def __init__(self):
        """Initialize router with configuration"""
        self.config = self._load_config()
        self.mode = self.config.get("mode", AIMode.HYBRID)
        self.ollama_url = self.config.get("ollama_url", "http://127.0.0.1:31080/v1/chat/completions")
        self.ollama_timeout = int(self.config.get("ollama_timeout", 30))
        self.anthropic_api_key = self.config.get("anthropic_api_key", "")
        self.use_claude = self.mode == AIMode.HYBRID and self.anthropic_api_key
        # Claude model name - try older models first (more widely available)
        # Then newer models. See: https://platform.claude.com/docs/en/about-claude/models/overview
        self.claude_model = self.config.get("claude_model", "claude-3-haiku-20240307")
        self.claude_model_fallbacks = [
            # Start with oldest/most basic models (most likely to work)
            "claude-3-haiku-20240307",        # Oldest Haiku (most widely available)
            "claude-3-sonnet-20240229",      # Older Sonnet
            "claude-3-opus-20240229",        # Older Opus
            # Then 3.5 series
            "claude-3-5-sonnet-20240620",    # 3.5 Sonnet (older)
            "claude-3-5-sonnet-20241022",    # 3.5 Sonnet (newer)
            # Then 3.7 and 4 series
            "claude-3-7-sonnet-20250219",    # 3.7 Sonnet
            "claude-sonnet-4-20250514",      # Sonnet 4
            # Finally try 4.5 series (may require higher tier)
            "claude-sonnet-4-5",             # Alias (auto-updates)
            "claude-sonnet-4-5-20250929",    # Specific version
            "claude-haiku-4-5",              # Haiku 4.5 alias
            "claude-haiku-4-5-20251001",     # Haiku 4.5 specific
        ]

        # Request tracking
        self.last_ollama_call = None
        self.last_claude_call = None

    def _load_config(self) -> Dict[str, Any]:
        """Load configuration from environment and config files"""
        config = {}

        # Load from .gtd_config_ai FIRST
        config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_ai"
        if not config_file.exists():
            config_file = Path.home() / ".gtd_config_ai"

        if config_file.exists():
            with open(config_file) as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        # Remove inline comments
                        if '#' in line:
                            line = line.split('#')[0].strip()

                        # Handle bash variable syntax like ${VAR:-default}
                        if line.startswith('GTD_AI_MODE='):
                            # Parse value, stripping quotes and bash syntax
                            raw_value = line.split('=', 1)[1]
                            # Extract from ${VAR:-default} or "value" or value
                            value = self._parse_bash_value(raw_value)
                            config["mode"] = value or "hybrid"
                        elif line.startswith('OLLAMA_URL='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            config["ollama_url"] = value or "http://127.0.0.1:31080/v1/chat/completions"
                        elif line.startswith('ANTHROPIC_API_KEY='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            if value and value != "-":
                                config["anthropic_api_key"] = value
                        elif line.startswith('CLAUDE_MODEL=') or line.startswith('ANTHROPIC_MODEL='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            if value:
                                config["claude_model"] = value

        # Set defaults if not found
        if "mode" not in config:
            config["mode"] = os.getenv("GTD_AI_MODE", "hybrid")
        if "ollama_url" not in config:
            config["ollama_url"] = os.getenv("OLLAMA_URL", "http://127.0.0.1:31080/v1/chat/completions")
        if "claude_model" not in config:
            config["claude_model"] = os.getenv("CLAUDE_MODEL", os.getenv("ANTHROPIC_MODEL", "claude-3-haiku-20240307"))

        # Load API key from multiple sources (in order of priority)
        # 1. Environment variable (highest priority) - but only if it's valid
        if "ANTHROPIC_API_KEY" in os.environ:
            env_key = os.getenv("ANTHROPIC_API_KEY", "").strip()
            if env_key and env_key.startswith("sk-"):
                config["anthropic_api_key"] = env_key
        # 2. Try reading from dedicated API key file
        if not config.get("anthropic_api_key"):
            api_key_file = Path.home() / "code" / "dotfiles" / "zsh" / "ANTHROPIC_API_KEY"
            if not api_key_file.exists():
                api_key_file = Path.home() / "ANTHROPIC_API_KEY"

            if api_key_file.exists():
                try:
                    with open(api_key_file) as f:
                        api_key = f.read().strip()
                        if api_key and api_key.startswith("sk-"):
                            config["anthropic_api_key"] = api_key
                except Exception as e:
                    # Silently fail if we can't read the file
                    pass

        return config

    def _parse_bash_value(self, raw_value: str) -> str:
        """Parse bash variable syntax like ${VAR:-default} or "value"

        Examples:
            "${GTD_AI_MODE:-hybrid}" -> "hybrid"
            "value" -> "value"
            'value' -> "value"
            http://url -> "http://url"
        """
        raw_value = raw_value.strip()

        # First, strip outer quotes if present
        if (raw_value.startswith('"') and raw_value.endswith('"')) or \
           (raw_value.startswith("'") and raw_value.endswith("'")):
            raw_value = raw_value[1:-1]

        # Now handle ${VAR:-default} format
        if raw_value.startswith('${') and ':-' in raw_value:
            # Extract the default value after :-
            default_part = raw_value.split(':-', 1)[1]
            # Remove trailing }
            value = default_part.rstrip('}').strip('"').strip("'")
            return value

        # Return as-is
        return raw_value

    def route_request(
        self,
        request_type: str,
        content: str,
        persona: Optional[str] = None,
        complexity: Optional[float] = None,
        context: Optional[Dict[str, Any]] = None,
    ) -> Tuple[Dict[str, Any], Optional[str]]:
        """
        Route a request to Ollama or Claude based on mode and complexity.

        Args:
            request_type: Type of request ("persona", "suggest", "categorize", "analyze", etc.)
            content: The content/prompt to process
            persona: Persona name if applicable
            complexity: Estimated complexity (0.0-1.0). If None, auto-detect.
            context: Additional context for routing decisions

        Returns:
            Tuple of (result_dict, error_message)
            - result_dict contains response or routing info
            - error_message is None if successful, error string otherwise
        """

        # Auto-detect complexity if not provided
        if complexity is None:
            complexity = self._estimate_complexity(request_type, content, persona)

        # Determine target based on mode
        if self.mode == AIMode.OLLAMA_ONLY:
            target = "ollama"
        elif self.mode == AIMode.HYBRID:
            target = self._choose_target(request_type, complexity)
        else:
            return {}, f"Unknown mode: {self.mode}"

        # Execute on target
        result = None
        error = None

        if target == "ollama":
            result, error = self._call_ollama(request_type, content, persona, context)
        elif target == "claude":
            result, error = self._call_claude(request_type, content, persona, context)

        if error and self.mode == AIMode.HYBRID and target == "claude":
            # Fallback to Ollama if Claude fails
            result, error = self._call_ollama(request_type, content, persona, context)
            if result:
                result["_fallback_from"] = "claude"

        return result or {}, error

    def _estimate_complexity(
        self,
        request_type: str,
        content: str,
        persona: Optional[str] = None,
    ) -> float:
        """Estimate complexity of a request (0.0 = simple, 1.0 = complex)"""

        # Request type complexity baseline
        type_complexity = {
            "persona_response": 0.2,      # Usually simple
            "task_categorize": 0.1,       # Classification
            "task_suggest": 0.3,          # Template-based
            "similarity_search": 0.1,     # Embedding-based
            "quick_advice": 0.3,          # Relatively simple
            "analyze_daily_log": 0.6,     # More complex analysis
            "weekly_review": 0.8,         # Deep analysis
            "strategy_planning": 0.9,     # Very complex reasoning
            "pattern_analysis": 0.7,      # Complex patterns
        }

        base_complexity = type_complexity.get(request_type, 0.5)

        # Adjust based on content length and complexity indicators
        content_length_score = min(len(content) / 1000, 0.3)  # Max +0.3 for long content

        # Check for complexity indicators
        complexity_keywords = [
            "why", "analyze", "strategic", "pattern", "synthesis",
            "integrate", "connection", "framework", "approach",
        ]
        has_complexity_markers = any(kw in content.lower() for kw in complexity_keywords)
        complexity_boost = 0.2 if has_complexity_markers else 0

        final_complexity = min(1.0, base_complexity + content_length_score + complexity_boost)
        return final_complexity

    def _choose_target(self, request_type: str, complexity: float) -> str:
        """Choose between Ollama and Claude based on complexity"""

        # These always go to Ollama (too simple for Claude)
        always_ollama = {
            "task_categorize",
            "similarity_search",
            "persona_response",
            "quick_suggestion",
        }

        if request_type in always_ollama:
            return "ollama"

        # These always go to Claude if available (too complex for Ollama)
        always_claude = {
            "strategy_planning",
            "weekly_review",
            "pattern_analysis_complex",
        }

        if request_type in always_claude and self.use_claude:
            return "claude"

        # For moderate tasks, use complexity score
        if complexity < RouteComplexity.MODERATE:
            return "ollama"
        elif complexity >= RouteComplexity.MODERATE and self.use_claude:
            return "claude"
        else:
            return "ollama"  # Fallback to Ollama if Claude not available

    def _call_ollama(
        self,
        request_type: str,
        content: str,
        persona: Optional[str],
        context: Optional[Dict[str, Any]],
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Call Ollama for a request"""

        try:
            self.last_ollama_call = datetime.now()

            # Build the prompt based on request type
            prompt = self._build_prompt(request_type, content, persona, context)

            # Prepare request
            body = json.dumps({
                "model": context.get("model", "gemma3:1b") if context else "gemma3:1b",
                "messages": [
                    {"role": "system", "content": prompt.get("system", "You are a helpful assistant.")},
                    {"role": "user", "content": prompt.get("user", content)},
                ],
                "temperature": context.get("temperature", 0.7) if context else 0.7,
                "max_tokens": context.get("max_tokens", 500) if context else 500,
            }).encode("utf-8")

            # Make request
            req = urllib.request.Request(
                self.ollama_url,
                data=body,
                headers={"Content-Type": "application/json"},
            )

            with urllib.request.urlopen(req, timeout=self.ollama_timeout) as response:
                result = json.loads(response.read().decode("utf-8"))

            # Handle async responses
            if result.get("status") == "queued":
                base_url = self.ollama_url.rsplit('/v1', 1)[0]
                polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=self.ollama_timeout)
                if polled_result:
                    result = polled_result
                if poll_error:
                    return None, f"Ollama polling error: {poll_error}"

            # Extract response
            if "choices" in result and result["choices"]:
                response_text = result["choices"][0]["message"]["content"]
                return {
                    "source": "ollama",
                    "response": response_text,
                    "request_type": request_type,
                    "timestamp": datetime.now().isoformat(),
                }, None
            else:
                return None, "No response from Ollama"

        except urllib.error.URLError as e:
            return None, f"Ollama connection error: {e}"
        except json.JSONDecodeError as e:
            return None, f"Ollama response parse error: {e}"
        except Exception as e:
            return None, f"Ollama error: {e}"

    def _call_claude(
        self,
        request_type: str,
        content: str,
        persona: Optional[str],
        context: Optional[Dict[str, Any]],
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Call Claude API for a request with GTD tool support"""

        if not self.anthropic_api_key:
            return None, "Claude API key not configured"

        # Validate API key format
        api_key = self.anthropic_api_key.strip()
        if not api_key.startswith("sk-"):
            return None, f"Invalid API key format (doesn't start with 'sk-'): {api_key[:20]}..."

        try:
            import anthropic
        except ImportError:
            return None, "anthropic package not installed (pip install anthropic)"

        try:
            self.last_claude_call = datetime.now()

            client = anthropic.Anthropic(api_key=api_key)

            # Build the prompt
            prompt = self._build_prompt(request_type, content, persona, context)

            # Get GTD tools and skills for Claude API
            tools = []
            try:
                functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                if not functions_dir.exists():
                    functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                
                if functions_dir.exists() and str(functions_dir) not in sys.path:
                    sys.path.insert(0, str(functions_dir))
                
                from gtd_tool_registry import get_tool_definitions
                # Include both GTD tools and skills
                gtd_tools = get_tool_definitions(categories=["gtd", "skills"])
                
                # Convert OpenAI format to Anthropic format
                for tool in gtd_tools:
                    tools.append({
                        "name": tool["function"]["name"],
                        "description": tool["function"]["description"],
                        "input_schema": tool["function"]["parameters"]
                    })
            except Exception as e:
                # If tool loading fails, continue without tools
                # sys is already imported at module level
                print(f"⚠️  Could not load GTD tools: {e}", file=sys.stderr)

            # Build system message
            system_message = prompt.get('system', 'You are a helpful assistant.')
            if tools:
                tool_names = [t.get("name", "") for t in tools]
                gtd_tools = [t for t in tool_names if t.startswith("gtd_")]
                skill_tools = [t for t in tool_names if "skill" in t.lower()]
                
                system_message += "\n\nYou have access to GTD tools to interact with the user's productivity system. Available tools include:"
                system_message += f"\n- GTD Tools ({len(gtd_tools)}): {', '.join(gtd_tools[:10])}" + ("..." if len(gtd_tools) > 10 else "")
                
                if skill_tools:
                    system_message += f"\n- Skill Tools ({len(skill_tools)}): {', '.join(skill_tools)}"
                
                # Mention personalization if available
                if "gtd_get_personalization" in tool_names:
                    system_message += "\n\nIMPORTANT: You have access to personalization data via gtd_get_personalization. Use this to understand the user's relationships (e.g., who 'Louiza' is), goals, preferences, work patterns, and communication style. This helps you provide more personalized, context-aware assistance. Call gtd_get_personalization() early in conversations to understand the user better."
                
                if "gtd_update_personalization" in tool_names:
                    system_message += "\n\nLEARNING: You can update personalization data via gtd_update_personalization when you discover new, reliable information about the user (e.g., learning their partner's name, discovering goals, noticing energy patterns). Only update when you have clear, explicit information - don't guess or assume. Use the 'personalization-learning' skill for guidance on when and how to update."
                
                system_message += "\n\nWhen you call a tool, it will execute and return results. If a tool call succeeds, you'll receive the tool's output. If it fails, you'll receive an error message. Always use the tool results to inform your response."
                system_message += "\n\nIMPORTANT WORKFLOW GUIDELINES:"
                system_message += "\n- For long workflows (like morning check-ins, reviews), break them into steps"
                system_message += "\n- After completing 2-3 tool calls, provide a progress update summarizing what you've done"
                system_message += "\n- Then ask if the user wants to continue or if they have questions"
                system_message += "\n- This allows interactive, back-and-forth conversation rather than one long response"
                system_message += "\n- If you hit rate limits or max iterations, summarize what you've accomplished and what remains"
                
                if skill_tools:
                    system_message += "\n\nYou also have access to Agent Skills - reusable workflows that guide how to accomplish goals using GTD tools. Skills provide step-by-step instructions for complex workflows. To use skills: (1) Call list_agent_skills to discover available skills, (2) Call get_agent_skill to read a skill's instructions, (3) Follow the skill's step-by-step workflow using the appropriate GTD tools."
                
                system_message += "\n\nIf you're unsure what tools are available, you can call list_available_tools to see all available tools and their descriptions."

            # Build initial messages
            # Include conversation history if provided
            messages = []
            if context and context.get("conversation_history"):
                # Add conversation history
                for msg in context.get("conversation_history", []):
                    messages.append(msg)
            
            # Add current user message
            messages.append({
                "role": "user",
                "content": f"{prompt.get('user', content)}"
            })

            # Try models in order: configured model, then fallbacks
            models_to_try = [self.claude_model] + [m for m in self.claude_model_fallbacks if m != self.claude_model]
            last_error = None

            for model_name in models_to_try:
                try:
                    max_iterations = 15  # Increased limit for complex workflows (skills may require multiple tool calls)
                    iteration = 0
                    final_response = None
                    accumulated_text = ""  # Collect text responses across iterations

                    while iteration < max_iterations:
                        # Make request
                        request_params = {
                            "model": model_name,
                            "max_tokens": int(context.get("max_tokens", 1024)) if context else 1024,
                            "system": system_message,
                            "messages": messages,
                        }
                        
                        if tools:
                            request_params["tools"] = tools

                        # Handle rate limiting with exponential backoff
                        max_retries = 3
                        retry_count = 0
                        message = None
                        
                        while retry_count < max_retries:
                            try:
                                message = client.messages.create(**request_params)
                                break  # Success, exit retry loop
                            except Exception as api_error:
                                error_str = str(api_error)
                                # Check if it's a rate limit error (429)
                                if "429" in error_str or "rate limit" in error_str.lower() or "too many requests" in error_str.lower():
                                    retry_count += 1
                                    if retry_count < max_retries:
                                        # Exponential backoff: 2^retry_count seconds
                                        wait_time = 2 ** retry_count
                                        print(f"  ⏳ Rate limited, waiting {wait_time}s before retry {retry_count}/{max_retries}...", file=sys.stderr)
                                        import time
                                        time.sleep(wait_time)
                                        continue
                                    else:
                                        raise api_error  # Re-raise if we've exhausted retries
                                else:
                                    raise api_error  # Not a rate limit error, re-raise immediately
                        
                        if message is None:
                            raise Exception("Failed to get response after rate limit retries")

                        # Check if there are tool calls
                        tool_calls = []
                        assistant_content = []
                        text_blocks = []
                        
                        for content_block in message.content:
                            if content_block.type == "tool_use":
                                tool_calls.append(content_block)
                                assistant_content.append({
                                    "type": "tool_use",
                                    "id": content_block.id,
                                    "name": content_block.name,
                                    "input": content_block.input
                                })
                            elif content_block.type == "text":
                                text_blocks.append(content_block.text)
                                assistant_content.append({
                                    "type": "text",
                                    "text": content_block.text
                                })

                        # Accumulate any text responses (but don't use them until Claude is done)
                        if text_blocks:
                            new_text = "\n".join(text_blocks)
                            # Only accumulate if it's substantial (not just "okay" or similar)
                            if len(new_text.strip()) > 20:
                                accumulated_text += new_text + "\n"

                        if tool_calls:
                            # Execute tools and add results to messages
                            print(f"🔧 Iteration {iteration + 1}/{max_iterations}: Executing {len(tool_calls)} tool call(s)", file=sys.stderr)
                            tool_results = []
                            for tool_call in tool_calls:
                                tool_name = tool_call.name
                                tool_id = tool_call.id
                                tool_args = tool_call.input

                                print(f"  → Calling {tool_name} with args: {str(tool_args)[:100]}...", file=sys.stderr)

                                # Execute the tool
                                try:
                                    functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                                    if not functions_dir.exists():
                                        functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                                    
                                    if functions_dir.exists() and str(functions_dir) not in sys.path:
                                        sys.path.insert(0, str(functions_dir))
                                    
                                    from gtd_tool_registry import execute_tool
                                    tool_result = execute_tool(tool_name, tool_args)
                                    
                                    # Check if result indicates an error
                                    is_error = False
                                    if isinstance(tool_result, str):
                                        if tool_result.startswith("Error:") or tool_result.startswith("error:"):
                                            is_error = True
                                        # Try to parse as JSON to check for error field
                                        try:
                                            result_json = json.loads(tool_result)
                                            if isinstance(result_json, dict) and result_json.get("error"):
                                                is_error = True
                                        except:
                                            pass
                                    
                                    # Limit tool result size to prevent token bloat
                                    if len(tool_result) > 8000:
                                        tool_result = tool_result[:8000] + "\n... (truncated)"
                                    
                                    if is_error:
                                        print(f"  ❌ {tool_name} returned error ({len(tool_result)} chars)", file=sys.stderr)
                                    else:
                                        print(f"  ✅ {tool_name} completed successfully ({len(tool_result)} chars)", file=sys.stderr)
                                    
                                    tool_results.append({
                                        "type": "tool_result",
                                        "tool_use_id": tool_id,
                                        "content": tool_result
                                    })
                                except Exception as e:
                                    import traceback
                                    error_msg = f"Error executing tool '{tool_name}': {str(e)}"
                                    print(f"  ❌ {error_msg}", file=sys.stderr)
                                    tool_results.append({
                                        "type": "tool_result",
                                        "tool_use_id": tool_id,
                                        "content": error_msg
                                    })

                            # Add assistant message with all content (text + tool calls)
                            messages.append({
                                "role": "assistant",
                                "content": assistant_content
                            })
                            # Add tool results as user message
                            messages.append({
                                "role": "user",
                                "content": tool_results
                            })

                            iteration += 1
                            
                            # Don't exit early if Claude is still making tool calls - let it finish the workflow
                            # Only exit early if we're at max iterations and have some text
                            if iteration >= max_iterations:
                                if accumulated_text.strip():
                                    print(f"  ⚠️  Max iterations reached, using accumulated text ({len(accumulated_text)} chars)", file=sys.stderr)
                                    final_response = accumulated_text.strip()
                                    break
                                else:
                                    print(f"  ⚠️  Max iterations reached without text response", file=sys.stderr)
                            
                            continue  # Loop to get final response
                        else:
                            # No tool calls - extract text response
                            response_text = ""
                            for content_block in message.content:
                                if content_block.type == "text":
                                    response_text += content_block.text

                            # Combine accumulated text with final response
                            if accumulated_text and response_text:
                                # Merge intelligently - don't duplicate
                                if response_text.strip() not in accumulated_text:
                                    final_response = (accumulated_text.strip() + "\n\n" + response_text.strip()).strip()
                                else:
                                    # Current response is already in accumulated, just use accumulated
                                    final_response = accumulated_text.strip()
                            elif accumulated_text:
                                final_response = accumulated_text.strip()
                            else:
                                final_response = response_text.strip()
                            
                            if not final_response:
                                final_response = response_text.strip()  # Fallback to current response
                            
                            print(f"  ✅ Got final text response ({len(final_response)} chars)", file=sys.stderr)
                            break  # Exit tool call loop

                    if final_response is None or not final_response.strip():
                        # If we hit max iterations but have accumulated text, use it
                        if accumulated_text.strip():
                            final_response = accumulated_text.strip()
                        else:
                            return None, f"Max tool call iterations ({max_iterations}) reached without final response. Claude may be stuck in a tool-calling loop."

                    # If we used a fallback model, update the configured model for next time
                    if model_name != self.claude_model:
                        self.claude_model = model_name

                    return {
                        "source": "claude",
                        "response": final_response,
                        "request_type": request_type,
                        "timestamp": datetime.now().isoformat(),
                        "model": model_name,
                    }, None

                except Exception as e:
                    # If it's a 404 (model not found), try next model
                    error_str = str(e)
                    if "404" in error_str or "not found" in error_str.lower() or "not_found" in error_str:
                        last_error = e
                        # Log which model failed (for debugging)
                        # sys is already imported at module level
                        print(f"⚠️  Model '{model_name}' not available, trying next...", file=sys.stderr)
                        continue  # Try next model
                    else:
                        # For other errors, fail immediately
                        return None, f"Claude error: {e}"

            # If we tried all models and all failed, provide helpful error message
            if last_error:
                models_tried = ", ".join([f"'{m}'" for m in models_to_try])
                return None, (
                    f"Claude error: All models failed ({len(models_to_try)} models tried: {models_tried}). "
                    f"Last error: {last_error}. "
                    f"This may indicate your API key doesn't have access to these models, "
                    f"or there's an issue with your Anthropic account tier."
                )

        except Exception as e:
            return None, f"Claude error: {e}"

    def _build_prompt(
        self,
        request_type: str,
        content: str,
        persona: Optional[str],
        context: Optional[Dict[str, Any]],
    ) -> Dict[str, str]:
        """Build system and user prompts based on request type"""

        prompts = {
            "persona_response": {
                "system": f"You are {persona or 'a helpful assistant'}. Provide a brief, in-character response.",
                "user": content,
            },
            "task_categorize": {
                "system": "You are a GTD task categorization expert. Categorize tasks as either @computer, @phone, @errands, or @waiting-for.",
                "user": f"Categorize these tasks:\n{content}",
            },
            "task_suggest": {
                "system": "You are a GTD task suggestion expert. Generate 3-5 actionable tasks from the given context.",
                "user": f"Suggest tasks from:\n{content}",
            },
            "similarity_search": {
                "system": "You are helping find similar items. Return just the most relevant item.",
                "user": f"Find similar to:\n{content}",
            },
            "analyze_daily_log": {
                "system": "You are a productivity coach analyzing daily logs. Provide insights and suggestions.",
                "user": f"Analyze this log:\n{content}",
            },
            "weekly_review": {
                "system": "You are a strategic planning assistant. Analyze weekly patterns and provide insights.",
                "user": f"Review this week's data:\n{content}",
            },
            "strategy_planning": {
                "system": "You are a strategic planning expert. Help plan an approach based on context.",
                "user": f"Help plan:\n{content}",
            },
        }

        return prompts.get(request_type, {"system": "You are a helpful assistant.", "user": content})

    def get_status(self) -> Dict[str, Any]:
        """Get current router status"""
        return {
            "mode": self.mode,
            "ollama_available": self._check_ollama(),
            "claude_available": bool(self.use_claude),
            "ollama_url": self.ollama_url,
            "last_ollama_call": self.last_ollama_call.isoformat() if self.last_ollama_call else None,
            "last_claude_call": self.last_claude_call.isoformat() if self.last_claude_call else None,
        }

    def _check_ollama(self) -> bool:
        """Quick check if Ollama is available"""
        try:
            req = urllib.request.Request(
                self.ollama_url.rsplit('/v1', 1)[0] + "/v1/models",
                headers={"Accept": "application/json"},
            )
            with urllib.request.urlopen(req, timeout=2) as response:
                return response.status == 200
        except:
            return False

    def switch_mode(self, new_mode: str) -> Tuple[bool, str]:
        """Switch between ollama-only and hybrid modes"""

        if new_mode not in [AIMode.OLLAMA_ONLY, AIMode.HYBRID]:
            return False, f"Invalid mode: {new_mode}. Use '{AIMode.OLLAMA_ONLY}' or '{AIMode.HYBRID}'"

        try:
            # Update config file
            config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config_ai"
            if not config_file.exists():
                config_file = Path.home() / ".gtd_config_ai"

            if not config_file.exists():
                return False, f"Config file not found: {config_file}"

            content = config_file.read_text()

            # Replace the mode line
            if "GTD_AI_MODE=" in content:
                lines = content.split('\n')
                new_lines = []
                for line in lines:
                    if line.startswith("GTD_AI_MODE="):
                        new_lines.append(f'GTD_AI_MODE="{new_mode}"')
                    else:
                        new_lines.append(line)
                config_file.write_text('\n'.join(new_lines))
            else:
                # Add the line if it doesn't exist
                if not content.endswith('\n'):
                    content += '\n'
                config_file.write_text(content + f'GTD_AI_MODE="{new_mode}"\n')

            self.mode = new_mode
            self.use_claude = new_mode == AIMode.HYBRID and self.anthropic_api_key

            return True, f"Switched to {new_mode} mode"

        except Exception as e:
            return False, f"Failed to switch mode: {e}"


# CLI interface for testing
if __name__ == "__main__":
    router = SmartAIRouter()

    if len(sys.argv) > 1:
        command = sys.argv[1]

        if command == "status":
            print(json.dumps(router.get_status(), indent=2))

        elif command == "switch":
            if len(sys.argv) > 2:
                success, message = router.switch_mode(sys.argv[2])
                print(message)
                sys.exit(0 if success else 1)
            else:
                print("Usage: switch <ollama-only|hybrid>")
                sys.exit(1)

        elif command == "test":
            result, error = router.route_request(
                "persona_response",
                "What should I do today?",
                persona="hank"
            )
            if error:
                print(f"Error: {error}")
                sys.exit(1)
            else:
                print(json.dumps(result, indent=2))

    else:
        print("Smart AI Router")
        print(f"Mode: {router.mode}")
        print(f"Status: {json.dumps(router.get_status(), indent=2)}")
