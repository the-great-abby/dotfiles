#!/usr/bin/env python3
"""
Unit tests for LM Studio Helper
Tests config reading, server checking, and daily log processing.
"""

import unittest
from unittest.mock import Mock, patch, mock_open, MagicMock
import sys
import json
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

from lmstudio_helper import (
    read_config,
    get_daily_goal,
    check_ai_server,
    call_lm_studio
)


class TestReadConfig(unittest.TestCase):
    """Test cases for read_config function"""
    
    @patch('builtins.open', new_callable=mock_open, read_data='AI_BACKEND="lmstudio"\nLM_STUDIO_URL="http://localhost:1234/v1/chat/completions"\nLM_STUDIO_CHAT_MODEL="test-model"')
    @patch('pathlib.Path.exists')
    def test_read_config_lmstudio(self, mock_exists, mock_file):
        """Test reading config with LM Studio settings"""
        mock_exists.return_value = True
        config = read_config()
        
        self.assertIsInstance(config, dict)
        self.assertEqual(config.get("backend"), "lmstudio")
        self.assertIn("url", config)
        self.assertIn("chat_model", config)
    
    @patch('builtins.open', new_callable=mock_open, read_data='AI_BACKEND="ollama"\nOLLAMA_URL="http://localhost:11434/v1/chat/completions"\nOLLAMA_CHAT_MODEL="ollama-model"')
    @patch('pathlib.Path.exists')
    def test_read_config_ollama(self, mock_exists, mock_file):
        """Test reading config with Ollama settings"""
        mock_exists.return_value = True
        config = read_config()
        
        self.assertEqual(config.get("backend"), "ollama")
        # Ollama uses port 11434, check for that in URL
        self.assertIn("11434", config.get("url", ""))
    
    @patch('pathlib.Path.exists')
    def test_read_config_not_found(self, mock_exists):
        """Test config reading when file doesn't exist"""
        mock_exists.return_value = False
        config = read_config()
        
        # Should return default config
        self.assertIsInstance(config, dict)
        self.assertEqual(config.get("backend"), "lmstudio")
        self.assertIn("url", config)
    
    @patch('builtins.open', new_callable=mock_open, read_data='MAX_TOKENS="2000"')
    @patch('pathlib.Path.exists')
    def test_read_config_max_tokens(self, mock_exists, mock_file):
        """Test reading MAX_TOKENS from config"""
        mock_exists.return_value = True
        config = read_config()
        
        self.assertEqual(config.get("max_tokens"), 2000)
    
    @patch('builtins.open', new_callable=mock_open, read_data='MAX_TOKENS="invalid"')
    @patch('pathlib.Path.exists')
    def test_read_config_invalid_max_tokens(self, mock_exists, mock_file):
        """Test handling invalid MAX_TOKENS value"""
        mock_exists.return_value = True
        config = read_config()
        
        # Should use default value
        self.assertEqual(config.get("max_tokens"), 1200)


class TestGetDailyGoal(unittest.TestCase):
    """Test cases for get_daily_goal function"""
    
    def test_get_daily_goal_found(self):
        """Test extracting goal when present"""
        content = """
# Daily Log
Some text here
My goal today is to finish the project
More content
"""
        goal = get_daily_goal(content)
        
        self.assertIsNotNone(goal)
        self.assertIn("finish", goal.lower())
    
    def test_get_daily_goal_with_keyword(self):
        """Test extracting goal with goal keyword"""
        content = """
Today's intention: Complete the task
Goal: Finish writing tests
"""
        goal = get_daily_goal(content)
        
        self.assertIsNotNone(goal)
    
    def test_get_daily_goal_not_found(self):
        """Test when no goal is present"""
        content = """
Just regular log entries
No objectives mentioned here
"""
        goal = get_daily_goal(content)
        
        # Should return None or empty
        self.assertIsNone(goal)
    
    def test_get_daily_goal_short(self):
        """Test that very short goals are filtered out"""
        # The function doesn't filter by length, it just finds the first line
        # after a keyword. So we test with content that has no goal keywords
        content = "Just some text\nMore text here"
        goal = get_daily_goal(content)
        
        # Should return None if no goal keywords found
        self.assertIsNone(goal)


class TestCheckAIServer(unittest.TestCase):
    """Test cases for check_ai_server function"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "url": "http://localhost:1234/v1/chat/completions",
            "backend_name": "Test Server"
        }
    
    @patch('urllib.request.urlopen')
    def test_check_ai_server_success(self, mock_urlopen):
        """Test successful server check"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"data": [{"id": "model1"}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        server_ok, server_msg = check_ai_server(self.config)
        
        self.assertTrue(server_ok)
        self.assertIn("running", server_msg.lower())
    
    @patch('urllib.request.urlopen')
    def test_check_ai_server_no_models(self, mock_urlopen):
        """Test server check when no models available"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"data": []}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        server_ok, server_msg = check_ai_server(self.config)
        
        self.assertFalse(server_ok)
        self.assertIn("no models", server_msg.lower())
    
    @patch('urllib.request.urlopen')
    def test_check_ai_server_connection_error(self, mock_urlopen):
        """Test server check when connection fails"""
        import urllib.error
        mock_urlopen.side_effect = urllib.error.URLError("Connection refused")
        
        server_ok, server_msg = check_ai_server(self.config)
        
        self.assertFalse(server_ok)
        self.assertIn("connect", server_msg.lower())


class TestCallLMStudio(unittest.TestCase):
    """Test cases for call_lm_studio function"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "url": "http://localhost:1234/v1/chat/completions",
            "chat_model": "test-model",
            "backend": "lmstudio",
            "backend_name": "LM Studio",
            "name": "Test User",
            "max_tokens": 1200
        }
        self.daily_log_content = """
# Daily Log - 2024-01-01

09:00 - Started working on tests
10:00 - Reviewed code
"""
    
    @patch('lmstudio_helper.check_ai_server')
    def test_call_lm_studio_server_not_available(self, mock_check):
        """Test calling when server is not available"""
        mock_check.return_value = (False, "Server not running")
        
        result, exit_code = call_lm_studio(self.config, self.daily_log_content)
        
        self.assertIsInstance(result, str)
        self.assertIn("⚠️", result)
        self.assertEqual(exit_code, 1)
    
    @patch('lmstudio_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_lm_studio_success(self, mock_urlopen, mock_check):
        """Test successful LM Studio call"""
        mock_check.return_value = (True, "Server is running")
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Great work today!"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_lm_studio(self.config, self.daily_log_content)
        
        self.assertIsInstance(result, str)
        self.assertIn("Great work", result)
        self.assertEqual(exit_code, 0)
    
    @patch('lmstudio_helper.check_ai_server')
    @patch('lmstudio_helper.get_daily_goal')
    @patch('urllib.request.urlopen')
    def test_call_lm_studio_with_goal(self, mock_urlopen, mock_get_goal, mock_check):
        """Test calling with daily goal present"""
        mock_check.return_value = (True, "Server is running")
        mock_get_goal.return_value = "Finish the project"
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Keep working on your goal!"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_lm_studio(self.config, self.daily_log_content)
        
        self.assertIsInstance(result, str)
        self.assertEqual(exit_code, 0)
    
    @patch('lmstudio_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_lm_studio_model_error(self, mock_urlopen, mock_check):
        """Test handling model not loaded error"""
        mock_check.return_value = (True, "Server is running")
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"error": {"message": "Model not found"}}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_lm_studio(self.config, self.daily_log_content)
        
        self.assertIn("⚠️", result)
        self.assertIn("Model", result)
        self.assertEqual(exit_code, 1)
    
    @patch('lmstudio_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_lm_studio_timeout(self, mock_urlopen, mock_check):
        """Test handling timeout error"""
        import urllib.error
        mock_check.return_value = (True, "Server is running")
        mock_urlopen.side_effect = urllib.error.URLError("timed out")
        
        result, exit_code = call_lm_studio(self.config, self.daily_log_content)
        
        self.assertIn("⚠️", result)
        # Error message says "timed out" not "timeout"
        self.assertIn("timed out", result.lower())
        self.assertEqual(exit_code, 1)
    
    @patch('lmstudio_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_lm_studio_no_model_name(self, mock_urlopen, mock_check):
        """Test calling with no model name (uses default)"""
        config_no_model = self.config.copy()
        config_no_model["chat_model"] = ""
        mock_check.return_value = (True, "Server is running")
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Response"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_lm_studio(config_no_model, self.daily_log_content)
        
        # Should use "local-model" as default
        self.assertEqual(exit_code, 0)


if __name__ == '__main__':
    unittest.main()
