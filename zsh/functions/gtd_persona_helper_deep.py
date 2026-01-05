#!/usr/bin/env python3
"""
GTD Persona Helper (Deep Model) - Wrapper that uses call_deep_ai instead of call_persona

This script provides the same interface as gtd_persona_helper.py but uses
call_deep_ai() (deep model) instead of call_persona() (chat model).

Usage: gtd_persona_helper_deep.py <persona> <content> [context]
"""

import sys
from pathlib import Path

# Add parent directories to path for imports
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent.parent
sys.path.insert(0, str(dotfiles_dir))
sys.path.insert(0, str(dotfiles_dir / "mcp"))
sys.path.insert(0, str(dotfiles_dir / "zsh" / "functions"))

try:
    from gtd_persona_helper import PERSONAS, read_config
    from mcp.gtd_deep_analysis_worker import call_deep_ai
except ImportError:
    # Try alternative paths
    sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
    sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "mcp"))
    try:
        from gtd_persona_helper import PERSONAS, read_config
        from gtd_deep_analysis_worker import call_deep_ai
    except ImportError:
        print("Error: Could not import required modules", file=sys.stderr)
        sys.exit(1)

def get_persona_system_prompt_simple(persona_key: str, config: dict) -> str:
    """Get system prompt for a persona (simplified version for reminders)."""
    if persona_key not in PERSONAS:
        return "You are a helpful assistant."
    
    persona_info = PERSONAS[persona_key]
    base_prompt = persona_info.get("system_prompt", "")
    
    # Add user name if available
    user_name = config.get("name", "").strip()
    if user_name and user_name != "User":
        if "{name}" in base_prompt or "{user}" in base_prompt:
            base_prompt = base_prompt.replace("{name}", user_name).replace("{user}", user_name)
        else:
            base_prompt = f"You are helping {user_name}. {base_prompt}"
    
    # Add instruction to sign response
    persona_name = persona_info.get("name", persona_key)
    base_prompt += f"\n\nIMPORTANT: Always sign your response with your name ({persona_name}) at the end. For example, end with \"— {persona_name}\" or \"- {persona_name}\" or similar."
    
    return base_prompt


def main():
    if len(sys.argv) < 3:
        print("Usage: gtd_persona_helper_deep.py <persona> <content> [context]")
        print(f"\nAvailable personas: {', '.join(PERSONAS.keys())}")
        sys.exit(1)
    
    persona_key = sys.argv[1].lower().strip()
    content = sys.argv[2]
    context = sys.argv[3] if len(sys.argv) > 3 else ""
    
    # Validate persona
    if persona_key not in PERSONAS:
        print(f"Error: Unknown persona '{persona_key}'. Available: {', '.join(PERSONAS.keys())}", file=sys.stderr)
        sys.exit(1)
    
    # Read config
    config = read_config()
    
    # Get system prompt for persona
    system_prompt = get_persona_system_prompt_simple(persona_key, config)
    
    # Build user prompt (add context if provided)
    user_prompt = content
    if context:
        user_prompt = f"Context: {context}\n\n{user_prompt}"
    
    # Call deep AI (use async mode for tool support)
    try:
        # Use async mode to support tool calls via Ollama Controller
        # Use reasonable max_tokens for reminders (2000 should be plenty)
        advice = call_deep_ai(
            prompt=user_prompt,
            system_prompt=system_prompt,
            max_tokens=2000,
            use_async=True,  # Use async mode for tool support
            max_poll_time=300.0  # 5 minutes should be enough for reminders
        )
        
        # Check if we got a request_id (queued request)
        if advice and advice.startswith("Request submitted: "):
            # Need to poll for result
            request_id = advice.replace("Request submitted: ", "")
            from gtd_ai_helpers import poll_async_response
            from mcp.gtd_deep_analysis_worker import DEEP_MODEL_URL
            
            base_url = DEEP_MODEL_URL.rsplit('/v1', 1)[0]
            polled_result, poll_error = poll_async_response(
                request_id=request_id,
                base_url=base_url,
                max_poll_time=300.0,  # 5 minutes
                poll_interval=2.0
            )
            
            if poll_error:
                print(f"Error: {poll_error}", file=sys.stderr)
                sys.exit(1)
            elif polled_result and 'choices' in polled_result:
                advice = polled_result['choices'][0]['message']['content']
            else:
                print("Error: Unexpected response format from async request", file=sys.stderr)
                sys.exit(1)
        
        # Check for errors
        if advice.startswith("Error:"):
            print(advice, file=sys.stderr)
            sys.exit(1)
        
        # Print response in same format as persona_helper
        persona_name = PERSONAS[persona_key]['name']
        print(f"\n💬 Advice from {persona_name}:")
        print("━" * 60)
        if advice and advice.strip():
            print(advice)
        else:
            print("(No response received from AI model)")
        print("━" * 60)
        
        sys.exit(0)
        
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()