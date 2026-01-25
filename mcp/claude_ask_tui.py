#!/usr/bin/env python3
"""
Claude Ask TUI - Text User Interface for interactive Claude conversations

A modern TUI built with Textual for chatting with Claude.
"""

import sys
import os
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))
sys.path.insert(0, str(Path(__file__).parent))

try:
    from textual.app import App, ComposeResult
    from textual.widgets import (
        Header, Footer, Static, Input, Button, TextArea, Select, Label
    )
    from textual.containers import Container, Horizontal, Vertical, VerticalScroll
    from textual.binding import Binding
    from textual import events
    from textual.reactive import reactive
except ImportError:
    print("Error: textual library not installed.")
    print("Install with: pip install textual")
    sys.exit(1)

# Import Claude client
try:
    from claude_gtd_client import GTDClient
    from claude_ollama_bridge import SmartAIRouter
except ImportError as e:
    print(f"Error: Could not import Claude client: {e}", file=sys.stderr)
    sys.exit(1)

# Import persona definitions
try:
    from zsh.functions.gtd_persona_helper import PERSONAS
except ImportError:
    try:
        sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))
        from gtd_persona_helper import PERSONAS
    except ImportError:
        PERSONAS = {}


@dataclass
class Message:
    """Represents a message in the conversation"""
    role: str  # "user" or "assistant"
    content: str
    timestamp: str


class SendableTextArea(TextArea):
    """TextArea that handles Ctrl+Enter to send messages"""
    
    async def on_key(self, event: events.Key) -> None:
        """Handle Ctrl+Enter to trigger send action"""
        if event.key == "ctrl+enter":
            # Prevent default behavior (inserting newline)
            event.prevent_default()
            # Trigger the send action on the parent app
            app = self.app
            if app and hasattr(app, 'action_send_message'):
                await app.action_send_message()
            return
        # For other keys, let TextArea handle them normally
        # Don't call super().on_key() as TextArea doesn't expose it that way
        # Just return and let the default TextArea behavior handle it


class ClaudeAskTUI(App):
    """TUI for interactive Claude conversations"""

    CSS = """
    Screen {
        background: $surface;
    }
    
    #conversation {
        width: 1fr;
        height: 1fr;
        border: solid $primary;
        padding: 0 1;
    }
    
    #input-container {
        height: auto;
        max-height: 8;
        padding: 0 1;
        border-top: solid $primary;
    }
    
    #input-area {
        width: 1fr;
        height: 3;
    }
    
    Horizontal {
        height: auto;
        padding: 0;
    }
    
    .message-user {
        background: $primary 20%;
        padding: 0 1;
        margin: 0 0 1 0;
        border-left: solid $accent;
    }
    
    .message-assistant {
        background: $secondary 20%;
        padding: 0 1;
        margin: 0 0 1 0;
        border-left: solid $success;
    }
    
    .message-label {
        text-style: bold;
        margin-bottom: 0;
    }
    
    #status-bar {
        height: 1;
        padding: 0 1;
        background: $panel;
    }
    """

    BINDINGS = [
        Binding("ctrl+c", "quit", "Quit", priority=True),
        Binding("escape", "clear_input", "Clear Input", priority=True),
        Binding("ctrl+l", "clear_conversation", "Clear Chat", priority=True),
        Binding("ctrl+/", "help", "Help", priority=True),
        Binding("ctrl+j", "send_message", "Send", priority=True),
        Binding("ctrl+enter", "send_message", "Send", priority=True),
        Binding("ctrl+r", "reload_config", "Reload Config", priority=True),
    ]

    def __init__(self, initial_question: str = "", persona: Optional[str] = None, client: Optional[GTDClient] = None):
        super().__init__()
        self.initial_question = initial_question
        self.selected_persona = persona
        self.conversation_history: List[Dict[str, str]] = []
        self.messages: List[Message] = []
        self.client = client if client is not None else GTDClient()
        self.exchange_count = 0
        self.is_thinking = False
        
        # Runbook progress tracking
        self.current_runbook: Optional[str] = None
        self.current_step: int = 0
        self.total_steps: int = 0
        
        # Config file for external CSS customization
        self.config_file = Path(__file__).parent / "claude_ask_tui_config.css"

    def compose(self) -> ComposeResult:
        """Create child widgets for the app"""
        yield Header(show_clock=True)
        
        with Vertical():
            # Status bar
            yield Static("Ready", id="status-bar")
            
            # Conversation area
            with VerticalScroll(id="conversation"):
                yield Static("", id="conversation-content")
            
            # Input area (minimal space)
            with Container(id="input-container"):
                yield SendableTextArea(
                    placeholder="💬 Type your question here... (Ctrl+J or Ctrl+Enter to send, Esc to clear)",
                    id="input-area",
                    language="markdown"
                )
                with Horizontal():
                    yield Button("Send", id="send-btn", variant="primary")
                    yield Button("Continue", id="continue-btn")
                    yield Button("Clear", id="clear-btn")
                    yield Button("Quit", id="quit-btn", variant="error")
        
        yield Footer()

    async def on_mount(self) -> None:
        """Called when app starts"""
        # Focus input area
        self.query_one("#input-area", TextArea).focus()
        
        # If we have an initial question, ask it asynchronously (non-blocking)
        # This allows the TUI to display immediately before the AI request starts
        if self.initial_question:
            # Use create_task to run the request in the background
            # This allows the TUI to render first, then the request happens
            import asyncio
            asyncio.create_task(self._ask_claude(self.initial_question))
        else:
            # Show welcome message
            self._add_message("assistant", "Hello! I'm Claude. What would you like to talk about?")
            self._update_status("Ready - Type your question and press Ctrl+J or Ctrl+Enter to send")

    def _add_message(self, role: str, content: str):
        """Add a message to the conversation"""
        timestamp = datetime.now().strftime("%H:%M:%S")
        message = Message(role=role, content=content, timestamp=timestamp)
        self.messages.append(message)
        
        # Add to conversation history for Claude
        self.conversation_history.append({"role": role, "content": content})
        
        self._update_conversation_display()

    def _update_conversation_display(self):
        """Update the conversation display"""
        content_widget = self.query_one("#conversation-content", Static)
        
        # Build conversation text
        lines = []
        
        # Show persona if selected
        if self.selected_persona:
            persona_info = PERSONAS.get(self.selected_persona, {})
            persona_name = persona_info.get("name", self.selected_persona.capitalize())
            lines.append(f"[bold cyan]🤖 Chatting as: {persona_name}[/bold cyan]")
            lines.append("")
        
        # Add messages
        for msg in self.messages:
            if msg.role == "user":
                lines.append(f"[bold green]You ({msg.timestamp}):[/bold green]")
                lines.append(f"{msg.content}")
            else:
                lines.append(f"[bold blue]Claude ({msg.timestamp}):[/bold blue]")
                lines.append(f"{msg.content}")
            lines.append("")
        
        content_widget.update("\n".join(lines))

    def _update_status(self, status: str):
        """Update status bar"""
        status_widget = self.query_one("#status-bar", Static)
        status_widget.update(status)
    
    def _detect_and_update_runbook_progress(self, response_text: str):
        """Detect if we're in a runbook and update progress tracking"""
        import re
        
        response_lower = response_text.lower()
        
        # First, check if runbook is complete
        completion_keywords = [
            "runbook complete",
            "runbook is complete",
            "runbook finished",
            "runbook is finished",
            "morning review complete",
            "morning review is complete",
            "morning review finished",
            "all done",
            "that completes",
            "we've completed",
            "we have completed",
            "review is complete",
            "review complete",
        ]
        
        is_complete = any(keyword in response_lower for keyword in completion_keywords)
        
        # Also check if we've reached the final step and there's no more runbook content
        if self.current_runbook and self.current_step >= self.total_steps:
            # Check if response doesn't mention continuing the runbook
            continuing_keywords = ["next step", "proceed to", "step", "runbook"]
            is_continuing = any(keyword in response_lower for keyword in continuing_keywords)
            if not is_continuing:
                is_complete = True
        
        # If runbook is complete, clear tracking
        if is_complete and self.current_runbook:
            print(f"  ℹ️  Runbook complete - clearing progress tracking", file=sys.stderr)
            self.current_runbook = None
            self.current_step = 0
            self.total_steps = 0
            return
        
        # Check for runbook mentions
        runbook_keywords = [
            "morning review runbook",
            "interactive morning review",
            "morning review",
            "runbook",
        ]
        
        # Detect if we're in a runbook
        is_runbook = any(keyword in response_lower for keyword in runbook_keywords)
        
        if is_runbook:
            # Set runbook name if not set
            if not self.current_runbook:
                if "morning review" in response_lower:
                    self.current_runbook = "Morning Review"
                    self.total_steps = 8  # Morning review has 8 steps
                elif "runbook" in response_lower:
                    self.current_runbook = "Runbook"
                    self.total_steps = 8  # Default to 8, can be adjusted
            
            # Try to detect current step number from various patterns
            step_patterns = [
                r"Step (\d+):",  # "Step 1:"
                r"step (\d+):",  # "step 1:"
                r"Step (\d+) ",  # "Step 1 "
                r"step (\d+) ",  # "step 1 "
                r"proceed to Step (\d+)",  # "proceed to Step 2"
                r"proceed to step (\d+)",  # "proceed to step 2"
                r"Step (\d+)",  # "Step 1" (standalone)
                r"step (\d+)",  # "step 1" (standalone)
            ]
            
            # Check current response
            for pattern in step_patterns:
                matches = re.finditer(pattern, response_text, re.IGNORECASE)
                for match in matches:
                    step_num = int(match.group(1))
                    if step_num > self.current_step:
                        self.current_step = step_num
                        break
            
            # Also check conversation history for step mentions
            for msg in reversed(self.messages[-10:]):  # Check last 10 messages
                if msg.role == "assistant":
                    for pattern in step_patterns:
                        matches = re.finditer(pattern, msg.content, re.IGNORECASE)
                        for match in matches:
                            step_num = int(match.group(1))
                            if step_num > self.current_step:
                                self.current_step = step_num
                                break
            
            # If we detected a runbook but haven't found a step yet, assume we're on step 1
            if self.current_step == 0 and self.current_runbook:
                self.current_step = 1
    
    def _create_progress_bar(self, percentage: int, width: int = 20) -> str:
        """Create a visual progress bar"""
        filled = int((percentage / 100) * width)
        empty = width - filled
        bar = "█" * filled + "░" * empty
        return f"[{bar}]"

    async def _ask_claude(self, question: str):
        """Ask Claude a question"""
        if not question.strip():
            return
        
        # Add user message
        self._add_message("user", question)
        self._update_status("🧠 Thinking...")
        self.is_thinking = True
        
        # Disable input while thinking
        input_area = self.query_one("#input-area", TextArea)
        input_area.disabled = True
        
        try:
            # Call Claude (run in thread pool to avoid blocking event loop)
            # This allows the TUI to remain responsive while waiting for the AI response
            import asyncio
            loop = asyncio.get_event_loop()
            result, error = await loop.run_in_executor(
                None,  # Use default thread pool
                lambda: self.client.router._call_claude(
                    "general_question",
                    question,
                    persona=self.selected_persona,
                    context={
                        "max_tokens": 2000,
                        "conversation_history": self.conversation_history[:-1],  # Exclude the question we just added
                        "interactive": True
                    }
                )
            )
            
            if error:
                self._add_message("assistant", f"❌ Error: {error}")
                self._update_status(f"Error: {error}")
            else:
                response_text = result.get("response", "")
                
                # Display tool execution details if available (for transparency)
                tool_details = result.get("tool_executions", []) or result.get("tool_execution_details", [])
                if tool_details:
                    tool_info_lines = []
                    tool_info_lines.append("[bold cyan]🔧 Tools Used:[/bold cyan]")
                    for tool_detail in tool_details:
                        tool_name = tool_detail.get("tool_name", "unknown")
                        tool_args = tool_detail.get("tool_args", {})
                        tool_result = tool_detail.get("tool_result", "")
                        is_error = tool_detail.get("is_error", False)
                        
                        # Format tool call
                        args_str = ", ".join([f"{k}={v}" for k, v in tool_args.items()]) if tool_args else "no args"
                        status_icon = "❌" if is_error else "✅"
                        tool_info_lines.append(f"[cyan]  {status_icon} {tool_name}({args_str})[/cyan]")
                        
                        # Show result preview (truncate if too long, but show more for important tools)
                        if tool_result:
                            # For task/calendar tools, show more detail
                            if any(keyword in tool_name.lower() for keyword in ["task", "calendar", "daily_log", "project"]):
                                result_preview = tool_result[:1000] + "..." if len(tool_result) > 1000 else tool_result
                            else:
                                result_preview = tool_result[:500] + "..." if len(tool_result) > 500 else tool_result
                            
                            # Format as code block for readability
                            tool_info_lines.append(f"[dim]   ┌─ Result ─────────────────────────────────────────[/dim]")
                            # Split result into lines and indent each
                            result_lines = result_preview.split('\n')
                            for line in result_lines[:20]:  # Limit to 20 lines
                                tool_info_lines.append(f"[dim]   │ {line}[/dim]")
                            if len(result_lines) > 20:
                                tool_info_lines.append(f"[dim]   │ ... ({len(result_lines) - 20} more lines)[/dim]")
                            tool_info_lines.append(f"[dim]   └───────────────────────────────────────────────────[/dim]")
                    
                    # Add tool info before the response
                    tool_info = "\n".join(tool_info_lines)
                    self._add_message("assistant", f"{tool_info}\n\n{response_text}")
                else:
                    self._add_message("assistant", response_text)
                
                # Detect runbook context and track progress
                self._detect_and_update_runbook_progress(response_text)
                
                self.exchange_count += 1
                
                # Show progress bar if in runbook, otherwise show exchange count
                if self.current_runbook and self.total_steps > 0:
                    progress_pct = int((self.current_step / self.total_steps) * 100) if self.total_steps > 0 else 0
                    progress_bar = self._create_progress_bar(progress_pct)
                    status_text = f"📋 {self.current_runbook} - Step {self.current_step}/{self.total_steps} {progress_bar} ({progress_pct}%)"
                    self._update_status(status_text)
                else:
                    self._update_status(f"✓ Response received ({self.exchange_count} exchange{'s' if self.exchange_count != 1 else ''})")
                
        except Exception as e:
            self._add_message("assistant", f"❌ Error: {str(e)}")
            self._update_status(f"Error: {str(e)}")
        finally:
            self.is_thinking = False
            input_area.disabled = False
            input_area.focus()
            
            # Clear input
            input_area.text = ""

    async def action_send_message(self):
        """Send message action (bound to Ctrl+J or Ctrl+Enter)"""
        if not self.is_thinking:
            input_area = self.query_one("#input-area", TextArea)
            question = input_area.text.strip()
            if question:
                await self._ask_claude(question)
    

    async def on_button_pressed(self, event: Button.Pressed) -> None:
        """Handle button presses"""
        button_id = event.button.id
        
        if button_id == "send-btn":
            input_area = self.query_one("#input-area", TextArea)
            question = input_area.text.strip()
            if question and not self.is_thinking:
                await self._ask_claude(question)
        
        elif button_id == "continue-btn":
            if not self.is_thinking:
                await self._ask_claude("Please continue with the next steps of what you were doing. If you were in the middle of a workflow, proceed with the next step.")
        
        elif button_id == "clear-btn":
            self.messages.clear()
            self.conversation_history.clear()
            self.exchange_count = 0
            # Clear runbook tracking when conversation is cleared
            self.current_runbook = None
            self.current_step = 0
            self.total_steps = 0
            self._update_conversation_display()
            self._update_status("Conversation cleared")
        
        elif button_id == "quit-btn":
            self.exit()

    def action_clear_input(self):
        """Clear the input area"""
        input_area = self.query_one("#input-area", TextArea)
        input_area.text = ""

    def action_clear_conversation(self):
        """Clear the conversation"""
        self.messages.clear()
        self.conversation_history.clear()
        self.exchange_count = 0
        # Clear runbook tracking when conversation is cleared
        self.current_runbook = None
        self.current_step = 0
        self.total_steps = 0
        self._update_conversation_display()
        self._update_status("Conversation cleared")

    def action_reload_config(self):
        """Reload TUI configuration (CSS styles) - tmux-style reload"""
        try:
            # Try to load external config file if it exists
            if self.config_file.exists():
                with open(self.config_file, 'r') as f:
                    external_css = f.read()
                # Update CSS property (this will be applied on next refresh)
                self.CSS = external_css
                print(f"  ℹ️  Loaded external config from {self.config_file}", file=sys.stderr)
            
            # Force refresh of all widgets to apply new styles
            self.refresh()
            
            # Show success notification
            config_source = f"external ({self.config_file.name})" if self.config_file.exists() else "built-in"
            self.notify(f"✅ Configuration reloaded from {config_source}", title="Config Reload", timeout=2)
            self._update_status("Configuration reloaded")
            
        except Exception as e:
            error_msg = f"❌ Error reloading config: {str(e)}"
            self.notify(error_msg, title="Config Reload Error", timeout=5)
            print(f"  ❌ Config reload error: {e}", file=sys.stderr)

    def action_help(self):
        """Show help"""
        help_text = """
[bold]Claude Ask TUI - Keyboard Shortcuts[/bold]

[cyan]Input:[/cyan]
  Ctrl+J      - Send message
  Esc         - Clear input
  Ctrl+L      - Clear conversation
  Ctrl+/      - Show this help
  Ctrl+R      - Reload config (tmux-style)
  Ctrl+C      - Quit

[cyan]Buttons:[/cyan]
  Send        - Send your message
  Continue    - Ask Claude to continue
  Clear       - Clear conversation
  Quit        - Exit TUI
        """
        self.notify(help_text, title="Help", timeout=10)

    def action_quit(self):
        """Quit the application"""
        # Award XP if we had exchanges
        if self.exchange_count > 0:
            try:
                reason = f"Interactive Claude conversation ({self.exchange_count} exchange{'s' if self.exchange_count != 1 else ''})"
                self.client._award_xp("claude_ask_interactive", reason)
            except Exception:
                pass
        
        self.exit()


def select_persona_tui() -> Optional[str]:
    """Select persona using a simple TUI"""
    if not PERSONAS:
        return None
    
    available_personas = [k for k in PERSONAS.keys() if k not in ["random", "all"]]
    
    if not available_personas:
        return None
    
    print("\n🤖 Select a persona for this conversation:")
    print("─" * 60)
    
    for i, persona_key in enumerate(available_personas, 1):
        persona_info = PERSONAS.get(persona_key, {})
        persona_name = persona_info.get("name", persona_key.capitalize())
        print(f"  {i}) {persona_key} - {persona_name}")
    
    print("─" * 60)
    print("💡 Type a number, persona name, or 'none' for no persona")
    print()
    
    while True:
        choice = input("Select persona: ").strip().lower()
        
        if not choice or choice == "none":
            return None
        
        # Try number
        try:
            idx = int(choice) - 1
            if 0 <= idx < len(available_personas):
                return available_personas[idx]
        except ValueError:
            pass
        
        # Try name match
        for persona_key in available_personas:
            if choice == persona_key.lower() or choice in persona_key.lower():
                return persona_key
        
        print("❌ Invalid choice. Please try again.")


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="Claude Ask TUI - Interactive Claude conversations")
    parser.add_argument("question", nargs="?", default="", help="Initial question to ask")
    parser.add_argument("--persona", "-p", help="Persona to use")
    parser.add_argument("--select-persona", action="store_true", help="Select persona interactively")
    parser.add_argument("--model", help="Claude model to use (e.g., claude-3-5-sonnet-20241022)")
    parser.add_argument("--ollama-model", help="Ollama model to use (e.g., ministral-3:3b, llama3.1:8b-instruct-q6_K)")
    parser.add_argument("--ollama-timeout", type=int, help="Ollama timeout in seconds (default: 120)")
    
    args = parser.parse_args()
    
    # Select persona if requested
    persona = args.persona
    if args.select_persona and not persona:
        persona = select_persona_tui()
    
    # Configure router with overrides if provided
    if args.model or args.ollama_model or args.ollama_timeout:
        # Get the router from the client and update settings
        client = GTDClient()
        if args.model:
            client.router.claude_model = args.model
            print(f"📌 Using Claude model: {args.model}", file=sys.stderr)
        if args.ollama_model:
            client.router.ollama_model = args.ollama_model
            print(f"📌 Using Ollama model: {args.ollama_model}", file=sys.stderr)
        if args.ollama_timeout:
            client.router.ollama_timeout = args.ollama_timeout
            print(f"📌 Using Ollama timeout: {args.ollama_timeout}s", file=sys.stderr)
        
        # Create TUI with pre-configured client
        app = ClaudeAskTUI(initial_question=args.question, persona=persona)
        app.client = client  # Use the configured client
    else:
        # Create TUI with default client
        app = ClaudeAskTUI(initial_question=args.question, persona=persona)
    
    app.run()


if __name__ == "__main__":
    main()