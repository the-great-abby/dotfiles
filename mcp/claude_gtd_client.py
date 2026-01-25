#!/usr/bin/env python3
"""
Claude GTD Client - CLI interface for hybrid Claude + Ollama GTD system

Usage:
    claude-gtd persona <question> [--persona NAME]
    claude-gtd suggest <context>
    claude-gtd categorize <tasks>
    claude-gtd analyze <log_file>
    claude-gtd status
    claude-gtd mode <ollama-only|hybrid>
"""

import sys
import os
import json
import argparse
from pathlib import Path
from typing import Optional

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent))

from claude_ollama_bridge import SmartAIRouter, AIMode

# Import persona definitions
try:
    from zsh.functions.gtd_persona_helper import PERSONAS
except ImportError:
    # Try alternative path
    sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
    try:
        from gtd_persona_helper import PERSONAS
    except ImportError:
        PERSONAS = {}


class GTDClient:
    """Client for interacting with the hybrid AI system"""

    def __init__(self):
        """Initialize the client"""
        self.router = SmartAIRouter()

    def run(self, args: list) -> int:
        """Main entry point"""

        if not args:
            self._print_help()
            return 0

        command = args[0]
        command_args = args[1:] if len(args) > 1 else []

        try:
            if command == "persona":
                return self._handle_persona(command_args)
            elif command == "suggest":
                return self._handle_suggest(command_args)
            elif command == "categorize":
                return self._handle_categorize(command_args)
            elif command == "analyze":
                return self._handle_analyze(command_args)
            elif command == "status":
                return self._handle_status()
            elif command == "mode":
                return self._handle_mode(command_args)
            elif command == "ask":
                return self._handle_ask(command_args)
            elif command == "help":
                self._print_help()
                return 0
            else:
                print(f"❌ Unknown command: {command}", file=sys.stderr)
                self._print_help()
                return 1

        except Exception as e:
            print(f"❌ Error: {e}", file=sys.stderr)
            return 1

    def _handle_persona(self, args: list) -> int:
        """Handle persona advice request"""

        if not args:
            print("❌ Usage: claude-gtd persona <question> [--persona NAME]", file=sys.stderr)
            return 1

        # Parse arguments
        persona = "hank"  # Default
        question_parts = []
        i = 0

        while i < len(args):
            if args[i] == "--persona" and i + 1 < len(args):
                persona = args[i + 1]
                i += 2
            else:
                question_parts.append(args[i])
                i += 1

        if not question_parts:
            print("❌ Usage: claude-gtd persona <question> [--persona NAME]", file=sys.stderr)
            return 1

        question = " ".join(question_parts)

        print(f"🤖 Getting {persona}'s advice on: {question[:50]}...")

        result, error = self.router.route_request(
            "persona_response",
            question,
            persona=persona,
            context={"temperature": 0.8, "max_tokens": 300}
        )

        if error:
            print(f"❌ Error: {error}", file=sys.stderr)
            return 1

        print(f"\n💭 {persona.capitalize()} says:")
        print("─" * 60)
        print(result.get("response", ""))
        print("─" * 60)
        print(f"Source: {result.get('source', 'unknown')}")

        return 0

    def _handle_suggest(self, args: list) -> int:
        """Handle task suggestion"""

        if not args:
            print("❌ Usage: claude-gtd suggest <context>", file=sys.stderr)
            return 1

        context = " ".join(args)

        print(f"💡 Generating task suggestions from: {context[:50]}...")

        result, error = self.router.route_request(
            "task_suggest",
            context,
            context={"max_tokens": 400}
        )

        if error:
            print(f"❌ Error: {error}", file=sys.stderr)
            return 1

        print(f"\n✨ Suggested tasks:")
        print("─" * 60)
        print(result.get("response", ""))
        print("─" * 60)
        print(f"Source: {result.get('source', 'unknown')}")

        return 0

    def _handle_categorize(self, args: list) -> int:
        """Handle task categorization"""

        if not args:
            print("❌ Usage: claude-gtd categorize <tasks>", file=sys.stderr)
            return 1

        tasks = " ".join(args)

        print(f"🏷️  Categorizing tasks: {tasks[:50]}...")

        result, error = self.router.route_request(
            "task_categorize",
            tasks,
            context={"max_tokens": 300}
        )

        if error:
            print(f"❌ Error: {error}", file=sys.stderr)
            return 1

        print(f"\n📋 Categorized tasks:")
        print("─" * 60)
        print(result.get("response", ""))
        print("─" * 60)
        print(f"Source: {result.get('source', 'unknown')}")

        return 0

    def _handle_analyze(self, args: list) -> int:
        """Handle daily log analysis"""

        if not args:
            print("❌ Usage: claude-gtd analyze <log_file>", file=sys.stderr)
            return 1

        log_file = Path(args[0])

        if not log_file.exists():
            print(f"❌ Log file not found: {log_file}", file=sys.stderr)
            return 1

        content = log_file.read_text()

        print(f"📊 Analyzing: {log_file.name}")

        result, error = self.router.route_request(
            "analyze_daily_log",
            content,
            context={"max_tokens": 800}
        )

        if error:
            print(f"❌ Error: {error}", file=sys.stderr)
            return 1

        print(f"\n📈 Analysis:")
        print("─" * 60)
        print(result.get("response", ""))
        print("─" * 60)
        print(f"Source: {result.get('source', 'unknown')}")

        return 0

    def _handle_status(self) -> int:
        """Show current status"""

        status = self.router.get_status()

        print(f"\n🔄 AI System Status")
        print("─" * 60)
        print(f"Mode:              {status['mode']}")
        print(f"Ollama Available:  {'✅' if status['ollama_available'] else '❌'}")
        print(f"Claude Available:  {'✅' if status['claude_available'] else '❌'}")
        print(f"Ollama URL:        {status['ollama_url']}")

        if status['last_ollama_call']:
            print(f"Last Ollama Call:  {status['last_ollama_call']}")
        if status['last_claude_call']:
            print(f"Last Claude Call:  {status['last_claude_call']}")

        print("─" * 60)

        return 0

    def _handle_mode(self, args: list) -> int:
        """Switch AI mode"""

        if not args:
            status = self.router.get_status()
            print(f"Current mode: {status['mode']}")
            print(f"Available modes: {AIMode.OLLAMA_ONLY}, {AIMode.HYBRID}")
            return 0

        new_mode = args[0]
        success, message = self.router.switch_mode(new_mode)

        if success:
            print(f"✅ {message}")
            return 0
        else:
            print(f"❌ {message}", file=sys.stderr)
            return 1

    def _handle_ask(self, args: list) -> int:
        """Ask Claude directly (bypass router, always use Claude) - supports interactive mode"""

        if not args:
            print("❌ Usage: claude-gtd ask <question> [--interactive] [--model MODEL_NAME] [--ollama-model MODEL_NAME] [--ollama-timeout SECONDS]", file=sys.stderr)
            return 1

        # Check for interactive flag
        interactive = False
        model_override = None
        ollama_model_override = None
        ollama_timeout_override = None
        
        # Parse flags
        filtered_args = []
        i = 0
        while i < len(args):
            if args[i] in ["--interactive", "-i"]:
                interactive = True
                i += 1
            elif args[i] == "--model" and i + 1 < len(args):
                model_override = args[i + 1]
                i += 2
            elif args[i] == "--ollama-model" and i + 1 < len(args):
                ollama_model_override = args[i + 1]
                i += 2
            elif args[i] == "--ollama-timeout" and i + 1 < len(args):
                try:
                    ollama_timeout_override = int(args[i + 1])
                    i += 2
                except ValueError:
                    print(f"❌ Invalid timeout value: {args[i + 1]}", file=sys.stderr)
                    return 1
            else:
                filtered_args.append(args[i])
                i += 1
        
        args = filtered_args

        if not args:
            print("❌ Usage: claude-gtd ask <question> [--interactive] [--model MODEL_NAME] [--ollama-model MODEL_NAME] [--ollama-timeout SECONDS]", file=sys.stderr)
            return 1

        question = " ".join(args)

        if not self.router.anthropic_api_key:
            print("❌ Claude API key not configured", file=sys.stderr)
            print("   Set it with: export ANTHROPIC_API_KEY=sk-...", file=sys.stderr)
            return 1

        # Override Ollama settings if specified
        if ollama_model_override:
            self.router.ollama_model = ollama_model_override
        if ollama_timeout_override:
            self.router.ollama_timeout = ollama_timeout_override
            print(f"📌 Using Ollama timeout: {ollama_timeout_override}s")
        
        if interactive:
            return self._handle_interactive_ask(question, model_override=model_override, ollama_model_override=ollama_model_override, ollama_timeout_override=ollama_timeout_override)
        else:
            return self._handle_single_ask(question, model_override=model_override, ollama_model_override=ollama_model_override, ollama_timeout_override=ollama_timeout_override)

    def _award_xp(self, activity_type: str, reason: str = ""):
        """Award XP for an activity (silently, non-blocking)"""
        try:
            import subprocess
            script_dir = Path(__file__).parent.parent
            gamify_script = script_dir / "bin" / "gtd-gamify-award"
            if gamify_script.exists():
                # Run in background, don't wait for it
                subprocess.Popen(
                    [str(gamify_script), activity_type, "", reason],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL
                )
        except Exception:
            pass  # Silently fail if gamification not available

    def _handle_single_ask(self, question: str, model_override: Optional[str] = None, ollama_model_override: Optional[str] = None, ollama_timeout_override: Optional[int] = None) -> int:
        """Handle a single question (non-interactive)"""
        print(f"🧠 Asking Claude directly: {question[:50]}...")
        
        # Override models and timeout if specified
        if model_override:
            self.router.claude_model = model_override
            print(f"📌 Using Claude model: {model_override}")
        if ollama_model_override:
            self.router.ollama_model = ollama_model_override
            print(f"📌 Using Ollama model: {ollama_model_override}")
        if ollama_timeout_override:
            self.router.ollama_timeout = ollama_timeout_override
            print(f"📌 Using Ollama timeout: {ollama_timeout_override}s")

        result, error = self.router._call_claude(
            "general_question",
            question,
            persona=None,
            context={"max_tokens": 2000}
        )

        if error:
            print(f"❌ Error: {error}", file=sys.stderr)
            return 1

        print(f"\n💡 Claude's response:")
        print("─" * 60)
        print(result.get("response", ""))
        print("─" * 60)

        # Award XP for using Claude
        self._award_xp("claude_ask", f"Asked Claude: {question[:50]}")

        return 0

    def _select_persona_interactive(self) -> Optional[str]:
        """Interactively select a persona from available personas"""
        if not PERSONAS:
            print("⚠️  Personas not available, continuing without persona", file=sys.stderr)
            return None
        
        # Filter out special personas
        available_personas = [k for k in PERSONAS.keys() if k not in ["random", "all"]]
        
        if not available_personas:
            print("⚠️  No personas available, continuing without persona", file=sys.stderr)
            return None
        
        print("\n🤖 Select a persona for this conversation:")
        print("─" * 60)
        
        # Display personas with numbers
        persona_list = []
        for i, persona_key in enumerate(available_personas, 1):
            persona_info = PERSONAS.get(persona_key, {})
            persona_name = persona_info.get("name", persona_key.capitalize())
            persona_list.append(persona_key)
            print(f"  {i}) {persona_key} - {persona_name}")
        
        print("─" * 60)
        print("💡 You can also type 'none' to chat without a persona")
        print()
        
        while True:
            user_input = input("Select persona (number or name, or 'none'): ").strip().lower()
            
            if not user_input or user_input == 'none':
                return None
            
            # Check if it's a number
            if user_input.isdigit():
                index = int(user_input) - 1
                if 0 <= index < len(persona_list):
                    selected = persona_list[index]
                    persona_info = PERSONAS.get(selected, {})
                    persona_name = persona_info.get("name", selected.capitalize())
                    print(f"✓ Selected: {persona_name}\n")
                    return selected
                else:
                    print(f"❌ Invalid number. Please select 1-{len(persona_list)}")
                    continue
            
            # Try partial name matching (case-insensitive)
            matches = [p for p in persona_list if user_input in p.lower()]
            
            if len(matches) == 0:
                print(f"❌ No personas found matching '{user_input}'")
                print("   Try typing part of the persona name or use a number")
                continue
            elif len(matches) == 1:
                selected = matches[0]
                persona_info = PERSONAS.get(selected, {})
                persona_name = persona_info.get("name", selected.capitalize())
                print(f"✓ Selected: {persona_name}\n")
                return selected
            else:
                print(f"❌ Multiple matches found: {', '.join(matches)}")
                print("   Please be more specific or use a number")
                continue

    def _handle_interactive_ask(self, initial_question: str, model_override: Optional[str] = None, ollama_model_override: Optional[str] = None, ollama_timeout_override: Optional[int] = None) -> int:
        """Handle interactive conversation mode - launches TUI"""
        try:
            # Import TUI module
            tui_module_path = Path(__file__).parent / "claude_ask_tui.py"
            if not tui_module_path.exists():
                # Fallback to old interactive mode
                return self._handle_interactive_ask_legacy(initial_question)
            
            # Select persona at the start
            selected_persona = self._select_persona_interactive()
            
            # Launch TUI
            import subprocess
            import sys as sys_module
            
            # Build command
            cmd = [
                sys_module.executable,
                str(tui_module_path),
                initial_question
            ]
            
            if selected_persona:
                cmd.extend(["--persona", selected_persona])
            
            if model_override:
                cmd.extend(["--model", model_override])
            
            if ollama_model_override:
                cmd.extend(["--ollama-model", ollama_model_override])
            
            if ollama_timeout_override:
                cmd.extend(["--ollama-timeout", str(ollama_timeout_override)])
            
            # Run TUI (replaces current process)
            os.execv(sys_module.executable, cmd)
            
        except Exception as e:
            # Fallback to legacy mode on error
            print(f"⚠️  TUI not available, using legacy mode: {e}", file=sys.stderr)
            return self._handle_interactive_ask_legacy(initial_question)
    
    def _handle_interactive_ask_legacy(self, initial_question: str) -> int:
        """Legacy interactive conversation mode (fallback)"""
        print(f"💬 Interactive Claude Conversation")
        print("─" * 60)
        
        # Select persona at the start
        selected_persona = self._select_persona_interactive()
        
        if selected_persona:
            persona_info = PERSONAS.get(selected_persona, {})
            persona_name = persona_info.get("name", selected_persona.capitalize())
            print(f"🤖 Chatting as: {persona_name}")
        else:
            print("🤖 Chatting as: Claude (no persona)")
        
        print("─" * 60)
        print(f"Initial question: {initial_question}")
        print("─" * 60)
        print("\n💡 Type 'done' or 'exit' to end the conversation")
        print("💡 Type 'continue' to let Claude continue its current workflow\n")

        conversation_history = []
        current_question = initial_question
        exchange_count = 0

        while True:
            # Ask Claude
            print(f"\n🧠 Asking: {current_question[:80]}...")
            
            result, error = self.router._call_claude(
                "general_question",
                current_question,
                persona=selected_persona,
                context={"max_tokens": 2000, "conversation_history": conversation_history, "interactive": True}
            )

            if error:
                print(f"❌ Error: {error}", file=sys.stderr)
                # Ask if user wants to continue
                response = input("\nContinue anyway? (y/n): ").strip().lower()
                if response != 'y':
                    break
                continue

            response_text = result.get("response", "")
            print(f"\n💡 Claude:")
            print("─" * 60)
            print(response_text)
            print("─" * 60)

            # Add to conversation history
            conversation_history.append({"role": "user", "content": current_question})
            conversation_history.append({"role": "assistant", "content": response_text})
            exchange_count += 1

            # Ask for next input
            print("\n")
            next_input = input("💬 Your response (or 'done'/'exit' to finish, 'continue' to let Claude proceed): ").strip()

            if not next_input or next_input.lower() in ['done', 'exit', 'quit', 'q']:
                print("\n✓ Conversation ended.")
                break
            elif next_input.lower() == 'continue':
                # Let Claude continue - use a continuation prompt
                current_question = "Please continue with the next steps of what you were doing. If you were in the middle of a workflow, proceed with the next step."
            else:
                current_question = next_input

        # Award XP for interactive conversation (more exchanges = more engagement)
        if exchange_count > 0:
            reason = f"Interactive Claude conversation ({exchange_count} exchange{'s' if exchange_count > 1 else ''})"
            self._award_xp("claude_ask_interactive", reason)

        return 0

    def _print_help(self):
        """Print help message"""

        help_text = """
Claude GTD Client - Hybrid AI system for GTD workflows

USAGE:
    claude-gtd <command> [options]

COMMANDS:
    persona <question> [--persona NAME]
        Get advice from a specific persona (uses smart routing)
        Example: claude-gtd persona "How do I focus?" --persona cal

    suggest <context>
        Generate task suggestions (uses smart routing)
        Example: claude-gtd suggest "finished report, need to prepare presentation"

    categorize <tasks>
        Categorize tasks by context (uses smart routing)
        Example: claude-gtd categorize "email client, call mom, buy groceries"

    analyze <log_file>
        Analyze a daily log for insights (uses smart routing)
        Example: claude-gtd analyze ~/Documents/daily_logs/2026-01-19.md

    ask <question> [--interactive] [--model MODEL_NAME] [--ollama-model MODEL_NAME] [--ollama-timeout SECONDS]
        Ask Claude directly (ALWAYS uses Claude, bypasses router)
        Use --interactive or -i for extended conversation with persona selection
        Use --model to specify Claude model (e.g., claude-3-5-sonnet-20241022, claude-sonnet-4-5)
        Use --ollama-model to specify Ollama model (e.g., gemma3:1b, llama3.2:3b, qwen2.5:7b)
        Use --ollama-timeout to specify timeout in seconds (default: 120, increase for larger/slower models)
        Example: claude-gtd ask "What's your thoughts on productivity?"
        Example: claude-gtd ask "Help me plan my day" --interactive
        Example: claude-gtd ask "Review my log" --interactive --model claude-sonnet-4-5
        Example: claude-gtd ask "Simple question" --interactive --ollama-model llama3.2:3b
        Example: claude-gtd ask "Complex task" --interactive --ollama-model ministral-3:3b --ollama-timeout 300

    status
        Show current system status (mode, available backends)

    mode [ollama-only|hybrid]
        Switch between modes or show current mode
        Example: claude-gtd mode hybrid

    help
        Show this help message

MODES:
    ollama-only   - All requests use local Ollama (free, instant)
    hybrid        - Smart routing: simple tasks→Ollama, complex→Claude (API)

ROUTING:
    Most commands use smart routing in hybrid mode:
        - Simple tasks (suggestions, categorization) → Ollama
        - Complex tasks (analysis, strategy) → Claude

    Use 'ask' command to ALWAYS use Claude:
        - Bypasses routing logic
        - Always calls Claude API
        - Guarantees Claude quality

CONFIG:
    - Mode is controlled via ~/.gtd_config_ai (GTD_AI_MODE setting)
    - Claude API key: Set ANTHROPIC_API_KEY environment variable
    - Ollama URL: Set OLLAMA_URL in ~/.gtd_config_ai

EXAMPLES:
    # Get Hank's productivity advice (routed via smart logic)
    claude-gtd persona "I'm procrastinating"

    # Get Cal Newport's deep work advice (routed via smart logic)
    claude-gtd persona "How do I do deep work?" --persona cal

    # Ask Claude a direct question (ALWAYS Claude)
    claude-gtd ask "What's your best productivity advice?"

    # Generate 3-5 tasks from today's notes (routed via smart logic)
    claude-gtd suggest "worked on architecture, reviewed PRs, planned sprint"

    # Categorize a list of tasks (routed via smart logic, usually Ollama)
    claude-gtd categorize "email john, run test suite, buy milk"

    # Check current system
    claude-gtd status

    # Switch to local-only mode (no API calls)
    claude-gtd mode ollama-only
"""
        print(help_text)


def main():
    """Main entry point"""
    client = GTDClient()
    exit_code = client.run(sys.argv[1:])
    sys.exit(exit_code)


if __name__ == "__main__":
    main()
