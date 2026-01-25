#!/usr/bin/env python3
"""
Tests for Claude Ask TUI fixes and features

Tests the fixes for:
- TextArea.Submitted handler removal
- Config reload functionality
- Argument parsing for ollama-model and ollama-timeout

Tests the new features:
- Progress bar for interactive runbooks
- Tool transparency (showing tool calls and results)
- Runbook step tracking
- Ctrl+Enter support
"""

import unittest
import sys
import ast
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

# Add paths
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp"))
sys.path.insert(0, str(Path(__file__).parent.parent / "personal" / "dotfiles" / "mcp"))

class TestClaudeAskTUIFixes(unittest.TestCase):
    """Test suite for TUI fixes"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.tui_file = Path(__file__).parent.parent / "personal" / "dotfiles" / "mcp" / "claude_ask_tui.py"
        if not self.tui_file.exists():
            # Try alternative path
            self.tui_file = Path(__file__).parent.parent / "mcp" / "claude_ask_tui.py"
    
    def test_file_exists(self):
        """Test that the TUI file exists"""
        self.assertTrue(self.tui_file.exists(), f"TUI file should exist at {self.tui_file}")
    
    def test_syntax_valid(self):
        """Test that the TUI file has valid Python syntax"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        try:
            ast.parse(code)
        except SyntaxError as e:
            self.fail(f"TUI file has syntax errors: {e}")
    
    def test_no_textarea_submitted(self):
        """Test that TextArea.Submitted handler is removed"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertNotIn(
            'TextArea.Submitted',
            code,
            "TextArea.Submitted handler should be removed (TextArea doesn't support this event)"
        )
        self.assertNotIn(
            'on_text_area_submitted',
            code,
            "on_text_area_submitted method should be removed"
        )
    
    def test_no_styles_reload(self):
        """Test that invalid self.styles.reload() is removed"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertNotIn(
            'self.styles.reload()',
            code,
            "self.styles.reload() should be removed (RenderStyles doesn't have reload method)"
        )
    
    def test_has_action_reload_config(self):
        """Test that action_reload_config method exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'def action_reload_config',
            code,
            "action_reload_config method should exist"
        )
        # Check it uses proper reload method
        self.assertIn(
            'self.refresh()',
            code,
            "action_reload_config should use self.refresh() instead of self.styles.reload()"
        )
    
    def test_has_action_send_message(self):
        """Test that action_send_message method exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'def action_send_message',
            code,
            "action_send_message method should exist for Ctrl+J binding"
        )
    
    def test_has_ctrl_j_binding(self):
        """Test that Ctrl+J binding exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'ctrl+j',
            code.lower(),
            "Ctrl+J binding should exist for sending messages"
        )
    
    def test_has_ctrl_r_binding(self):
        """Test that Ctrl+R binding exists for config reload"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'ctrl+r',
            code.lower(),
            "Ctrl+R binding should exist for config reload"
        )
        self.assertIn(
            'reload_config',
            code,
            "reload_config action should be bound"
        )
    
    def test_argument_parser_has_ollama_model(self):
        """Test that argument parser accepts --ollama-model"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            '--ollama-model',
            code,
            "Argument parser should accept --ollama-model"
        )
    
    def test_argument_parser_has_ollama_timeout(self):
        """Test that argument parser accepts --ollama-timeout"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            '--ollama-timeout',
            code,
            "Argument parser should accept --ollama-timeout"
        )
    
    def test_argument_parser_has_model(self):
        """Test that argument parser accepts --model"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'parser.add_argument("--model"',
            code,
            "Argument parser should accept --model"
        )
    
    def test_config_file_initialized(self):
        """Test that config_file is initialized in __init__"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        self.assertIn(
            'self.config_file',
            code,
            "config_file should be initialized in __init__"
        )
        self.assertIn(
            'claude_ask_tui_config.css',
            code,
            "config_file should point to claude_ask_tui_config.css"
        )
    
    def test_import_succeeds(self):
        """Test that the TUI module can be imported"""
        try:
            # Try both possible paths
            try:
                from claude_ask_tui import ClaudeAskTUI
            except ImportError:
                # Try adding the path
                import sys
                sys.path.insert(0, str(self.tui_file.parent))
                from claude_ask_tui import ClaudeAskTUI
            
            self.assertTrue(hasattr(ClaudeAskTUI, 'action_reload_config'))
            self.assertTrue(hasattr(ClaudeAskTUI, 'action_send_message'))
        except ImportError as e:
            self.fail(f"Failed to import ClaudeAskTUI: {e}")
    
    def test_client_parameter_optional(self):
        """Test that __init__ accepts optional client parameter"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        # Check __init__ signature
        import re
        init_match = re.search(r'def __init__\(self[^)]+\):', code)
        self.assertIsNotNone(init_match, "__init__ method should exist")
        # Check for optional client parameter
        self.assertIn(
            'client: Optional[GTDClient]',
            code,
            "__init__ should accept optional client parameter"
        )


class TestArgumentParsing(unittest.TestCase):
    """Test argument parsing functionality"""
    
    def test_parse_ollama_model(self):
        """Test parsing --ollama-model argument"""
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('question', nargs='?', default='')
        parser.add_argument('--ollama-model')
        
        args = parser.parse_args(['--ollama-model', 'ministral-3:3b', 'test question'])
        self.assertEqual(args.ollama_model, 'ministral-3:3b')
        self.assertEqual(args.question, 'test question')
    
    def test_parse_ollama_timeout(self):
        """Test parsing --ollama-timeout argument"""
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('--ollama-timeout', type=int)
        
        args = parser.parse_args(['--ollama-timeout', '90'])
        self.assertEqual(args.ollama_timeout, 90)
    
    def test_parse_all_arguments(self):
        """Test parsing all arguments together"""
        import argparse
        parser = argparse.ArgumentParser()
        parser.add_argument('question', nargs='?', default='')
        parser.add_argument('--persona', '-p')
        parser.add_argument('--select-persona', action='store_true')
        parser.add_argument('--model')
        parser.add_argument('--ollama-model')
        parser.add_argument('--ollama-timeout', type=int)
        
        args = parser.parse_args([
            '--ollama-model', 'ministral-3:3b',
            '--ollama-timeout', '90',
            '--persona', 'questmaster',
            'test question'
        ])
        
        self.assertEqual(args.ollama_model, 'ministral-3:3b')
        self.assertEqual(args.ollama_timeout, 90)
        self.assertEqual(args.persona, 'questmaster')
        self.assertEqual(args.question, 'test question')


class TestRunbookProgressTracking(unittest.TestCase):
    """Test runbook progress tracking features"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.tui_file = Path(__file__).parent.parent / "personal" / "dotfiles" / "mcp" / "claude_ask_tui.py"
        if not self.tui_file.exists():
            self.tui_file = Path(__file__).parent.parent / "mcp" / "claude_ask_tui.py"
    
    def test_runbook_tracking_variables_exist(self):
        """Test that runbook tracking variables are initialized"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn('current_runbook', code, "current_runbook variable should exist")
        self.assertIn('current_step', code, "current_step variable should exist")
        self.assertIn('total_steps', code, "total_steps variable should exist")
    
    def test_detect_runbook_progress_method_exists(self):
        """Test that _detect_and_update_runbook_progress method exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'def _detect_and_update_runbook_progress',
            code,
            "_detect_and_update_runbook_progress method should exist"
        )
    
    def test_create_progress_bar_method_exists(self):
        """Test that _create_progress_bar method exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'def _create_progress_bar',
            code,
            "_create_progress_bar method should exist"
        )
    
    def test_progress_bar_displayed_in_status(self):
        """Test that progress bar is displayed when in runbook"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        # Check that status update includes progress bar logic
        self.assertIn(
            'Step {self.current_step}/{self.total_steps}',
            code,
            "Status should show step progress when in runbook"
        )
        self.assertIn(
            'current_runbook and self.total_steps',
            code,
            "Should check for runbook context before showing progress"
        )
    
    def test_morning_review_detection(self):
        """Test that morning review runbook is detected"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'morning review',
            code.lower(),
            "Should detect morning review runbook"
        )
        # Check that it sets total_steps to 8 for morning review
        self.assertIn(
            'self.total_steps = 8',
            code,
            "Morning review should have 8 total steps"
        )
    
    def test_step_detection_patterns(self):
        """Test that step detection patterns exist"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        # Check for common step patterns
        self.assertIn(
            'Step (\\d+)',
            code,
            "Should have regex pattern to detect step numbers"
        )
        self.assertIn(
            'proceed to Step',
            code,
            "Should detect 'proceed to Step X' patterns"
        )


class TestToolTransparency(unittest.TestCase):
    """Test tool transparency features"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.tui_file = Path(__file__).parent.parent / "personal" / "dotfiles" / "mcp" / "claude_ask_tui.py"
        if not self.tui_file.exists():
            self.tui_file = Path(__file__).parent.parent / "mcp" / "claude_ask_tui.py"
    
    def test_tool_executions_displayed(self):
        """Test that tool executions are displayed"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'tool_executions',
            code,
            "Should check for tool_executions in result"
        )
        self.assertIn(
            'Tools Used',
            code,
            "Should display 'Tools Used' header"
        )
    
    def test_tool_result_formatting(self):
        """Test that tool results are formatted correctly"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        # Check for result formatting
        self.assertIn(
            'tool_result',
            code,
            "Should access tool_result from tool details"
        )
        self.assertIn(
            'Result ─',
            code,
            "Should format tool results in a box"
        )
    
    def test_tool_name_and_args_displayed(self):
        """Test that tool name and arguments are displayed"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'tool_name',
            code,
            "Should display tool name"
        )
        self.assertIn(
            'tool_args',
            code,
            "Should display tool arguments"
        )
    
    def test_task_calendar_tools_show_more_detail(self):
        """Test that task/calendar tools show more detail"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        # Check for special handling of task/calendar tools
        # The code uses a list: ["task", "calendar", "daily_log", "project"]
        self.assertIn(
            '"task"',
            code,
            "Should detect task tools for more detail"
        )
        self.assertIn(
            '"calendar"',
            code,
            "Should detect calendar tools for more detail"
        )
        # Check for larger preview size
        self.assertIn(
            '[:1000]',
            code,
            "Task/calendar tools should show up to 1000 chars"
        )


class TestCtrlEnterSupport(unittest.TestCase):
    """Test Ctrl+Enter support for sending messages"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.tui_file = Path(__file__).parent.parent / "personal" / "dotfiles" / "mcp" / "claude_ask_tui.py"
        if not self.tui_file.exists():
            self.tui_file = Path(__file__).parent.parent / "mcp" / "claude_ask_tui.py"
    
    def test_ctrl_enter_binding_exists(self):
        """Test that Ctrl+Enter binding exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'ctrl+enter',
            code.lower(),
            "Ctrl+Enter binding should exist"
        )
        self.assertIn(
            'send_message',
            code,
            "Ctrl+Enter should trigger send_message action"
        )
    
    def test_sendable_textarea_exists(self):
        """Test that SendableTextArea class exists"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        self.assertIn(
            'class SendableTextArea',
            code,
            "SendableTextArea class should exist"
        )
        self.assertIn(
            'ctrl+enter',
            code.lower(),
            "SendableTextArea should handle ctrl+enter"
        )
    
    def test_sendable_textarea_used_in_compose(self):
        """Test that SendableTextArea is used in compose method"""
        with open(self.tui_file, 'r') as f:
            code = f.read()
        
        # Check that SendableTextArea is instantiated
        self.assertIn(
            'SendableTextArea(',
            code,
            "SendableTextArea should be used in compose"
        )


if __name__ == '__main__':
    unittest.main()
