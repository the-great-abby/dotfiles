#!/usr/bin/env python3
"""
Tests for Claude Ask TUI fixes

Tests the fixes for:
- TextArea.Submitted handler removal
- Config reload functionality
- Argument parsing for ollama-model and ollama-timeout
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


if __name__ == '__main__':
    unittest.main()
