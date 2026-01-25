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

# Import persona definitions for persona support
try:
    from zsh.functions.gtd_persona_helper import PERSONAS
except ImportError:
    # Try alternative path
    try:
        sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
        from gtd_persona_helper import PERSONAS
    except ImportError:
        PERSONAS = {}


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
        # Default timeout increased to 120 seconds for local Ollama calls (larger models can take longer)
        self.ollama_timeout = int(self.config.get("ollama_timeout", 120))
        # Direct Ollama URL (bypasses async/polling - for faster responses)
        self.ollama_direct_url = self.config.get("ollama_direct_url", None)
        # If not set, try to derive from ollama_url (remove /v1/chat/completions and use /api/generate)
        if not self.ollama_direct_url:
            base_url = self.ollama_url.rsplit('/v1', 1)[0]
            # Try direct Ollama API endpoint (synchronous, no polling)
            self.ollama_direct_url = f"{base_url}/api/generate"
        self.anthropic_api_key = self.config.get("anthropic_api_key", "")
        self.use_claude = self.mode == AIMode.HYBRID and self.anthropic_api_key
        # Claude model name - try older models first (more widely available)
        # Then newer models. See: https://platform.claude.com/docs/en/about-claude/models/overview
        self.claude_model = self.config.get("claude_model", "claude-3-haiku-20240307")
        # Ollama model name - default to gemma3:1b (fast, small model)
        self.ollama_model = self.config.get("ollama_model", "gemma3:1b")
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
                        elif line.startswith('OLLAMA_DIRECT_URL='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            if value:
                                config["ollama_direct_url"] = value
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
                        elif line.startswith('OLLAMA_TIMEOUT='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            if value:
                                try:
                                    config["ollama_timeout"] = int(value)
                                except ValueError:
                                    pass  # Invalid timeout value, skip
                        elif line.startswith('OLLAMA_MODEL='):
                            raw_value = line.split('=', 1)[1]
                            value = self._parse_bash_value(raw_value)
                            if value:
                                config["ollama_model"] = value

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

        # Check if request requires tools and model capabilities
        data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox", "log"]
        # Sequential thinking keywords that are especially demanding
        sequential_thinking_keywords = ["sequential thinking", "thinking", "thought", "step-by-step", "analyze", "break down"]
        content_lower = content.lower() if content else ""
        requires_tools = any(keyword in content_lower for keyword in data_keywords)
        requires_sequential_thinking = any(keyword in content_lower for keyword in sequential_thinking_keywords)
        model_lower = self.ollama_model.lower() if self.ollama_model else ""
        is_small_model = any(size in model_lower for size in ["1b", "3b", "2b", "4b"])

        # Determine target based on mode
        if self.mode == AIMode.OLLAMA_ONLY:
            target = "ollama"
            # Warn user if they're using a small model for complex requests
            if (requires_tools or requires_sequential_thinking) and is_small_model:
                print(f"  ⚠️  Using small model ({self.ollama_model}) for complex request in OLLAMA_ONLY mode", file=sys.stderr)
                print(f"  💡 Consider using a larger model (8b+): --ollama-model llama3.1:8b-instruct-q6_K", file=sys.stderr)
            if requires_sequential_thinking and is_small_model:
                print(f"  🧠 Sequential thinking with small models may cause instability", file=sys.stderr)
        elif self.mode == AIMode.HYBRID:
            target = self._choose_target(request_type, complexity, content)
            # Force sequential thinking to Claude for reliability
            if requires_sequential_thinking and target == "ollama" and is_small_model:
                print(f"  🧠 Routing sequential thinking to Claude for reliability", file=sys.stderr)
                target = "claude"
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
            "general_question": 0.3,      # General questions - start simple, adjust based on content
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

        # Check for simple question indicators (math, facts, definitions)
        simple_indicators = [
            "what's", "what is", "how much", "how many", 
            "when did", "who is", "where is", "what time",
            "calculate", "compute", "add", "subtract", "multiply", "divide",
            "define", "meaning of", "spell", "translate",
        ]
        has_simple_markers = any(indicator in content.lower() for indicator in simple_indicators)
        # Simple questions get a complexity reduction
        simplicity_reduction = 0.2 if has_simple_markers and len(content) < 100 else 0

        # Very short questions (< 50 chars) are likely simple
        if len(content) < 50 and not has_complexity_markers:
            simplicity_reduction = max(simplicity_reduction, 0.15)

        final_complexity = min(1.0, max(0.0, base_complexity + content_length_score + complexity_boost - simplicity_reduction))
        return final_complexity

    def _choose_target(self, request_type: str, complexity: float, content: str = "") -> str:
        """Choose between Ollama and Claude based on complexity"""
        
        # CRITICAL: If request requires tools and we're using a model that may not support tool calling well,
        # force to Claude for reliability. Some Ollama models (especially smaller ones) don't handle
        # tool calling reliably even if they technically support it.
        data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox", "log"]
        content_lower = content.lower() if content else ""
        requires_tools = any(keyword in content_lower for keyword in data_keywords)
        
        # Check if we're using a model that might not handle tool calling well
        # Smaller models (1b, 3b) often struggle with tool calling even if they support it
        model_lower = self.ollama_model.lower() if self.ollama_model else ""
        is_small_model = any(size in model_lower for size in ["1b", "3b", "2b", "4b"])
        
        # For tool-requiring requests with small models, prefer Claude for reliability
        if requires_tools and is_small_model and self.use_claude:
            print(f"  ℹ️  Request requires tools and using small model ({self.ollama_model}) - routing to Claude for reliability", file=sys.stderr)
            return "claude"

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
        # Use strict < comparison so 0.5 goes to Ollama (not Claude)
        if complexity < RouteComplexity.MODERATE:
            return "ollama"
        elif complexity > RouteComplexity.MODERATE and self.use_claude:
            return "claude"
        else:
            # At exactly MODERATE (0.5), prefer Ollama for cost savings
            # Only use Claude if complexity is clearly above moderate
            return "ollama"  # Default to Ollama for cost savings

    def _call_ollama(
        self,
        request_type: str,
        content: str,
        persona: Optional[str],
        context: Optional[Dict[str, Any]],
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Call Ollama for a request with tool support - uses OpenAI-compatible endpoint for tool calling"""
        
        # Initialize tool execution details tracking for this request
        self._tool_execution_details = []

        try:
            self.last_ollama_call = datetime.now()

            # Build the prompt based on request type
            prompt = self._build_prompt(request_type, content, persona, context)

            # For tool calling, we MUST use OpenAI-compatible endpoint
            # Direct /api/generate doesn't support tools
            return self._call_ollama_openai_compatible(prompt, context, request_type, content, persona)

        except Exception as e:
            return None, f"Ollama error: {e}"

    def _call_ollama_direct(
        self,
        prompt: Dict[str, str],
        context: Optional[Dict[str, Any]],
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Call Ollama using direct /api/generate endpoint (synchronous, fast)"""
        
        if not self.ollama_direct_url:
            return None, "Direct Ollama URL not configured"

        try:
            # Combine system and user prompts for direct API
            full_prompt = f"{prompt.get('system', '')}\n\n{prompt.get('user', '')}".strip()
            
            # Direct Ollama API format
            # Use model from context if provided, otherwise use configured ollama_model
            model_name = context.get("model") if context else None
            if not model_name:
                model_name = self.ollama_model
            
            body = json.dumps({
                "model": model_name,
                "prompt": full_prompt,
                "stream": False,  # Get complete response
                "options": {
                    "temperature": context.get("temperature", 0.7) if context else 0.7,
                    "num_predict": context.get("max_tokens", 500) if context else 500,
                }
            }).encode("utf-8")

            req = urllib.request.Request(
                self.ollama_direct_url,
                data=body,
                headers={"Content-Type": "application/json"},
            )

            with urllib.request.urlopen(req, timeout=self.ollama_timeout) as response:
                result = json.loads(response.read().decode("utf-8"))

            # Extract response from direct API format
            if "response" in result:
                response_text = result["response"]
                return {
                    "source": "ollama",
                    "response": response_text,
                    "request_type": "general_question",
                    "timestamp": datetime.now().isoformat(),
                }, None
            else:
                return None, "No response in Ollama direct API result"

        except urllib.error.URLError:
            # Connection failed, fall back to OpenAI-compatible endpoint
            return None, None  # Return None, None to signal fallback
        except Exception:
            # Any other error, fall back
            return None, None

    def _call_ollama_openai_compatible(
        self,
        prompt: Dict[str, str],
        context: Optional[Dict[str, Any]],
        request_type: str = "general_question",
        content: str = "",
        persona: Optional[str] = None,
    ) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
        """Call Ollama using OpenAI-compatible endpoint with tool support (may require polling)"""

        try:
            # Prepare request for OpenAI-compatible endpoint
            # Use model from context if provided, otherwise use configured ollama_model
            model_name = context.get("model") if context else None
            if not model_name:
                model_name = self.ollama_model
            
            # Get GTD tools for Ollama (same as Claude)
            tools = []
            try:
                functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                if not functions_dir.exists():
                    functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                
                if functions_dir.exists() and str(functions_dir) not in sys.path:
                    sys.path.insert(0, str(functions_dir))
                
                from gtd_tool_registry import get_tool_definitions
                # Include GTD tools, skills, and knowledge organization (exclude sequential_thinking - only available in Cursor IDE)
                gtd_tools = get_tool_definitions(categories=["gtd", "skills", "knowledge_organization"])
                
                # Convert to OpenAI format (Ollama uses OpenAI-compatible format)
                for tool in gtd_tools:
                    tools.append({
                        "type": "function",
                        "function": {
                            "name": tool["function"]["name"],
                            "description": tool["function"]["description"],
                            "parameters": tool["function"]["parameters"]
                        }
                    })
                
                if tools and (context is None or context.get("verbose", False)):
                    print(f"  ✓ Loaded {len(tools)} tools for Ollama", file=sys.stderr)
            except Exception as e:
                # If tool loading fails, continue without tools
                print(f"⚠️  Could not load GTD tools for Ollama: {e}", file=sys.stderr)
                tools = []
            
            # Build initial messages (system message will be added later with tool instructions)
            messages = [
                {"role": "user", "content": prompt.get("user", "")},
            ]
            
            # Build request body
            body_dict = {
                "model": model_name,
                "messages": messages,
                "temperature": context.get("temperature", 0.7) if context else 0.7,
                "max_tokens": context.get("max_tokens", 2000) if context else 2000,
                "priority": context.get("priority", 10) if context else 10,  # Lower = higher priority
            }
            
            # Add tools if available
            if tools:
                body_dict["tools"] = tools
                body_dict["tool_choice"] = "auto"  # Let model decide when to use tools
            
            body = json.dumps(body_dict).encode("utf-8")

            # Make request
            req = urllib.request.Request(
                self.ollama_url,
                data=body,
                headers={"Content-Type": "application/json"},
            )

            with urllib.request.urlopen(req, timeout=self.ollama_timeout) as response:
                result = json.loads(response.read().decode("utf-8"))

            # Handle async responses with enhanced timeout management
            if result.get("status") == "queued":
                base_url = self.ollama_url.rsplit('/v1', 1)[0]
                request_id = result.get("request_id")
                
                print(f"  🔄 Ollama request queued (ID: {request_id})", file=sys.stderr)
                print(f"  ⏳ Will wait up to {self.ollama_timeout}s, with status updates...", file=sys.stderr)
                
                polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=self.ollama_timeout)
                
                if polled_result:
                    result = polled_result
                    print(f"  ℹ️  Polled result keys: {list(result.keys())}", file=sys.stderr)
                    # If result has status "completed" but choices might be in detail, extract them
                    if result.get("status") == "completed":
                        print(f"  ℹ️  Status is 'completed', extracting response...", file=sys.stderr)
                        # Check if choices are in detail
                        if isinstance(result.get("detail"), dict) and "choices" in result.get("detail", {}):
                            result = result["detail"]
                            print(f"  ✅ Extracted choices from detail", file=sys.stderr)
                        # If result has message field (status response format), try to get actual response
                        elif "message" in result and "choices" not in result:
                            # This is a status response, not the actual response - need to extract
                            print(f"  ⚠️  Got status response instead of actual response, attempting to extract...", file=sys.stderr)
                            # The actual response should be in the detail or we need to check the structure
                            if isinstance(result.get("detail"), dict):
                                if "choices" in result["detail"]:
                                    result = result["detail"]
                                    print(f"  ✅ Found choices in detail", file=sys.stderr)
                                elif "response" in result["detail"]:
                                    # Some formats might have response directly
                                    response_text = result["detail"]["response"]
                                    print(f"  ✅ Found response in detail ({len(response_text)} chars)", file=sys.stderr)
                                    return {
                                        "source": "ollama",
                                        "response": response_text,
                                        "request_type": request_type,
                                        "timestamp": datetime.now().isoformat(),
                                    }, None
                                else:
                                    print(f"  ⚠️  Detail exists but no choices or response. Detail keys: {list(result['detail'].keys())}", file=sys.stderr)
                            else:
                                print(f"  ⚠️  No detail field or detail is not a dict", file=sys.stderr)
                    else:
                        print(f"  ℹ️  Status is '{result.get('status', 'unknown')}', not 'completed'", file=sys.stderr)
                elif poll_error:
                    # Enhanced timeout handling
                    if "timed out" in poll_error:
                        # Process is still running in background
                        timeout_msg = f"""Ollama request timed out after {self.ollama_timeout}s, but the process is still running in background.

🔄 **Background Process Status:**
  • Request ID: {request_id}
  • Status: Still processing in Ollama queue
  • Estimated completion: May take several more minutes

💡 **What you can do:**
  • Check status: gtd request-status {request_id}
  • Try a simpler request while this completes
  • Use direct CLI: gtd read-daily-log today (bypasses LLM)
  • Force Claude: Press Ctrl+F to use Claude instead of Ollama

⚠️  **The background process will continue running.**
    Results may be available later via status check."""
                        return None, timeout_msg
                    else:
                        return None, f"Ollama polling error: {poll_error}"

            # Handle tool calling loop (similar to Claude)
            max_iterations = 15
            iteration = 0
            final_response = None
            accumulated_text = ""
            
            # Build system message with tool instructions (same as Claude)
            system_message = prompt.get("system", "You are a helpful assistant.")
            
            # Add tool-first instructions if tools are available (same as Claude)
            if tools:
                # Get tool names for instructions
                tool_names = [t["function"]["name"] for t in tools]
                gtd_tools = [t for t in tool_names if t.startswith("gtd_")]
                skill_tools = [t for t in tool_names if "skill" in t.lower()]
                
                # Add the same tool-first instructions that Claude gets
                system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n🚨🚨🚨 MANDATORY: TOOL-FIRST RESPONSE RULE 🚨🚨🚨"
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n\n⚠️ CRITICAL: If the user asks about ANY data (tasks, projects, logs, inbox, notes, personalization, skills, runbooks), you MUST call the appropriate tool FIRST before generating ANY response text."
                system_message += "\n\n🚨 CRITICAL: YOU MUST USE THE FUNCTION CALLING API - NOT DESCRIBE IT IN TEXT"
                system_message += "\n  - DO NOT write text like 'Tool Call: gtd_list_tasks()' or 'I will call gtd_read_daily_log()'"
                system_message += "\n  - DO NOT describe what tools you would call"
                system_message += "\n  - DO NOT output JSON like {\"method\":\"instructions\",\"skill_name\":\"daily-review\"} in the content field"
                system_message += "\n  - DO NOT write JSON objects describing tool calls - this is WRONG"
                system_message += "\n  - YOU MUST actually use the function calling API by including tool_calls in your response message"
                system_message += "\n  - When you need data, your response message should have a 'tool_calls' field with tool call objects"
                system_message += "\n  - The tool_calls field is separate from the content field - do NOT put tool descriptions in content"
                system_message += "\n  - CORRECT: Include tool_calls array in your response message"
                system_message += "\n  - WRONG: Writing {\"method\":\"instructions\"} or any JSON in the content field"
                system_message += "\n\n❌ ABSOLUTELY FORBIDDEN:"
                system_message += "\n  - Writing text that describes tool calls (e.g., 'Tool Call: gtd_list_tasks()')"
                system_message += "\n  - Saying 'I will call...' or 'Let me check...' - JUST CALL THE TOOLS"
                system_message += "\n  - Responding with text before calling tools for data queries"
                system_message += "\n  - Making up, inventing, or guessing any data"
                system_message += "\n  - Mentioning specific task/project/log names without tool calls"
                system_message += "\n  - Describing what you would do instead of doing it"
                system_message += "\n  - Creative/fictional responses when user asks for data"
                system_message += "\n  - Any response that doesn't use actual tool results"
                system_message += "\n\n✅ MANDATORY FLOW FOR DATA QUERIES:"
                system_message += "\n  1. User asks about data (e.g., 'review my daily log', 'what tasks do I have', 'use the runbook')"
                system_message += "\n  2. YOU: IMMEDIATELY make tool call(s) - NO TEXT RESPONSE YET"
                system_message += "\n  3. Wait for tool result(s)"
                system_message += "\n  4. THEN and ONLY THEN generate response using ACTUAL tool results"
                system_message += "\n\n✅ REQUIRED TOOL CALLS:"
                system_message += "\n  - 'review daily log' / 'daily log' → MUST CALL gtd_read_daily_log(date='today') FIRST"
                system_message += "\n  - 'use runbook' / 'follow runbook' → MUST CALL list_agent_skills(query='runbook') THEN get_agent_skill() FIRST"
                system_message += "\n  - 'tasks' / 'my tasks' → MUST CALL gtd_list_tasks() FIRST"
                system_message += "\n  - 'projects' / 'my projects' → MUST CALL gtd_list_projects() FIRST"
                system_message += "\n  - 'inbox' → MUST CALL gtd_get_inbox_count() or gtd_list_inbox_items() FIRST"
                system_message += "\n  - 'personalization' / 'about me' → MUST CALL gtd_get_personalization() FIRST"
                system_message += "\n  - 'search notes' / 'second brain' → MUST CALL gtd_search_second_brain() FIRST"
                system_message += "\n  - 'skills' / 'workflows' / 'what can you do' → MUST CALL list_agent_skills() FIRST"
                system_message += "\n\n🚨 IF YOU DON'T HAVE TOOL RESULTS, YOU DON'T HAVE DATA. DO NOT MAKE UP DATA."
                system_message += "\n🚨 IF USER ASKS FOR DATA, YOU MUST CALL TOOLS FIRST. NO EXCEPTIONS."
                system_message += "\n🚨 IF TOOLS RETURN EMPTY/NOTHING, SAY SO. DO NOT INVENT DATA TO FILL THE VOID."
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                # Check if user is asking for a runbook
                is_runbook_request = False
                runbook_keywords = ["runbook", "daily log review", "review daily log", "follow the runbook", "use the runbook"]
                content_lower = content.lower() if content else ""
                for keyword in runbook_keywords:
                    if keyword in content_lower:
                        is_runbook_request = True
                        break
                
                if is_runbook_request:
                    system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n🚨🚨🚨 RUNBOOK REQUEST DETECTED - MANDATORY WORKFLOW 🚨🚨🚨"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n\n⚠️ CRITICAL: The user asked to use a RUNBOOK. You MUST follow this exact workflow:"
                    system_message += "\n\n📋 STEP-BY-STEP MANDATORY WORKFLOW:"
                    system_message += "\n  1. IMMEDIATELY call list_agent_skills(query='runbook', runbooks_only=True) - NO TEXT, NO EXPLANATION, JUST THE TOOL CALL"
                    system_message += "\n  2. Wait for result, find 'Daily Log Review Runbook'"
                    system_message += "\n  3. IMMEDIATELY call get_agent_skill(skill_name='daily-log-review-runbook') - NO TEXT, JUST THE TOOL CALL"
                    system_message += "\n  4. Read the runbook instructions - it has 7 steps"
                    system_message += "\n  5. Follow Step 1: IMMEDIATELY call gtd_read_daily_log(date='today') - NO TEXT, JUST THE TOOL CALL"
                    system_message += "\n  6. Wait for tool result - this is the ACTUAL daily log data"
                    system_message += "\n  7. Use ONLY the actual log data returned - do NOT make up expenses, financial data, or any other information"
                    system_message += "\n  8. Continue with runbook Step 2: Analyze the ACTUAL log structure"
                    system_message += "\n  9. Continue with runbook Step 3: Cross-reference with GTD system (call gtd_list_tasks(), gtd_list_projects())"
                    system_message += "\n  10. Continue with remaining runbook steps using ACTUAL data only"
                    system_message += "\n  11. ONLY generate final text response AFTER completing all runbook steps with tool calls"
                    system_message += "\n\n❌ ABSOLUTELY FORBIDDEN WHEN RUNBOOK IS REQUESTED:"
                    system_message += "\n  - Making up financial data, expenses, or any data not in tool results"
                    system_message += "\n  - Responding with text before calling list_agent_skills()"
                    system_message += "\n  - Describing what you would do instead of doing it"
                    system_message += "\n  - Skipping tool calls"
                    system_message += "\n  - Creative/fictional responses (expenses, financial stability quests, etc.)"
                    system_message += "\n  - Any response that doesn't match the actual daily log content"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Start with initial messages (include system message)
            conversation_messages = [
                {"role": "system", "content": system_message},
                *messages
            ]
            
            while iteration < max_iterations:
                # Make request
                request_body = {
                    "model": model_name,
                    "messages": conversation_messages,
                    "temperature": context.get("temperature", 0.7) if context else 0.7,
                    "max_tokens": context.get("max_tokens", 2000) if context else 2000,
                    "priority": context.get("priority", 10) if context else 10,  # Lower = higher priority
                }
                
                if tools:
                    request_body["tools"] = tools
                    request_body["tool_choice"] = "auto"
                
                body = json.dumps(request_body).encode("utf-8")
                
                req = urllib.request.Request(
                    self.ollama_url,
                    data=body,
                    headers={"Content-Type": "application/json"},
                )
                
                with urllib.request.urlopen(req, timeout=self.ollama_timeout) as response:
                    result = json.loads(response.read().decode("utf-8"))
                
                # Handle async responses with enhanced timeout management
                if result.get("status") == "queued":
                    base_url = self.ollama_url.rsplit('/v1', 1)[0]
                    request_id = result.get("request_id")
                    
                    print(f"  🔄 Ollama tool call queued (ID: {request_id})", file=sys.stderr)
                    print(f"  ⏳ Waiting up to {self.ollama_timeout}s...", file=sys.stderr)
                    
                    polled_result, poll_error = handle_ai_response(result, base_url, max_poll_time=self.ollama_timeout)
                    
                    if polled_result:
                        result = polled_result
                        # If result has status "completed" but choices might be in detail, extract them
                        if result.get("status") == "completed":
                            # Check if choices are in detail
                            if isinstance(result.get("detail"), dict) and "choices" in result.get("detail", {}):
                                result = result["detail"]
                            # If result has message field (status response format), try to get actual response
                            elif "message" in result and "choices" not in result:
                                # This is a status response, not the actual response - need to extract
                                if isinstance(result.get("detail"), dict):
                                    if "choices" in result["detail"]:
                                        result = result["detail"]
                                    elif "response" in result["detail"]:
                                        # Some formats might have response directly
                                        response_text = result["detail"]["response"]
                                        # Return a simple response structure for tool calling
                                        return {
                                            "source": "ollama",
                                            "response": response_text,
                                            "request_type": request_type,
                                            "timestamp": datetime.now().isoformat(),
                                        }, None
                    elif poll_error:
                        # Enhanced timeout handling for tool calls
                        if "timed out" in poll_error:
                            timeout_msg = f"""Tool call timed out after {self.ollama_timeout}s, but process still running.

🔄 **Background Process:**
  • Request ID: {request_id}  
  • Status: Processing in Ollama queue
  • Check: gtd request-status {request_id}

💡 **Alternatives:**
  • Use GTD CLI: gtd [command] (direct, no LLM)
  • Force Claude: Press Ctrl+F in TUI"""
                            return None, timeout_msg
                        else:
                            return None, f"Ollama tool call error: {poll_error}"
                
                # Extract choices - might be in result directly or in detail
                choices = None
                if "choices" in result and result["choices"]:
                    choices = result["choices"]
                    print(f"  ✅ Found choices in result directly ({len(choices)} choice(s))", file=sys.stderr)
                elif isinstance(result.get("detail"), dict) and "choices" in result.get("detail", {}):
                    choices = result["detail"]["choices"]
                    result = result["detail"]  # Use detail as the main result
                    print(f"  ✅ Found choices in result.detail ({len(choices)} choice(s))", file=sys.stderr)
                
                if not choices:
                    # Check if there's a direct response field (some formats)
                    response_text = None
                    if "response" in result:
                        response_text = result["response"]
                        print(f"  ✅ Found response field directly ({len(response_text)} chars)", file=sys.stderr)
                    elif isinstance(result.get("detail"), dict) and "response" in result.get("detail", {}):
                        response_text = result["detail"]["response"]
                        print(f"  ✅ Found response in result.detail ({len(response_text)} chars)", file=sys.stderr)
                    elif "message" in result and isinstance(result["message"], str):
                        # Some formats might have message as a string
                        response_text = result["message"]
                        print(f"  ✅ Found message field as string ({len(response_text)} chars)", file=sys.stderr)
                    elif isinstance(result.get("detail"), dict) and "message" in result.get("detail", {}):
                        detail_msg = result["detail"]["message"]
                        if isinstance(detail_msg, str):
                            response_text = detail_msg
                            print(f"  ✅ Found message in result.detail ({len(response_text)} chars)", file=sys.stderr)
                    
                    if response_text:
                        return {
                            "source": "ollama",
                            "response": response_text,
                            "request_type": request_type,
                            "timestamp": datetime.now().isoformat(),
                        }, None
                    
                    # Debug: log what we got
                    print(f"  ⚠️  No choices or response found in result. Keys: {list(result.keys())}", file=sys.stderr)
                    if "detail" in result:
                        print(f"  ⚠️  Detail keys: {list(result['detail'].keys()) if isinstance(result.get('detail'), dict) else 'not a dict'}", file=sys.stderr)
                    if "status" in result:
                        print(f"  ⚠️  Status: {result.get('status')}, Message: {result.get('message', 'N/A')}", file=sys.stderr)
                    return None, "No response from Ollama (no choices or response field found)"
                
                choice = choices[0]
                message = choice.get("message", {})
                
                # Check for tool calls
                tool_calls = message.get("tool_calls", [])
                response_text = message.get("content", "")
                
                # CRITICAL: Detect if AI is describing tool calls in text instead of using tool_calls
                # Common patterns: JSON objects, "method":"instructions", skill_name, etc.
                is_describing_tools = False
                if response_text:
                    response_lower = response_text.lower()
                    # Check for JSON-like tool descriptions
                    if ("method" in response_lower and "skill" in response_lower) or \
                       ("tool" in response_lower and "call" in response_lower) or \
                       ("gtd_" in response_lower and ("()" in response_text or "(" in response_text)) or \
                       (response_text.strip().startswith("{") and ("skill" in response_lower or "method" in response_lower)):
                        is_describing_tools = True
                        print(f"  🚨 DETECTED: AI is describing tools in text instead of using tool_calls!", file=sys.stderr)
                        print(f"  🚨 Response contains: {response_text[:200]}...", file=sys.stderr)
                
                # CRITICAL: If this is a data request and first iteration with no tool calls, force tool usage
                data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox", "log"]
                content_lower = content.lower() if content else ""
                is_data_request = any(keyword in content_lower for keyword in data_keywords)
                
                if is_data_request and iteration == 0 and (not tool_calls or is_describing_tools) and response_text:
                    # AI responded with text but no tools for a data request - this is wrong
                    # Force it to call tools by adding an enforcement message
                    print(f"  🚨 FORCING TOOL USAGE: Ollama responded with text but no tools for data request!", file=sys.stderr)
                    print(f"  🚨 Adding enforcement message to force tool calls...", file=sys.stderr)
                    
                    # Add the assistant's text response to messages (so it knows we saw it)
                    assistant_msg = {"role": "assistant", "content": response_text}
                    conversation_messages.append(assistant_msg)
                    
                    # Add enforcement message forcing tool usage
                    if is_describing_tools:
                        # Special message for when AI describes tools instead of calling them
                        enforcement_msg = "🚨 CRITICAL ERROR: You described tool calls in your text response (like {\"method\":\"instructions\"} or mentioning tool names), but you did NOT actually use the tool_calls field. This is WRONG. You MUST use the function calling API by including tool_calls in your response message, NOT by writing JSON or describing tools in the content field. Your response was ignored. Please make the actual tool calls NOW using the tool_calls field - DO NOT write text describing tools."
                    elif "runbook" in content_lower:
                        enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For runbook requests, you MUST call list_agent_skills(query='runbook') FIRST, then get_agent_skill(), then follow the runbook steps. Your text response was ignored. Please call the required tools NOW - DO NOT generate text, ONLY make tool calls."
                    elif "daily log" in content_lower or "log" in content_lower:
                        enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For daily log requests, you MUST call gtd_read_daily_log(date='today') FIRST. Your text response was ignored. Please call the required tool NOW - DO NOT generate text, ONLY make tool calls."
                    else:
                        enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For data requests, you MUST call tools FIRST (e.g., gtd_read_daily_log, gtd_list_tasks, list_agent_skills). Your text response was ignored. Please call the required tools NOW - DO NOT generate text, ONLY make tool calls."
                    
                    conversation_messages.append({
                        "role": "user",
                        "content": enforcement_msg
                    })
                    iteration += 1
                    continue  # Retry with enforcement message - don't accumulate this text response
                
                # Add assistant message to conversation
                # IMPORTANT: Always add assistant message if we have tool calls OR content
                # This is needed for the conversation flow
                if tool_calls:
                    # Has tool calls - add message with tool_calls
                    assistant_msg = {"role": "assistant", "tool_calls": tool_calls}
                    if response_text and response_text.strip():
                        assistant_msg["content"] = response_text
                    else:
                        # Tool calls but no content - that's fine, content can be null/empty
                        assistant_msg["content"] = None
                    conversation_messages.append(assistant_msg)
                elif response_text and response_text.strip():
                    # Has content but no tool calls - add message with content
                    conversation_messages.append({
                        "role": "assistant",
                        "content": response_text
                    })
                # If neither tool_calls nor content, don't add message (skip)
                
                # Accumulate text responses (even short ones if we don't have much)
                if response_text and response_text.strip():
                    # Accumulate any text response, not just long ones
                    # This ensures we capture responses even if they're brief
                    if accumulated_text:
                        accumulated_text += response_text + "\n"
                    else:
                        accumulated_text = response_text + "\n"
                
                if tool_calls:
                    # Execute tools
                    print(f"🔧 Ollama Iteration {iteration + 1}/{max_iterations}: Executing {len(tool_calls)} tool call(s)", file=sys.stderr)
                    tool_results = []
                    
                    for tool_call in tool_calls:
                        tool_id = tool_call.get("id", "")
                        function_info = tool_call.get("function", {})
                        tool_name = function_info.get("name", "")
                        tool_args_str = function_info.get("arguments", "{}")
                        
                        try:
                            tool_args = json.loads(tool_args_str) if isinstance(tool_args_str, str) else tool_args_str
                        except json.JSONDecodeError:
                            tool_args = {}
                        
                        print(f"  → Calling {tool_name} with args: {str(tool_args)[:100]}...", file=sys.stderr)
                        
                        # Execute tool
                        try:
                            functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
                            if not functions_dir.exists():
                                functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"
                            
                            if functions_dir.exists() and str(functions_dir) not in sys.path:
                                sys.path.insert(0, str(functions_dir))
                            
                            from gtd_tool_registry import execute_tool
                            tool_result = execute_tool(tool_name, tool_args)
                            
                            # Store tool execution details
                            if not hasattr(self, '_tool_execution_details'):
                                self._tool_execution_details = []
                            self._tool_execution_details.append({
                                "tool_name": tool_name,
                                "tool_args": tool_args,
                                "tool_result": tool_result,
                                "is_error": False
                            })
                            
                            tool_results.append({
                                "tool_call_id": tool_id,
                                "role": "tool",
                                "name": tool_name,
                                "content": str(tool_result)
                            })
                        except Exception as e:
                            error_msg = f"Error executing {tool_name}: {str(e)}"
                            print(f"  ❌ {error_msg}", file=sys.stderr)
                            
                            # Store error
                            if not hasattr(self, '_tool_execution_details'):
                                self._tool_execution_details = []
                            self._tool_execution_details.append({
                                "tool_name": tool_name,
                                "tool_args": tool_args,
                                "tool_result": error_msg,
                                "is_error": True
                            })
                            
                            tool_results.append({
                                "tool_call_id": tool_id,
                                "role": "tool",
                                "name": tool_name,
                                "content": error_msg
                            })
                    
                    # Add tool results to conversation
                    conversation_messages.extend(tool_results)
                    
                    # After adding tool results, we need to continue the loop
                    # to get a text response from Ollama based on the tool results
                    print(f"  ℹ️  Tool results added ({len(tool_results)} result(s)), continuing to get text response...", file=sys.stderr)
                    iteration += 1
                    # Continue loop to get text response after tool execution
                    continue
                else:
                    # No more tool calls in this iteration - check if we have a text response
                    # CRITICAL: After tool execution, we MUST get a text response
                    
                    # Check if tools were executed in previous iterations
                    current_tool_executions = getattr(self, '_tool_execution_details', [])
                    
                    if response_text and response_text.strip():
                        # We have a text response - use it
                        if accumulated_text and accumulated_text.strip():
                            # Merge accumulated and current
                            final_response = (accumulated_text.strip() + "\n\n" + response_text.strip()).strip()
                        else:
                            final_response = response_text.strip()
                        print(f"  ✅ Got final text response after tool execution ({len(final_response)} chars)", file=sys.stderr)
                        break
                    elif accumulated_text and accumulated_text.strip():
                        # We have accumulated text but no current response
                        final_response = accumulated_text.strip()
                        print(f"  ✅ Using accumulated text response ({len(final_response)} chars)", file=sys.stderr)
                        break
                    else:
                        # No text response yet - need to continue to get one
                        # This happens when tools were executed but AI hasn't generated text yet
                        # Check if we have tool execution details (meaning tools were executed)
                        current_tool_executions = getattr(self, '_tool_execution_details', [])
                        if current_tool_executions:
                            # Tools were executed, but no text response - continue to get one
                            print(f"  ℹ️  Tools executed ({len(current_tool_executions)} tool(s)) but no text response yet - continuing to get final response...", file=sys.stderr)
                            
                            # Check if we already added the assistant message with tool calls
                            # If not, add it now (should have been added above, but double-check)
                            last_msg = conversation_messages[-1] if conversation_messages else None
                            if not last_msg or last_msg.get("role") != "assistant" or "tool_calls" not in last_msg:
                                # Assistant message with tool calls wasn't added - add it now
                                if tool_calls:
                                    conversation_messages.append({
                                        "role": "assistant",
                                        "tool_calls": tool_calls,
                                        "content": None
                                    })
                                elif response_text:
                                    conversation_messages.append({
                                        "role": "assistant",
                                        "content": response_text
                                    })
                            
                            # Add a prompt to encourage text response after tool execution
                            # Only add if we haven't already added a similar prompt
                            last_user_msg = None
                            for msg in reversed(conversation_messages):
                                if msg.get("role") == "user":
                                    last_user_msg = msg.get("content", "")
                                    break
                            
                            if "provide a text response" not in (last_user_msg or "").lower():
                                conversation_messages.append({
                                    "role": "user",
                                    "content": "Based on the tool results above, please provide a text response summarizing what you found and your analysis. Do not make additional tool calls - just provide your response in text."
                                })
                            
                            iteration += 1
                            if iteration >= max_iterations:
                                # Hit max iterations - use accumulated text or error
                                if accumulated_text and accumulated_text.strip():
                                    final_response = accumulated_text.strip()
                                    print(f"  ⚠️  Max iterations reached, using accumulated text", file=sys.stderr)
                                    break
                                else:
                                    # No response at all
                                    error_msg = f"Max iterations ({max_iterations}) reached. Tools were executed but AI didn't generate a final text response."
                                    print(f"  ❌ ERROR: {error_msg}", file=sys.stderr)
                                    return None, error_msg
                            continue
                        else:
                            # No tools and no text - this shouldn't happen, but handle it
                            final_response = response_text.strip() if response_text else ""
                            if not final_response:
                                print(f"  ⚠️  No tools executed and no text response", file=sys.stderr)
                            break
            
            if final_response is None:
                if accumulated_text:
                    final_response = accumulated_text.strip()
                else:
                    # No response at all - this is an error
                    error_msg = "No final response from Ollama after tool calls"
                    print(f"  ❌ ERROR: {error_msg}", file=sys.stderr)
                    if tool_execution_details:
                        print(f"  ℹ️  Note: {len(tool_execution_details)} tool(s) were executed but no text response was generated", file=sys.stderr)
                    return None, error_msg
            
            # Ensure we have a non-empty response
            if not final_response or not final_response.strip():
                # Empty response - use a fallback message
                if tool_execution_details:
                    final_response = "⚠️ AI generated an empty response, but tools were executed. Check tool execution details above."
                else:
                    final_response = "⚠️ AI generated an empty response. This may indicate an error."
                print(f"  ⚠️  WARNING: Empty response from Ollama, using fallback message", file=sys.stderr)
            
            # Collect tool execution details
            tool_execution_details = getattr(self, '_tool_execution_details', [])
            if hasattr(self, '_tool_execution_details'):
                delattr(self, '_tool_execution_details')
            
            return {
                "source": "ollama",
                "response": final_response,
                "request_type": request_type,
                "timestamp": datetime.now().isoformat(),
                "tool_executions": tool_execution_details,
            }, None

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
        # Initialize tool execution details tracking for this request
        self._tool_execution_details = []
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
                # Include GTD tools, skills, and knowledge organization (exclude sequential_thinking - only available in Cursor IDE)
                gtd_tools = get_tool_definitions(categories=["gtd", "skills", "knowledge_organization"])
                
                # Convert OpenAI format to Anthropic format
                for tool in gtd_tools:
                    tools.append({
                        "name": tool["function"]["name"],
                        "description": tool["function"]["description"],
                        "input_schema": tool["function"]["parameters"]
                    })
                
                # Verify skill tools are loaded (for debugging - always show in interactive mode)
                skill_tool_names = [t["name"] for t in tools if "skill" in t["name"].lower()]
                gtd_tool_names = [t["name"] for t in tools if t["name"].startswith("gtd_")]
                
                # In interactive mode, always show tool loading status
                if context and context.get("interactive", False):
                    print(f"  ✓ Loaded {len(tools)} total tools ({len(gtd_tool_names)} GTD tools, {len(skill_tool_names)} skill tools)", file=sys.stderr)
                    if skill_tool_names:
                        print(f"  ✓ Skill tools: {', '.join(skill_tool_names)}", file=sys.stderr)
                elif skill_tool_names and context and context.get("verbose", False):
                    # Log to stderr so it's visible but doesn't interfere with output
                    print(f"  ✓ Loaded {len(skill_tool_names)} skill tools: {', '.join(skill_tool_names)}", file=sys.stderr)
            except Exception as e:
                # If tool loading fails, continue without tools
                # sys is already imported at module level
                import traceback
                print(f"⚠️  Could not load GTD tools: {e}", file=sys.stderr)
                if context and context.get("verbose", False):
                    traceback.print_exc(file=sys.stderr)

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
                    system_message += "\n\nCRITICAL: When reading personalization data, ONLY use information that is actually in the file. DO NOT make up, infer, or assume details that aren't explicitly stored. If the personalization data doesn't contain specific information, say you don't have that information rather than guessing."
                
                # Mention Second Brain search if available
                if "gtd_search_second_brain" in tool_names:
                    system_message += "\n\nIMPORTANT: You have access to the user's Second Brain (personal knowledge base) via gtd_search_second_brain. This contains their notes, Pathfinder campaign sessions, and other personal information. When the user asks about topics that might be in their notes (like Pathfinder content, campaign details, characters, etc.), use gtd_search_second_brain to search for relevant information. The search is case-insensitive and searches both filenames and content."
                    system_message += "\n\n🚨🚨🚨 CRITICAL ANTI-HALLUCINATION RULES FOR SEARCH RESULTS 🚨🚨🚨"
                    system_message += "\n\nWhen you get search results from gtd_search_second_brain or gtd_search_vector_database:"
                    system_message += "\n  ✅ ONLY state information that is EXPLICITLY written in the search results"
                    system_message += "\n  ✅ Quote directly from the 'content', 'content_preview', or 'content_text' fields when stating facts"
                    system_message += "\n  ✅ If search results show a file path but no content, say 'I found a file but cannot see its contents'"
                    system_message += "\n  ✅ If search results are empty or don't contain the information, say 'I don't have that information in the search results'"
                    system_message += "\n  ❌ DO NOT infer, assume, or make up details that aren't in the search results"
                    system_message += "\n  ❌ DO NOT add information that seems logical but isn't explicitly stated"
                    system_message += "\n  ❌ DO NOT combine information from multiple sources unless explicitly stated in results"
                    system_message += "\n  ❌ DO NOT make up professions, hobbies, interests, or details about people mentioned"
                    system_message += "\n  ❌ DO NOT extrapolate or add context that isn't in the results"
                    system_message += "\n\nExample of CORRECT behavior:"
                    system_message += "\n  Search result: 'Louiza is my partner. She is a foodie.'"
                    system_message += "\n  ✅ CORRECT: 'Based on your notes, Louiza is your partner and she is a foodie.'"
                    system_message += "\n  ❌ WRONG: 'Louiza is your partner, a foodie, and works as a graphic designer' (graphic designer not in results)"
                    system_message += "\n\nExample of CORRECT behavior when information is missing:"
                    system_message += "\n  Search result: 'Louiza is my partner.'"
                    system_message += "\n  ✅ CORRECT: 'I found that Louiza is your partner, but I don't have information about her profession, interests, or other details in the search results.'"
                    system_message += "\n  ❌ WRONG: 'Louiza is your partner and works as a graphic designer' (making up profession)"
                    system_message += "\n  ❌ WRONG: 'Louiza is your partner and enjoys cooking' (making up interests)"
                    system_message += "\n\n🚨 IF YOU STATE ANY INFORMATION NOT EXPLICITLY IN THE SEARCH RESULTS, YOU ARE HALLUCINATING."
                    system_message += "\n🚨 WHEN IN DOUBT, SAY YOU DON'T HAVE THAT INFORMATION - DO NOT GUESS OR MAKE IT UP."
                
                if "gtd_update_personalization" in tool_names:
                    system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n🧠 PERSONALIZATION LEARNING - AUTOMATIC UPDATES ENABLED 🧠"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n\n✅ YOU CAN AUTOMATICALLY UPDATE PERSONALIZATION DATA"
                    system_message += "\n\nWhen you discover new, reliable information about the user during conversations, you should update their personalization data using gtd_update_personalization. This helps the system learn about them and provide better assistance over time."
                    system_message += "\n\n📝 Examples of what to learn and save:"
                    system_message += "\n  - Relationships: Partner name (e.g., 'Louiza'), family members, important people"
                    system_message += "\n    - Relationship details: Use dot notation to store detailed information about people"
                    system_message += "\n    - Examples:"
                    system_message += "\n      * 'partner.interests' for hobbies/interests (e.g., 'foodie', 'cooking') - use operation='append'"
                    system_message += "\n      * 'partner.birthday' for birthdays (e.g., 'February') - use operation='set'"
                    system_message += "\n      * 'partner.gift_ideas' for gift suggestions (e.g., 'watch band') - use operation='append'"
                    system_message += "\n      * 'partner.preferences' for preferences (favorite foods, activities) - use operation='append'"
                    system_message += "\n      * 'partner.notes' for any other relevant details - use operation='append'"
                    system_message += "\n  - Goals: Career goals, personal goals, learning objectives (e.g., 'learning Kubernetes for CKA exam')"
                    system_message += "\n  - Energy patterns: Peak productivity hours (e.g., '9-12 AM'), what recharges them, what drains them"
                    system_message += "\n  - Communication style: Preferred tone, detail level, feedback style"
                    system_message += "\n  - Work patterns: Typical schedule, focus duration, on-call patterns"
                    system_message += "\n  - Lessons learned: What works for them, what doesn't work, effective strategies"
                    system_message += "\n\n✅ WHEN TO UPDATE:"
                    system_message += "\n  - User explicitly states information: 'My partner is Louiza'"
                    system_message += "\n  - Pattern is clear: User consistently mentions morning productivity"
                    system_message += "\n  - Goal is mentioned: 'I'm working toward my CKA exam'"
                    system_message += "\n  - Preference is expressed: 'I prefer direct communication'"
                    system_message += "\n\n❌ WHEN NOT TO UPDATE:"
                    system_message += "\n  - Information is uncertain or inferred"
                    system_message += "\n  - It's a one-time mention that might not be important"
                    system_message += "\n  - You're guessing or assuming"
                    system_message += "\n  - Information conflicts with existing data (verify first)"
                    system_message += "\n\n🔧 HOW TO UPDATE:"
                    system_message += "\n  - Use gtd_update_personalization(category='...', field='...', value='...', operation='set'|'append'|'remove')"
                    system_message += "\n  - Use 'set' to set/replace a value"
                    system_message += "\n  - Use 'append' to add to a list (e.g., goals, energy rechargers)"
                    system_message += "\n  - Use 'remove' to remove from a list"
                    system_message += "\n  - Use the 'personalization-learning' skill for detailed guidance on categories and fields"
                    system_message += "\n\n💡 BEST PRACTICES:"
                    system_message += "\n  - Update in the background when possible - don't interrupt conversation flow"
                    system_message += "\n  - Acknowledge briefly if appropriate: 'I'll remember that [information] for future conversations'"
                    system_message += "\n  - Be discreet - let the update happen naturally as part of the conversation"
                    system_message += "\n  - If uncertain, ask for confirmation: 'Should I remember that [information] for future conversations?'"
                    system_message += "\n\n🚨 CRITICAL: When updating personalization, ONLY save information that was explicitly stated by the user. DO NOT make up, infer, or assume details. If you're uncertain, ask the user to confirm before updating. When reading personalization data, ONLY use information that is actually in the file - do not add details that aren't there."
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n🚨🚨🚨 MANDATORY: TOOL-FIRST RESPONSE RULE 🚨🚨🚨"
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n\n⚠️ CRITICAL: If the user asks about ANY data (tasks, projects, logs, inbox, notes, personalization, skills, runbooks), you MUST call the appropriate tool FIRST before generating ANY response text."
                system_message += "\n\n🚨 CRITICAL: YOU MUST USE THE FUNCTION CALLING API - NOT DESCRIBE IT IN TEXT"
                system_message += "\n  - DO NOT write text like 'Tool Call: gtd_list_tasks()' or 'I will call gtd_read_daily_log()'"
                system_message += "\n  - DO NOT describe what tools you would call"
                system_message += "\n  - YOU MUST actually use the function calling API by including tool_use blocks in your response"
                system_message += "\n  - When you need data, your response should have tool_use blocks, NOT text describing tools"
                system_message += "\n\n❌ ABSOLUTELY FORBIDDEN:"
                system_message += "\n  - Writing text that describes tool calls (e.g., 'Tool Call: gtd_list_tasks()')"
                system_message += "\n  - Saying 'I will call...' or 'Let me check...' - JUST CALL THE TOOLS"
                system_message += "\n  - Responding with text before calling tools for data queries"
                system_message += "\n  - Making up, inventing, or guessing any data"
                system_message += "\n  - Mentioning specific task/project/log names without tool calls"
                system_message += "\n  - Describing what you would do instead of doing it"
                system_message += "\n  - Creative/fictional responses when user asks for data"
                system_message += "\n  - Any response that doesn't use actual tool results"
                system_message += "\n\n✅ MANDATORY FLOW FOR DATA QUERIES:"
                system_message += "\n  1. User asks about data (e.g., 'review my daily log', 'what tasks do I have', 'use the runbook')"
                system_message += "\n  2. YOU: IMMEDIATELY make tool call(s) - NO TEXT RESPONSE YET"
                system_message += "\n  3. Wait for tool result(s)"
                system_message += "\n  4. THEN and ONLY THEN generate response using ACTUAL tool results"
                system_message += "\n\n✅ REQUIRED TOOL CALLS:"
                system_message += "\n  - 'review daily log' / 'daily log' → MUST CALL gtd_read_daily_log(date='today') FIRST"
                system_message += "\n  - 'use runbook' / 'follow runbook' → MUST CALL list_agent_skills(query='runbook') THEN get_agent_skill() FIRST"
                system_message += "\n  - 'tasks' / 'my tasks' → MUST CALL gtd_list_tasks() FIRST"
                system_message += "\n  - 'projects' / 'my projects' → MUST CALL gtd_list_projects() FIRST"
                system_message += "\n  - 'inbox' → MUST CALL gtd_get_inbox_count() or gtd_list_inbox_items() FIRST"
                system_message += "\n  - 'personalization' / 'about me' → MUST CALL gtd_get_personalization() FIRST"
                system_message += "\n  - 'search notes' / 'second brain' → MUST CALL gtd_search_second_brain() FIRST"
                system_message += "\n  - 'skills' / 'workflows' / 'what can you do' → MUST CALL list_agent_skills() FIRST"
                system_message += "\n\n❌ WRONG EXAMPLES (DO NOT DO THIS):"
                system_message += "\n  User: 'Review my daily log'"
                system_message += "\n  ❌ WRONG: 'I'd be happy to review your daily log! Let me check...' [then responds with made-up content]"
                system_message += "\n  ❌ WRONG: Any creative/fictional response about pickles, squirrels, or unrelated topics"
                system_message += "\n  ❌ WRONG: 'Your log shows Project Alpha and Task: Report Generation' [without calling tools]"
                system_message += "\n\n✅ CORRECT EXAMPLES (DO THIS):"
                system_message += "\n  User: 'Review my daily log'"
                system_message += "\n  ✅ CORRECT: [IMMEDIATELY call gtd_read_daily_log(date='today') with content=null]"
                system_message += "\n  ✅ CORRECT: Wait for result, then respond with ACTUAL log content"
                system_message += "\n\n  User: 'Use the runbook to review my daily log'"
                system_message += "\n  ✅ CORRECT: [IMMEDIATELY call list_agent_skills(query='runbook')]"
                system_message += "\n  ✅ CORRECT: [Then call get_agent_skill(skill_name='daily-log-review-runbook')]"
                system_message += "\n  ✅ CORRECT: [Then follow runbook steps, calling gtd_read_daily_log(date='today') FIRST]"
                system_message += "\n\n🚨 IF YOU DON'T HAVE TOOL RESULTS, YOU DON'T HAVE DATA. DO NOT MAKE UP DATA."
                system_message += "\n🚨 IF USER ASKS FOR DATA, YOU MUST CALL TOOLS FIRST. NO EXCEPTIONS."
                system_message += "\n🚨 IF TOOLS RETURN EMPTY/NOTHING, SAY SO. DO NOT INVENT DATA TO FILL THE VOID."
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
                # Check if user is asking for a runbook
                is_runbook_request = False
                is_interactive_runbook = False
                runbook_keywords = ["runbook", "daily log review", "review daily log", "follow the runbook", "use the runbook", "weekly review", "weekly-review", "morning review", "morning-review"]
                user_question_lower = content.lower() if content else ""
                
                # Check current message for runbook request
                for keyword in runbook_keywords:
                    if keyword in user_question_lower:
                        is_runbook_request = True
                        # Check if it's an interactive runbook (weekly review, morning review, interactive runbooks)
                        # IMPORTANT: "weekly review" and "morning review" should ALWAYS use the interactive runbook, not the automated skill
                        if "weekly" in user_question_lower or "morning" in user_question_lower or "interactive" in user_question_lower:
                            is_interactive_runbook = True
                        break
                
                # ALSO check conversation history to see if we're already in an interactive runbook
                # This prevents restarting the runbook on follow-up messages
                if context and context.get("conversation_history"):
                    conversation_text = " ".join([
                        msg.get("content", "") for msg in context.get("conversation_history", [])
                        if isinstance(msg.get("content"), str)
                    ]).lower()
                    
                    # Check if previous messages mention weekly review, morning review, or interactive runbook
                    # IMPORTANT: If "weekly review" or "morning review" was mentioned, it should ALWAYS be interactive
                    if ("weekly review" in conversation_text or "weekly-review" in conversation_text or 
                        "morning review" in conversation_text or "morning-review" in conversation_text or
                        ("interactive" in conversation_text and "runbook" in conversation_text)):
                        is_interactive_runbook = True
                        # If we're in an interactive runbook, treat this as a continuation
                        if not is_runbook_request:
                            is_runbook_request = True  # Continue runbook mode
                
                # CRITICAL: If user says "weekly review" or "morning review" without "runbook", they likely mean the interactive runbook
                # The automated skills should only be used if explicitly requested
                if "weekly review" in user_question_lower and "runbook" not in user_question_lower:
                    # Default to interactive runbook for "weekly review" requests
                    is_interactive_runbook = True
                    is_runbook_request = True
                    print(f"  ℹ️  Detected 'weekly review' - defaulting to INTERACTIVE runbook (weekly-review-runbook)", file=sys.stderr)
                elif "morning review" in user_question_lower:
                    # Default to interactive runbook for "morning review" requests
                    is_interactive_runbook = True
                    is_runbook_request = True
                    print(f"  ℹ️  Detected 'morning review' - defaulting to INTERACTIVE runbook (interactive-morning-review-runbook)", file=sys.stderr)
                
                if is_runbook_request:
                    system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n🚨🚨🚨 RUNBOOK REQUEST DETECTED - MANDATORY WORKFLOW 🚨🚨🚨"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n\n⚠️ CRITICAL: The user asked to use a RUNBOOK. You MUST follow this exact workflow:"
                    system_message += "\n\n📋 STEP-BY-STEP MANDATORY WORKFLOW:"
                    system_message += "\n  1. IMMEDIATELY call list_agent_skills(query='runbook', runbooks_only=True) - NO TEXT, NO EXPLANATION, JUST THE TOOL CALL"
                    system_message += "\n  2. Wait for result, find 'Daily Log Review Runbook'"
                    system_message += "\n  3. IMMEDIATELY call get_agent_skill(skill_name='daily-log-review-runbook') - NO TEXT, JUST THE TOOL CALL"
                    system_message += "\n  4. Read the runbook instructions - it has 7 steps"
                    system_message += "\n  5. Follow Step 1: IMMEDIATELY call gtd_read_daily_log(date='today') - NO TEXT, JUST THE TOOL CALL"
                    system_message += "\n  6. Wait for tool result - this is the ACTUAL daily log data"
                    system_message += "\n  7. Use ONLY the actual log data returned - do NOT make up expenses, financial data, or any other information"
                    system_message += "\n  8. Continue with runbook Step 2: Analyze the ACTUAL log structure"
                    system_message += "\n  9. Continue with runbook Step 3: Cross-reference with GTD system (call gtd_list_tasks(), gtd_list_projects())"
                    system_message += "\n  10. Continue with remaining runbook steps using ACTUAL data only"
                    system_message += "\n  11. ONLY generate final text response AFTER completing all runbook steps with tool calls"
                    system_message += "\n\n❌ ABSOLUTELY FORBIDDEN WHEN RUNBOOK IS REQUESTED:"
                    system_message += "\n  - Making up financial data, expenses, or any data not in tool results"
                    system_message += "\n  - Responding with text before calling list_agent_skills()"
                    system_message += "\n  - Describing what you would do instead of doing it"
                    system_message += "\n  - Skipping tool calls"
                    system_message += "\n  - Creative/fictional responses (expenses, financial stability quests, etc.)"
                    system_message += "\n  - Any response that doesn't match the actual daily log content"
                    system_message += "\n\n✅ VALIDATION CHECK: Before generating your final response, verify:"
                    system_message += "\n  - Did I call gtd_read_daily_log()? ✓"
                    system_message += "\n  - Did I get the actual log content? ✓"
                    system_message += "\n  - Does my response mention ONLY things from the actual log? ✓"
                    system_message += "\n  - Am I NOT making up expenses, financial data, or unrelated information? ✓"
                    system_message += "\n\n🚨 IF YOU MENTION EXPENSES, FINANCIAL DATA, OR ANYTHING NOT IN THE ACTUAL LOG, YOU ARE HALLUCINATING."
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    
                    # Special handling for INTERACTIVE runbooks (weekly review, etc.)
                    if is_interactive_runbook:
                        system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        system_message += "\n🎯🎯🎯 INTERACTIVE RUNBOOK - CRITICAL INTERACTION RULES 🎯🎯🎯"
                        system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                        system_message += "\n\n⚠️ THIS IS AN INTERACTIVE RUNBOOK - YOU MUST FOLLOW THESE RULES:"
                        system_message += "\n\n🚨 **MANDATORY: Use the CORRECT interactive runbook skill**"
                        system_message += "\n  - For 'weekly review': get_agent_skill(skill_name='weekly-review-runbook')"
                        system_message += "\n  - For 'morning review': get_agent_skill(skill_name='interactive-morning-review-runbook')"
                        system_message += "\n  - Do NOT use automated skills (weekly-review) - use the INTERACTIVE runbook versions"
                        system_message += "\n  - The 'weekly-review-runbook' is interactive and asks questions one at a time"
                        system_message += "\n  - The 'weekly-review' skill is automated and goes through all steps automatically"
                        system_message += "\n\n1. **ASK ONE QUESTION AT A TIME** - Do NOT ask multiple questions in one response"
                        system_message += "\n2. **WAIT FOR USER RESPONSE** - After asking a question, STOP and wait for the user to respond. DO NOT proceed to the next question."
                        system_message += "\n3. **DO NOT PROCEED AUTOMATICALLY** - Do NOT answer your own questions or proceed to the next step without user input"
                        system_message += "\n4. **NO RUSHING** - Do NOT try to complete all steps in one response. This is a conversation, not a checklist"
                        system_message += "\n5. **ADAPT TO RESPONSES** - Listen to what the user says and adapt your follow-up questions based on their answers"
                        system_message += "\n6. **SHOW GENUINE INTEREST** - Acknowledge their insights, celebrate wins, ask follow-up questions that show you're listening"
                        system_message += "\n7. **CONTINUE THE CONVERSATION** - If the user just responded to your question, acknowledge their answer and ask the NEXT question. Do NOT restart the runbook or repeat previous questions."
                        system_message += "\n8. **USE THE CORRECT RUNBOOK** - If user asks for 'morning review', use 'interactive-morning-review-runbook'. If user asks for 'weekly review', use 'weekly-review-runbook'. Do NOT mix them up."
                        system_message += "\n9. **COMPLETE THE RUNBOOK PROPERLY** - When you reach the final step (Summary), provide a complete summary, ask final questions, and then give a clear completion message."
                        system_message += "\n   After the user confirms completion, mark the runbook as finished. Do NOT restart or loop back to Step 1."
                        system_message += "\n\n🚨🚨🚨 CRITICAL: DO NOT HAVE A CONVERSATION WITH YOURSELF 🚨🚨🚨"
                        system_message += "\n\n❌ ABSOLUTELY FORBIDDEN - YOU WILL BE REJECTED IF YOU DO THIS:"
                        system_message += "\n  - Asking a question and then providing an answer in <result> tags"
                        system_message += "\n  - Asking 'How are you feeling?' and then saying '<result>I'm feeling good</result>'"
                        system_message += "\n  - Asking multiple questions and answering them yourself"
                        system_message += "\n  - Creating fake user responses or simulating conversations"
                        system_message += "\n  - Using <result> tags to provide answers to your own questions"
                        system_message += "\n\n✅ CORRECT BEHAVIOR:"
                        system_message += "\n  - Ask ONE question: 'How are you feeling right now?'"
                        system_message += "\n  - STOP. End your response. Wait for the ACTUAL user to type their answer"
                        system_message += "\n  - Do NOT include any <result> tags"
                        system_message += "\n  - Do NOT provide example answers"
                        system_message += "\n  - Do NOT continue to the next question"
                        system_message += "\n  - The user will respond in the TUI, then you'll see their actual response"
                        system_message += "\n  - ONLY THEN do you acknowledge their answer and ask the NEXT question"
                        system_message += "\n\n🔴 IF YOU SEE <result> TAGS IN YOUR RESPONSE, YOU ARE DOING IT WRONG"
                        system_message += "\n🔴 IF YOU ANSWER YOUR OWN QUESTIONS, YOU ARE DOING IT WRONG"
                        system_message += "\n🔴 IF YOU ASK MULTIPLE QUESTIONS IN ONE RESPONSE, YOU ARE DOING IT WRONG"
                        system_message += "\n\nThe pattern is: ONE question → STOP → Wait for REAL user input → Acknowledge → NEXT question"
                        system_message += "\n\n🚨 CRITICAL: DO NOT LOOP OR RESTART THE RUNBOOK"
                        system_message += "\n  - After Step 8 is complete, mark the runbook as finished"
                        system_message += "\n  - Do NOT restart from Step 1 after completion"
                        system_message += "\n  - Do NOT skip steps or jump around"
                        system_message += "\n  - Progress sequentially: Step 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → Complete"
                        system_message += "\n\n❌ ABSOLUTELY FORBIDDEN IN INTERACTIVE RUNBOOKS:"
                        system_message += "\n  - Using automated skills (weekly-review) instead of interactive runbooks (weekly-review-runbook, interactive-morning-review-runbook)"
                        system_message += "\n  - Asking a question and then immediately answering it yourself"
                        system_message += "\n  - Using <result> tags to provide answers to your own questions"
                        system_message += "\n  - Creating fake user responses or simulating conversations"
                        system_message += "\n  - Asking multiple questions in sequence without waiting for responses"
                        system_message += "\n  - Running the WRONG runbook (e.g., weekly review when user asked for morning review)"
                        system_message += "\n  - Proceeding to the next step without waiting for user response"
                        system_message += "\n  - Asking multiple questions at once"
                        system_message += "\n  - Rushing through all steps in one response"
                        system_message += "\n  - Ignoring what the user says and just following a script"
                        system_message += "\n  - Completing all 8 steps in a single response"
                        system_message += "\n  - Having a conversation with yourself (asking and answering your own questions)"
                        system_message += "\n  - RESTARTING the runbook when the user responds (continue from where you left off!)"
                        system_message += "\n  - Repeating questions you already asked"
                        system_message += "\n  - Providing example answers or placeholder responses"
                        system_message += "\n\n✅ CORRECT BEHAVIOR - FOLLOW THIS EXACTLY:"
                        system_message += "\n  - If starting fresh: Ask ONE question ONLY (e.g., 'Good morning! How are you feeling right now?')"
                        system_message += "\n  - END YOUR RESPONSE IMMEDIATELY after asking the question"
                        system_message += "\n  - Do NOT include any example answers, <result> tags, or follow-up questions"
                        system_message += "\n  - The user will type their answer in the TUI and send it"
                        system_message += "\n  - When you receive their ACTUAL response: Acknowledge what they said, then ask the NEXT question"
                        system_message += "\n  - This creates a REAL conversation with a REAL human, not a simulated one"
                        system_message += "\n  - Progress through the runbook steps sequentially based on their ACTUAL responses"
                        system_message += "\n\n📝 EXAMPLE OF CORRECT BEHAVIOR:"
                        system_message += "\n  You: 'Good morning! How are you feeling right now? What's your energy level like on a scale of 1-10?'"
                        system_message += "\n  [END RESPONSE IMMEDIATELY - DO NOT ADD ANYTHING ELSE]"
                        system_message += "\n  User types: 'I'm feeling pretty good, energy is about 7/10'"
                        system_message += "\n  You: 'That's great! A 7/10 is solid energy. Let's make the most of it. What was the most important thing you accomplished yesterday?'"
                        system_message += "\n  [END RESPONSE IMMEDIATELY - DO NOT ADD ANYTHING ELSE]"
                        
                        system_message += "\n\n🚨🚨🚨 CRITICAL: YOUR RESPONSE MUST END IMMEDIATELY AFTER THE QUESTION 🚨🚨🚨"
                        system_message += "\n  - If you ask 'How are you feeling?', your response ENDS with the question mark"
                        system_message += "\n  - DO NOT add: 'Ooh, interesting! Let's dive in...'"
                        system_message += "\n  - DO NOT add: 'Share your thoughts, I'm listening!'"
                        system_message += "\n  - DO NOT add: 'Wonderful! On to the next step!'"
                        system_message += "\n  - DO NOT add follow-up questions in the same response"
                        system_message += "\n  - DO NOT add explanations or elaborations"
                        system_message += "\n  - JUST ASK THE QUESTION, THEN STOP"
                        system_message += "\n\n❌ EXAMPLE OF WRONG BEHAVIOR (DO NOT DO THIS):"
                        system_message += "\n  You: 'How are you feeling?'"
                        system_message += "\n  <result>I'm feeling good, energy is 7/10</result>"
                        system_message += "\n  'Great! Now what did you accomplish yesterday?'"
                        system_message += "\n  [THIS IS WRONG - YOU ANSWERED YOUR OWN QUESTION]"
                        system_message += "\n\n🚨🚨🚨 FINAL CRITICAL RULES 🚨🚨🚨"
                        system_message += "\n1. IF THE RUNBOOK SAYS 'Wait for Response', YOU MUST ACTUALLY WAIT FOR THE REAL USER TO TYPE THEIR ANSWER"
                        system_message += "\n2. DO NOT PROCEED TO THE NEXT STEP UNTIL THE USER HAS ACTUALLY RESPONDED"
                        system_message += "\n3. DO NOT RESTART THE RUNBOOK - CONTINUE FROM WHERE YOU LEFT OFF"
                        system_message += "\n4. DO NOT USE <result> TAGS - THESE ARE FOR TOOL RESULTS, NOT USER RESPONSES"
                        system_message += "\n5. DO NOT CREATE FAKE USER RESPONSES - WAIT FOR THE REAL USER TO TYPE IN THE TUI"
                        system_message += "\n6. IF YOU SEE YOURSELF ANSWERING YOUR OWN QUESTIONS, STOP IMMEDIATELY AND ASK ONLY ONE QUESTION"
                        system_message += "\n7. REMEMBER: The user is a REAL PERSON typing in the TUI. You will see their ACTUAL response in the next message."
                        system_message += "\n8. YOUR JOB: Ask ONE question, then STOP and wait for them to respond. That's it."
                        system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                else:
                    system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n📋 RUNBOOKS - MANDATORY FOR STRUCTURED PROCESSES"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n\nWhen user asks to 'review daily log', 'use the runbook', 'follow the runbook', or mentions 'daily log review runbook':"
                    system_message += "\n\n🚨 MANDATORY STEPS (DO NOT SKIP):"
                    system_message += "\n  1. IMMEDIATELY call list_agent_skills(query='runbook') - NO TEXT RESPONSE FIRST"
                    system_message += "\n  2. Find the 'Daily Log Review Runbook' in results"
                    system_message += "\n  3. IMMEDIATELY call get_agent_skill(skill_name='daily-log-review-runbook') - NO TEXT RESPONSE"
                    system_message += "\n  4. Read the runbook instructions carefully"
                    system_message += "\n  5. Follow Step 1: Call gtd_read_daily_log(date='today') - NO TEXT RESPONSE"
                    system_message += "\n  6. Wait for tool result"
                    system_message += "\n  7. Continue following ALL runbook steps in sequence"
                    system_message += "\n  8. ONLY generate text responses AFTER you have tool results"
                    system_message += "\n\n❌ FORBIDDEN:"
                    system_message += "\n  - Responding with text before calling list_agent_skills()"
                    system_message += "\n  - Describing what the runbook would do instead of following it"
                    system_message += "\n  - Skipping tool calls and making up responses"
                    system_message += "\n  - Creative/fictional responses instead of following the runbook"
                    system_message += "\n\n✅ CORRECT: Follow runbook steps exactly, call tools first, use actual results only."
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n✅ RESPONSE VALIDATION - BEFORE YOU RESPOND"
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n\nBefore generating your final text response, ask yourself:"
                system_message += "\n  1. Did I call the required tools? (gtd_read_daily_log, gtd_list_tasks, etc.)"
                system_message += "\n  2. Did I get actual tool results?"
                system_message += "\n  3. Does my response mention ONLY things from the tool results?"
                system_message += "\n  4. Am I NOT making up data (expenses, financial info, task names, project names)?"
                system_message += "\n  5. Am I NOT inferring connections or meanings between user statements and tool results?"
                system_message += "\n  6. Am I stating tool results as facts without adding interpretation or assumptions?"
                system_message += "\n  7. If the user asked for a runbook, did I follow ALL runbook steps?"
                system_message += "\n\n🚨 IF YOUR RESPONSE MENTIONS DATA NOT IN TOOL RESULTS, YOU ARE HALLUCINATING."
                system_message += "\n🚨 IF TOOL RESULTS ARE EMPTY, SAY 'No data found' - DO NOT MAKE UP DATA."
                system_message += "\n🚨 FOR ALL TOOL RESULTS (calendar, tasks, logs, search, personalization, etc.):"
                system_message += "\n  - ONLY state information that is EXPLICITLY written in the tool results"
                system_message += "\n  - VERIFY the tool result actually contains the information before stating it"
                system_message += "\n  - If calendar tool shows 'No events' or empty, say 'No events scheduled' - DO NOT make up events"
                system_message += "\n  - If calendar tool shows specific events, quote them exactly - DO NOT add events that aren't there"
                system_message += "\n  - DO NOT infer connections, relationships, or meanings between different pieces of information"
                system_message += "\n  - DO NOT say things 'align' or 'confirm' unless explicitly stated in the results"
                system_message += "\n  - DO NOT add context, interpretation, or assumptions beyond what's in the results"
                system_message += "\n  - If a calendar shows 'Wedding Planning Meeting', state that - DO NOT infer it means you're getting married"
                system_message += "\n  - If user says something and tool shows related data, state both separately - DO NOT assume they're connected"
                system_message += "\n  - Quote directly from tool results when stating facts"
                system_message += "\n  - If information is missing, say so - DO NOT make it up or infer it"
                system_message += "\n\n🚨 CRITICAL FOR CALENDAR TOOL:"
                system_message += "\n  - If the tool result shows 'No events' or 'No upcoming events', state that exactly"
                system_message += "\n  - If the tool result is empty or shows no events, DO NOT invent events"
                system_message += "\n  - ONLY report events that are EXPLICITLY listed in the tool result"
                system_message += "\n  - If you see 'Wedding Planning Meeting' in the result, it's real - if not, DO NOT make it up"
                system_message += "\n\n🚨 FOR SEARCH RESULTS (gtd_search_second_brain, gtd_search_vector_database):"
                system_message += "\n  - ONLY use information EXPLICITLY written in the search results"
                system_message += "\n  - DO NOT infer, assume, or add details that aren't in the results"
                system_message += "\n  - If information is missing, say so - DO NOT make it up"
                system_message += "\n  - Quote directly from results when stating facts"
                system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                system_message += "\n\nIMPORTANT WORKFLOW GUIDELINES:"
                system_message += "\n- For structured processes, use RUNBOOKS: Call list_agent_skills(query='runbook', runbooks_only=True) to find runbooks"
                system_message += "\n- Runbooks provide step-by-step procedures with validation - follow them exactly"
                system_message += "\n- For long workflows (like morning check-ins, reviews), break them into steps"
                system_message += "\n- After completing 2-3 tool calls, provide a progress update summarizing what you've done"
                system_message += "\n- Then ask if the user wants to continue or if they have questions"
                system_message += "\n- This allows interactive, back-and-forth conversation rather than one long response"
                system_message += "\n- If you hit rate limits or max iterations, summarize what you've accomplished and what remains"
                
                if skill_tools:
                    system_message += "\n\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\n🎯 AGENT SKILLS - CRITICAL INSTRUCTIONS"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    system_message += "\nYou have access to Agent Skills - reusable workflows that guide how to accomplish goals using GTD tools. Skills provide step-by-step instructions for complex workflows."
                    system_message += "\n\n🚨 MANDATORY: When the user asks ANY of these questions, you MUST call list_agent_skills() FIRST before responding:"
                    system_message += "\n   - 'what skills do you have'"
                    system_message += "\n   - 'what skills are available'"
                    system_message += "\n   - 'what can you do'"
                    system_message += "\n   - 'what capabilities are available'"
                    system_message += "\n   - 'what workflows can you help with'"
                    system_message += "\n   - 'show me your skills'"
                    system_message += "\n   - 'help me with [workflow name]' (e.g., 'help me with morning review')"
                    system_message += "\n   - 'can you help me [do something]' (e.g., 'can you help me process my inbox')"
                    system_message += "\n   - Any question about skills, capabilities, or workflows"
                    system_message += "\n\nDO NOT guess, make up, or describe skills from memory. ALWAYS call list_agent_skills() to get the actual, current list of available skills."
                    system_message += "\n\nTo use skills: (1) Call list_agent_skills() to discover available skills, (2) Call get_agent_skill(skill_name='...') to read a skill's full instructions, (3) Follow the skill's step-by-step workflow using the appropriate GTD tools."
                    system_message += "\n\nWhen a user asks for help with a workflow (like 'help me with my morning review' or 'can you help me process my inbox'), you MUST:"
                    system_message += "\n  1. First call list_agent_skills() with a query matching their request"
                    system_message += "\n  2. Then call get_agent_skill() to get the full workflow instructions"
                    system_message += "\n  3. Then follow the skill's instructions step-by-step, calling the appropriate GTD tools"
                    system_message += "\n\nDO NOT describe what you would do - actually execute the workflow by calling tools."
                    system_message += "\n\nEXAMPLES OF CORRECT BEHAVIOR:"
                    system_message += "\n  User: 'what skills do you have?'"
                    system_message += "\n  ✅ CORRECT: Call list_agent_skills() immediately, then list the results"
                    system_message += "\n  ❌ WRONG: Say 'I have skills like morning check-in, inbox processing...' without calling tools"
                    system_message += "\n\n  User: 'help me with my morning review'"
                    system_message += "\n  ✅ CORRECT: Call list_agent_skills(query='morning'), then get_agent_skill(), then follow the workflow"
                    system_message += "\n  ❌ WRONG: Describe what a morning review would involve without calling tools"
                    system_message += "\n\n  User: 'can you help me populate my second brain?'"
                    system_message += "\n  ✅ CORRECT: Call list_agent_skills(query='second brain'), then get_agent_skill(), then follow instructions"
                    system_message += "\n  ❌ WRONG: Describe how you would help without actually calling tools to see what's available"
                    system_message += "\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                
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

                        # CRITICAL: If this is a data request and first iteration with no tool calls, force tool usage
                        data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox", "log"]
                        user_question_lower = content.lower() if content else ""
                        is_data_request = any(keyword in user_question_lower for keyword in data_keywords)
                        
                        if is_data_request and iteration == 0 and not tool_calls and text_blocks:
                            # AI responded with text but no tools for a data request - this is wrong
                            # Force it to call tools by adding an enforcement message
                            print(f"  🚨 FORCING TOOL USAGE: AI responded with text but no tools for data request!", file=sys.stderr)
                            print(f"  🚨 Adding enforcement message to force tool calls...", file=sys.stderr)
                            
                            # Add the assistant's text response to messages (so it knows we saw it)
                            messages.append({
                                "role": "assistant",
                                "content": assistant_content
                            })
                            
                            # Add enforcement message forcing tool usage
                            if "runbook" in user_question_lower:
                                enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For runbook requests, you MUST call list_agent_skills(query='runbook') FIRST, then get_agent_skill(), then follow the runbook steps. Your text response was ignored. Please call the required tools NOW - DO NOT generate text, ONLY make tool calls."
                            elif "daily log" in user_question_lower or "log" in user_question_lower:
                                enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For daily log requests, you MUST call gtd_read_daily_log(date='today') FIRST. Your text response was ignored. Please call the required tool NOW - DO NOT generate text, ONLY make tool calls."
                            else:
                                enforcement_msg = "🚨 ERROR: You responded with text but did NOT call any tools. For data requests, you MUST call tools FIRST (e.g., gtd_read_daily_log, gtd_list_tasks, list_agent_skills). Your text response was ignored. Please call the required tools NOW - DO NOT generate text, ONLY make tool calls."
                            
                            messages.append({
                                "role": "user",
                                "content": enforcement_msg
                            })
                            iteration += 1
                            continue  # Retry with enforcement message - don't accumulate this text response
                        
                        # Accumulate any text responses (but don't use them until Claude is done)
                        if text_blocks:
                            new_text = "\n".join(text_blocks)
                            # Only accumulate if it's substantial (not just "okay" or similar)
                            if len(new_text.strip()) > 20:
                                accumulated_text += new_text + "\n"

                        if tool_calls:
                            # Execute tools and add results to messages
                            print(f"🔧 Iteration {iteration + 1}/{max_iterations}: Executing {len(tool_calls)} tool call(s)", file=sys.stderr)
                            print(f"  ✅ Tools are being called - this is correct!", file=sys.stderr)
                            for tc in tool_calls:
                                print(f"  → Tool: {tc.name} with args: {str(tc.input)[:100]}...", file=sys.stderr)
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
                                    
                                    # Store full result for transparency (before truncation)
                                    full_tool_result = tool_result
                                    
                                    # Limit tool result size to prevent token bloat
                                    if len(tool_result) > 8000:
                                        tool_result = tool_result[:8000] + "\n... (truncated)"
                                    
                                    if is_error:
                                        print(f"  ❌ {tool_name} returned error ({len(tool_result)} chars)", file=sys.stderr)
                                    else:
                                        print(f"  ✅ {tool_name} completed successfully ({len(tool_result)} chars)", file=sys.stderr)
                                    
                                    # Store tool execution details for transparency
                                    if not hasattr(self, '_tool_execution_details'):
                                        self._tool_execution_details = []
                                    self._tool_execution_details.append({
                                        "tool_name": tool_name,
                                        "tool_args": tool_args,
                                        "tool_result": full_tool_result,  # Store full result, not truncated
                                        "is_error": is_error
                                    })
                                    
                                    tool_results.append({
                                        "type": "tool_result",
                                        "tool_use_id": tool_id,
                                        "content": tool_result
                                    })
                                except Exception as e:
                                    import traceback
                                    error_msg = f"Error executing tool '{tool_name}': {str(e)}"
                                    print(f"  ❌ {error_msg}", file=sys.stderr)
                                    
                                    # Store error details for transparency
                                    if not hasattr(self, '_tool_execution_details'):
                                        self._tool_execution_details = []
                                    self._tool_execution_details.append({
                                        "tool_name": tool_name,
                                        "tool_args": tool_args,
                                        "tool_result": error_msg,
                                        "is_error": True
                                    })
                                    
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
                            # Check if we should have called tools
                            data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox"]
                            user_question_lower = content.lower() if content else ""
                            should_have_called_tools = any(keyword in user_question_lower for keyword in data_keywords)
                            
                            if should_have_called_tools and iteration == 0:
                                # First iteration and no tool calls for a data request - this is wrong
                                print(f"  ⚠️  WARNING: User asked about data but no tools were called in first response!", file=sys.stderr)
                                print(f"  ⚠️  This may result in hallucinated data!", file=sys.stderr)
                                print(f"  ⚠️  AI is responding with text instead of calling tools - this is INCORRECT behavior!", file=sys.stderr)
                            
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
                            
                            # CRITICAL: For interactive runbooks, validate that AI isn't answering its own questions
                            if is_interactive_runbook and final_response:
                                final_response = self._validate_interactive_runbook_response(final_response)
                            
                            print(f"  ✅ Got final text response ({len(final_response)} chars)", file=sys.stderr)
                            break  # Exit tool call loop

                    if final_response is None or not final_response.strip():
                        # If we hit max iterations but have accumulated text, use it
                        if accumulated_text.strip():
                            final_response = accumulated_text.strip()
                        else:
                            return None, f"Max tool call iterations ({max_iterations}) reached without final response. Claude may be stuck in a tool-calling loop."

                    # CRITICAL: For interactive runbooks, validate that AI isn't answering its own questions
                    if is_interactive_runbook and final_response:
                        final_response = self._validate_interactive_runbook_response(final_response)

                    # Collect all tool execution details for transparency
                    tool_execution_details = getattr(self, '_tool_execution_details', [])
                    
                    # CRITICAL: Validate that AI isn't hallucinating calendar events
                    if final_response and tool_execution_details:
                        final_response = self._validate_calendar_response(final_response, tool_execution_details)
                    
                    # Clear for next request
                    if hasattr(self, '_tool_execution_details'):
                        delattr(self, '_tool_execution_details')
                    
                    # Include tool execution details in the response for transparency
                    return {
                        "source": "claude",
                        "response": final_response,
                        "request_type": request_type,
                        "tool_execution_details": tool_execution_details  # Include tool details
                    }, None
                    
                    # Validation: Check if tools should have been called but weren't
                    data_keywords = ["daily log", "review", "runbook", "tasks", "projects", "inbox", "log"]
                    user_question_lower = content.lower() if content else ""
                    should_have_called_tools = any(keyword in user_question_lower for keyword in data_keywords)
                    
                    if should_have_called_tools and not tool_execution_details:
                        # AI responded without calling tools when it should have
                        warning = "\n\n⚠️ WARNING: You were asked about data but didn't call any tools. "
                        warning += "This response may contain hallucinated information. "
                        warning += "You should have called tools first (e.g., gtd_read_daily_log, gtd_list_tasks).\n\n"
                        final_response = warning + final_response
                        print(f"  ⚠️  WARNING: No tools called for data request!", file=sys.stderr)
                    
                    # If we used a fallback model, update the configured model for next time
                    if model_name != self.claude_model:
                        self.claude_model = model_name

                    return {
                        "source": "claude",
                        "response": final_response,
                        "request_type": request_type,
                        "timestamp": datetime.now().isoformat(),
                        "model": model_name,
                        "tool_executions": tool_execution_details,  # Include tool execution details
                        "_warnings": ["No tools called for data request"] if (should_have_called_tools and not tool_execution_details) else [],
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
        
        # Get persona system prompt if persona is provided
        persona_system_prompt = None
        if persona and persona in PERSONAS:
            persona_info = PERSONAS[persona]
            persona_system_prompt = persona_info.get("system_prompt", "")
            if not persona_system_prompt:
                # Fallback to name if no system prompt
                persona_name = persona_info.get("name", persona.capitalize())
                persona_system_prompt = f"You are {persona_name}."

        prompts = {
            "persona_response": {
                "system": persona_system_prompt or f"You are {persona or 'a helpful assistant'}. Provide a brief, in-character response.",
                "user": content,
            },
            "general_question": {
                "system": persona_system_prompt or "You are a helpful assistant.",
                "user": content,
            },
            "task_categorize": {
                "system": persona_system_prompt or "You are a GTD task categorization expert. Categorize tasks as either @computer, @phone, @errands, or @waiting-for.",
                "user": f"Categorize these tasks:\n{content}",
            },
            "task_suggest": {
                "system": persona_system_prompt or "You are a GTD task suggestion expert. Generate 3-5 actionable tasks from the given context.",
                "user": f"Suggest tasks from:\n{content}",
            },
            "similarity_search": {
                "system": persona_system_prompt or "You are helping find similar items. Return just the most relevant item.",
                "user": f"Find similar to:\n{content}",
            },
            "analyze_daily_log": {
                "system": persona_system_prompt or "You are a productivity coach analyzing daily logs. Provide insights and suggestions.",
                "user": f"Analyze this log:\n{content}",
            },
            "weekly_review": {
                "system": persona_system_prompt or "You are a strategic planning assistant. Analyze weekly patterns and provide insights.",
                "user": f"Review this week's data:\n{content}",
            },
            "strategy_planning": {
                "system": persona_system_prompt or "You are a strategic planning expert. Help plan an approach based on context.",
                "user": f"Help plan:\n{content}",
            },
        }

        # Default case - use persona if provided, otherwise default message
        default_system = persona_system_prompt or "You are a helpful assistant."
        return prompts.get(request_type, {"system": default_system, "user": content})

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
    
    def _validate_calendar_response(self, response: str, tool_execution_details: List[Dict[str, Any]]) -> str:
        """
        Validate that AI isn't hallucinating calendar events.
        If calendar tool was called and shows no events, but response mentions events, truncate.
        """
        import re
        
        # Check if calendar tool was called
        calendar_tool_called = False
        calendar_result = None
        
        for tool_detail in tool_execution_details:
            if "calendar" in tool_detail.get("tool_name", "").lower():
                calendar_tool_called = True
                calendar_result = tool_detail.get("tool_result", "")
                break
        
        if not calendar_tool_called:
            return response
        
        # Check if calendar result shows no events
        if calendar_result:
            calendar_lower = calendar_result.lower()
            has_no_events = any(phrase in calendar_lower for phrase in [
                "no events", "no upcoming events", "no events scheduled", 
                "no events found", "empty", "no meetings"
            ])
            
            # Check if response mentions specific calendar events
            response_lower = response.lower()
            # Look for patterns like "2:00 PM", "meeting", "event", etc. that suggest specific events
            has_event_mentions = bool(re.search(r'\d{1,2}:\d{2}\s*(AM|PM)', response_lower)) or \
                                bool(re.search(r'(meeting|event|appointment|scheduled)', response_lower))
            
            if has_no_events and has_event_mentions:
                # Calendar shows no events but response mentions events - this is hallucination
                print(f"  ⚠️  Detected calendar hallucination - calendar shows no events but response mentions events", file=sys.stderr)
                print(f"  ⚠️  Calendar result: {calendar_result[:200]}...", file=sys.stderr)
                # Return a safe response that doesn't mention specific events
                return "Your calendar shows no events scheduled for today."
        
        return response
    
    def _validate_interactive_runbook_response(self, response: str) -> str:
        """
        Validate interactive runbook response - truncate if AI is answering its own questions.
        
        This prevents the AI from asking a question and then immediately providing
        follow-up questions or answers in the same response.
        """
        import re
        
        if not response or not response.strip():
            return response
        
        # Find the first question mark
        first_question_idx = response.find('?')
        if first_question_idx == -1:
            # No question mark found - might be an acknowledgment, allow it
            return response
        
        # Get text after the first question
        after_question = response[first_question_idx + 1:].strip()
        
        # If there's no content after the question, it's fine
        if not after_question:
            return response
        
        # Check for patterns that indicate AI is answering its own question:
        # - Multiple question marks (asking follow-up questions)
        # - Phrases like "Ooh, interesting!", "Let's dive in", "Wonderful!", "On to the next step"
        # - Starting with "If you're feeling..." (providing conditional answers)
        # - Starting with "Share your thoughts" (follow-up prompts)
        
        problematic_patterns = [
            r'[Oo]oh,?\s+interesting',
            r"Let's\s+dive\s+in",
            r'[Ww]onderful',
            r'[Oo]n\s+to\s+the\s+next\s+step',
            r"If\s+you'?re\s+feeling",
            r'[Ss]hare\s+your\s+thoughts',
            r'[Ww]hat\s+could\s+help',
            r'[Hh]ow\s+can\s+we',
            r'[Gg]reat!',
            r'[Aa]lready\s+getting',
            r'[Ss]ense\s+of',
        ]
        
        # Check if after-question text contains problematic patterns
        for pattern in problematic_patterns:
            if re.search(pattern, after_question, re.IGNORECASE):
                # AI is answering its own question - truncate to just the first question
                truncated = response[:first_question_idx + 1].strip()
                print(f"  ⚠️  Detected AI answering own question - truncating response to: '{truncated[:50]}...'", file=sys.stderr)
                return truncated
        
        # Check for multiple questions in the same response (another sign of self-conversation)
        question_count = response.count('?')
        if question_count > 1:
            # Multiple questions - truncate to first question only
            truncated = response[:first_question_idx + 1].strip()
            print(f"  ⚠️  Detected multiple questions in one response - truncating to first question only", file=sys.stderr)
            return truncated
        
        # Response looks okay - return as-is
        return response

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
