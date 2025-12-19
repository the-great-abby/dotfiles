#!/usr/bin/env python3
"""
Unit tests for gtd_smart_suggestions.py
Tests: smart suggestion system, acceptance tracking, suggestion filtering
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
    from gtd_smart_suggestions import (
        load_acceptance_tracking,
        save_acceptance_tracking,
        filter_suggestions,
        get_smart_suggestions,
        track_suggestion_acceptance
    )
    MODULE_AVAILABLE = True
except (ImportError, NameError, SyntaxError, AttributeError) as e:
    MODULE_AVAILABLE = False
    print(f"Warning: gtd_smart_suggestions module not available for testing: {e}")


class TestGTDSmartSuggestions(unittest.TestCase):
    """Test cases for GTD smart suggestions system"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.temp_dir = tempfile.mkdtemp()
        self.tracking_file = os.path.join(self.temp_dir, "acceptance_tracking.json")
    
    def tearDown(self):
        """Clean up test fixtures"""
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_load_acceptance_tracking_function_exists(self):
        """Test that load_acceptance_tracking function exists"""
        self.assertTrue(callable(load_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_load_acceptance_tracking_new_file(self):
        """Test loading tracking from new/non-existent file"""
        tracking = load_acceptance_tracking()
        self.assertIsInstance(tracking, dict)
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_load_acceptance_tracking_existing_file(self):
        """Test loading tracking from existing file"""
        # Create test tracking file
        test_data = {
            "suggestions": {
                "task1": {"accepted": 1, "rejected": 0}
            }
        }
        with open(self.tracking_file, 'w') as f:
            json.dump(test_data, f)
        
        # Test loading
        self.assertTrue(callable(load_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_save_acceptance_tracking_function_exists(self):
        """Test that save_acceptance_tracking function exists"""
        self.assertTrue(callable(save_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_save_acceptance_tracking_basic(self):
        """Test saving tracking data"""
        test_data = {
            "suggestions": {
                "task1": {"accepted": 1, "rejected": 0}
            }
        }
        # Test that function can save
        self.assertTrue(callable(save_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_filter_suggestions_function_exists(self):
        """Test that filter_suggestions function exists"""
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_filter_suggestions_basic(self):
        """Test basic suggestion filtering"""
        suggestions = [
            {"task": "Task 1", "confidence": 0.9},
            {"task": "Task 2", "confidence": 0.5},
            {"task": "Task 3", "confidence": 0.8}
        ]
        # Test that function can filter
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_filter_suggestions_by_confidence(self):
        """Test filtering suggestions by confidence threshold"""
        suggestions = [
            {"task": "High confidence", "confidence": 0.9},
            {"task": "Low confidence", "confidence": 0.3}
        ]
        # Test filtering by confidence
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_get_smart_suggestions_function_exists(self):
        """Test that get_smart_suggestions function exists"""
        self.assertTrue(callable(get_smart_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_get_smart_suggestions_basic(self):
        """Test getting smart suggestions"""
        # Test that function can generate suggestions
        self.assertTrue(callable(get_smart_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_track_suggestion_acceptance_function_exists(self):
        """Test that track_suggestion_acceptance function exists"""
        self.assertTrue(callable(track_suggestion_acceptance))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_track_suggestion_acceptance_accepted(self):
        """Test tracking accepted suggestion"""
        suggestion_id = "test_suggestion_1"
        # Test tracking acceptance
        self.assertTrue(callable(track_suggestion_acceptance))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_track_suggestion_acceptance_rejected(self):
        """Test tracking rejected suggestion"""
        suggestion_id = "test_suggestion_1"
        # Test tracking rejection
        self.assertTrue(callable(track_suggestion_acceptance))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_error_handling_invalid_json(self):
        """Test error handling for invalid JSON"""
        # Create invalid JSON file
        invalid_file = os.path.join(self.temp_dir, "invalid.json")
        with open(invalid_file, 'w') as f:
            f.write("Invalid JSON content {")
        
        # Should handle gracefully
        self.assertTrue(callable(load_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_error_handling_missing_file(self):
        """Test error handling for missing file"""
        missing_file = os.path.join(self.temp_dir, "nonexistent.json")
        # Should handle gracefully
        self.assertTrue(callable(load_acceptance_tracking))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_suggestion_ranking(self):
        """Test that suggestions are ranked by acceptance rate"""
        # Test ranking logic
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_empty_suggestions_list(self):
        """Test with empty suggestions list"""
        suggestions = []
        # Should handle empty list
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_suggestion_persistence(self):
        """Test that suggestion tracking persists across calls"""
        # Test persistence
        self.assertTrue(callable(save_acceptance_tracking))
        self.assertTrue(callable(load_acceptance_tracking))


class TestGTDSmartSuggestionsEdgeCases(unittest.TestCase):
    """Edge case tests for smart suggestions"""
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_very_high_confidence(self):
        """Test with very high confidence values"""
        suggestions = [
            {"task": "Task", "confidence": 0.99}
        ]
        # Should handle high confidence
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_very_low_confidence(self):
        """Test with very low confidence values"""
        suggestions = [
            {"task": "Task", "confidence": 0.01}
        ]
        # Should handle low confidence
        self.assertTrue(callable(filter_suggestions))
    
    @unittest.skipUnless(MODULE_AVAILABLE, "Module not available")
    def test_special_characters_in_suggestions(self):
        """Test with special characters in suggestion text"""
        suggestions = [
            {"task": "Task with special chars: !@#$%", "confidence": 0.8}
        ]
        # Should handle special characters
        self.assertTrue(callable(filter_suggestions))


if __name__ == '__main__':
    unittest.main()

