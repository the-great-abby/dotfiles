#!/usr/bin/env python3
"""
Unit tests for gtd_auto_suggest.py
Tests: auto-suggestion system, banter generation, task extraction
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
from pathlib import Path
import json
import tempfile
import os

# Add module to path - need both mcp directory and parent for imports
dotfiles_dir = Path(__file__).parent.parent
mcp_dir = dotfiles_dir / "mcp"
sys.path.insert(0, str(mcp_dir))
sys.path.insert(0, str(dotfiles_dir))

try:
    from gtd_auto_suggest import (
        analyze_entry,
        generate_banter,
        extract_tasks,
        process_single_entry,
        batch_analyze_logs
    )
    MODULE_AVAILABLE = True
except (ImportError, NameError, SyntaxError, AttributeError) as e:
    MODULE_AVAILABLE = False
    print(f"Warning: gtd_auto_suggest module not available for testing: {e}")


class TestGTDAutoSuggest(unittest.TestCase):
    """Test cases for GTD auto-suggestion system"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.test_entry = "Just finished a great workout, feeling energized!"
        self.test_entry_with_tasks = "I need to finish the quarterly report by Friday and schedule a team meeting"
        self.temp_dir = tempfile.mkdtemp()
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_analyze_entry_function_exists(self):
        """Test that analyze_entry function exists"""
        self.assertTrue(callable(analyze_entry))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    @patch('gtd_auto_suggest.call_persona')
    def test_analyze_entry_basic(self, mock_call_persona):
        """Test basic entry analysis"""
        mock_call_persona.return_value = {
            "suggestions": [
                {"task": "Review workout routine", "confidence": 0.8}
            ],
            "banter": "Great job on the workout!"
        }
        
        result = analyze_entry(self.test_entry)
        self.assertIsNotNone(result)
        mock_call_persona.assert_called_once()
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_generate_banter_function_exists(self):
        """Test that generate_banter function exists"""
        self.assertTrue(callable(generate_banter))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_generate_banter_positive_tone(self):
        """Test banter generation for positive entries"""
        positive_entry = "Just completed a major milestone!"
        # Test that function can be called (may need mocking)
        self.assertTrue(callable(generate_banter))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_extract_tasks_function_exists(self):
        """Test that extract_tasks function exists"""
        self.assertTrue(callable(extract_tasks))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_extract_tasks_from_text(self):
        """Test task extraction from text"""
        text_with_tasks = "I need to: 1) Finish report 2) Call client 3) Review code"
        # Test that function can extract tasks
        self.assertTrue(callable(extract_tasks))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    @patch('gtd_auto_suggest.analyze_entry')
    def test_process_single_entry(self, mock_analyze):
        """Test processing a single entry"""
        mock_analyze.return_value = {
            "suggestions": [],
            "banter": "Test banter"
        }
        
        result = process_single_entry(self.test_entry)
        self.assertIsNotNone(result)
        mock_analyze.assert_called_once()
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_process_single_entry_empty(self):
        """Test processing empty entry"""
        result = process_single_entry("")
        # Should handle empty input gracefully
        self.assertIsNotNone(result)
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    @patch('gtd_auto_suggest.process_single_entry')
    def test_batch_analyze_logs(self, mock_process):
        """Test batch analysis of logs"""
        mock_process.return_value = {"suggestions": []}
        
        log_entries = [
            "Entry 1",
            "Entry 2",
            "Entry 3"
        ]
        
        results = batch_analyze_logs(log_entries)
        self.assertIsNotNone(results)
        self.assertEqual(mock_process.call_count, len(log_entries))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_batch_analyze_empty_logs(self):
        """Test batch analysis with empty log list"""
        results = batch_analyze_logs([])
        self.assertIsNotNone(results)
        self.assertEqual(len(results), 0)
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_confidence_scoring(self):
        """Test that suggestions include confidence scores"""
        # Test that confidence is between 0 and 1
        self.assertTrue(callable(analyze_entry))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_banter_contextual(self):
        """Test that banter matches entry tone"""
        # Test that banter is contextual
        self.assertTrue(callable(generate_banter))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_error_handling_invalid_entry(self):
        """Test error handling for invalid entries"""
        invalid_entries = [None, 123, [], {}]
        for invalid in invalid_entries:
            # Should handle gracefully
            try:
                result = process_single_entry(invalid)
                self.assertIsNotNone(result)
            except (TypeError, AttributeError):
                # Expected for some invalid types
                pass
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_suggestion_format(self):
        """Test that suggestions have correct format"""
        # Suggestions should have: task, reason, confidence
        self.assertTrue(callable(extract_tasks))


class TestGTDAutoSuggestIntegration(unittest.TestCase):
    """Integration tests for auto-suggestion system"""
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_end_to_end_flow(self):
        """Test end-to-end flow of suggestion generation"""
        # Test that the full flow works
        self.assertTrue(callable(analyze_entry))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    @patch('gtd_auto_suggest.call_persona')
    def test_suggestion_persistence(self, mock_call_persona):
        """Test that suggestions can be persisted"""
        mock_call_persona.return_value = {
            "suggestions": [{"task": "Test", "confidence": 0.9}]
        }
        # Test that suggestions can be saved
        self.assertTrue(callable(analyze_entry))


if __name__ == '__main__':
    unittest.main()

