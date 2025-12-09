#!/usr/bin/env python3
"""
Unit tests for GTD Persona Helper
Tests persona selection, config reading, web search, and LLM integration.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock, mock_open
import sys
import json
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

from gtd_persona_helper import (
    read_config,
    check_ai_server,
    call_persona,
    execute_web_search,
    _extract_user_context,
    filter_relevant_acronyms,
    read_acronyms,
    PERSONAS
)


class TestReadConfig(unittest.TestCase):
    """Test cases for read_config function"""
    
    @patch('builtins.open', new_callable=mock_open, read_data='GTD_USER_NAME="Test User"\nAI_BACKEND="lmstudio"\nLM_STUDIO_URL="http://localhost:1234/v1/chat/completions"')
    @patch('pathlib.Path.exists')
    def test_read_config_basic(self, mock_exists, mock_file):
        """Test reading basic config file"""
        mock_exists.return_value = True
        config = read_config()
        
        self.assertIsInstance(config, dict)
        self.assertIn("name", config)
        self.assertIn("backend", config)
        self.assertIn("url", config)
    
    @patch('pathlib.Path.exists')
    def test_read_config_not_found(self, mock_exists):
        """Test config reading when file doesn't exist"""
        mock_exists.return_value = False
        config = read_config()
        
        # Should return default config
        self.assertIsInstance(config, dict)
        self.assertEqual(config.get("backend"), "lmstudio")
    
    @patch('builtins.open', new_callable=mock_open, read_data='AI_BACKEND="ollama"\nOLLAMA_URL="http://localhost:11434/v1/chat/completions"')
    @patch('pathlib.Path.exists')
    def test_read_config_ollama(self, mock_exists, mock_file):
        """Test reading config with Ollama backend"""
        mock_exists.return_value = True
        config = read_config()
        
        self.assertEqual(config.get("backend"), "ollama")
        # Ollama uses port 11434, check for that in URL
        self.assertIn("11434", config.get("url", ""))


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
        """Test server check when no models are available"""
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


class TestExtractUserContext(unittest.TestCase):
    """Test cases for _extract_user_context function"""
    
    def test_extract_user_context_basic(self):
        """Test basic user context extraction"""
        config = {
            "name": "Test User",
            "work_type": "engineer"
        }
        
        context = _extract_user_context(config)
        
        self.assertIsInstance(context, dict)
        self.assertIn("work_type", context)
        self.assertIn("current_projects", context)
        self.assertIn("recent_patterns", context)
    
    def test_extract_user_context_empty(self):
        """Test context extraction with empty config"""
        config = {}
        context = _extract_user_context(config)
        
        self.assertIsInstance(context, dict)
        # Should still have required keys
        self.assertIn("work_type", context)
        self.assertIn("current_projects", context)


class TestReadAcronyms(unittest.TestCase):
    """Test cases for read_acronyms function"""
    
    @patch('builtins.open', new_callable=mock_open, read_data='[{"acronym": "API", "definition": "Application Programming Interface"}]')
    @patch('pathlib.Path.exists')
    def test_read_acronyms_success(self, mock_exists, mock_file):
        """Test reading acronyms from file"""
        mock_exists.return_value = True
        acronyms = read_acronyms()
        
        self.assertIsInstance(acronyms, list)
        if len(acronyms) > 0:
            self.assertIn("acronym", acronyms[0])
            self.assertIn("definition", acronyms[0])
    
    @patch('pathlib.Path.exists')
    def test_read_acronyms_file_not_found(self, mock_exists):
        """Test reading acronyms when file doesn't exist"""
        mock_exists.return_value = False
        acronyms = read_acronyms()
        
        # Should return empty list or handle gracefully
        self.assertIsInstance(acronyms, list)


class TestFilterRelevantAcronyms(unittest.TestCase):
    """Test cases for filter_relevant_acronyms function"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.acronyms = [
            {"acronym": "API", "definition": "Application Programming Interface"},
            {"acronym": "GTD", "definition": "Getting Things Done"},
            {"acronym": "LLM", "definition": "Large Language Model"},
            {"acronym": "HTTP", "definition": "HyperText Transfer Protocol"}
        ]
    
    def test_filter_relevant_acronyms_with_match(self):
        """Test filtering acronyms when content matches"""
        content = "I need to use the API to call the LLM"
        filtered = filter_relevant_acronyms(self.acronyms, content, max_acronyms=10)
        
        self.assertIsInstance(filtered, list)
        # Should include API and LLM
        acronym_texts = [a.get("acronym", "") for a in filtered]
        self.assertIn("API", acronym_texts)
        self.assertIn("LLM", acronym_texts)
    
    def test_filter_relevant_acronyms_no_match(self):
        """Test filtering when no acronyms match"""
        content = "This is just regular text with no acronyms"
        filtered = filter_relevant_acronyms(self.acronyms, content, max_acronyms=10)
        
        self.assertIsInstance(filtered, list)
    
    def test_filter_relevant_acronyms_max_limit(self):
        """Test that max_acronyms limit is respected"""
        content = "API GTD LLM HTTP"
        filtered = filter_relevant_acronyms(self.acronyms, content, max_acronyms=2)
        
        self.assertLessEqual(len(filtered), 2)


class TestExecuteWebSearch(unittest.TestCase):
    """Test cases for execute_web_search function"""
    
    @patch('gtd_persona_helper.execute_web_search')
    def test_execute_web_search_basic(self, mock_search):
        """Test basic web search execution"""
        mock_search.return_value = "Search results here"
        
        result = execute_web_search("test query")
        
        self.assertIsInstance(result, str)
    
    @patch('gtd_persona_helper.execute_web_search')
    def test_execute_web_search_with_enhanced(self, mock_search):
        """Test web search with enhanced search enabled"""
        mock_search.return_value = "Enhanced search results"
        
        result = execute_web_search("test query", use_enhanced_search=True)
        
        self.assertIsInstance(result, str)


class TestCallPersona(unittest.TestCase):
    """Test cases for call_persona function"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "url": "http://localhost:1234/v1/chat/completions",
            "chat_model": "test-model",
            "backend": "lmstudio",
            "backend_name": "Test Server",
            "name": "Test User"
        }
    
    def test_call_persona_invalid_persona(self):
        """Test calling with invalid persona"""
        result, exit_code = call_persona(self.config, "invalid_persona", "test content")
        
        self.assertIsInstance(result, str)
        self.assertIn("Unknown persona", result)
        self.assertEqual(exit_code, 1)
    
    @patch('gtd_persona_helper.check_ai_server')
    def test_call_persona_server_not_available(self, mock_check):
        """Test calling persona when server is not available"""
        mock_check.return_value = (False, "Server not running")
        
        result, exit_code = call_persona(self.config, "hank", "test content")
        
        self.assertIsInstance(result, str)
        self.assertIn("⚠️", result)
        self.assertEqual(exit_code, 1)
    
    @patch('gtd_persona_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_persona_success(self, mock_urlopen, mock_check):
        """Test successful persona call"""
        mock_check.return_value = (True, "Server is running")
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Test response"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_persona(self.config, "hank", "test content")
        
        self.assertIsInstance(result, str)
        self.assertEqual(exit_code, 0)
    
    @patch('gtd_persona_helper.check_ai_server')
    @patch('urllib.request.urlopen')
    def test_call_persona_with_skip_gtd_context(self, mock_urlopen, mock_check):
        """Test persona call with skip_gtd_context flag"""
        mock_check.return_value = (True, "Server is running")
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Test response"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_persona(
            self.config, "hank", "test content", 
            skip_gtd_context=True
        )
        
        self.assertIsInstance(result, str)
        self.assertEqual(exit_code, 0)
    
    @patch('gtd_persona_helper.check_ai_server')
    @patch('gtd_persona_helper.execute_web_search')
    @patch('urllib.request.urlopen')
    def test_call_persona_with_web_search(self, mock_urlopen, mock_web_search, mock_check):
        """Test persona call with web search requested"""
        mock_check.return_value = (True, "Server is running")
        mock_web_search.return_value = "Web search results"
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "Test response"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result, exit_code = call_persona(
            self.config, "hank", "test content",
            web_search_requested=True
        )
        
        self.assertIsInstance(result, str)
        # Web search should be called
        mock_web_search.assert_called()


class TestPersonas(unittest.TestCase):
    """Test cases for persona definitions"""
    
    def test_personas_defined(self):
        """Test that personas are properly defined"""
        self.assertIsInstance(PERSONAS, dict)
        self.assertGreater(len(PERSONAS), 0)
    
    def test_persona_structure(self):
        """Test that each persona has required fields"""
        required_fields = ["name", "system_prompt", "expertise", "temperature"]
        
        for persona_key, persona in PERSONAS.items():
            self.assertIsInstance(persona_key, str)
            self.assertIsInstance(persona, dict)
            
            for field in required_fields:
                self.assertIn(field, persona, f"Persona {persona_key} missing {field}")
    
    def test_persona_temperature_range(self):
        """Test that persona temperatures are in valid range"""
        for persona_key, persona in PERSONAS.items():
            temp = persona.get("temperature", 0.7)
            self.assertGreaterEqual(temp, 0.0, f"Persona {persona_key} temperature too low")
            self.assertLessEqual(temp, 1.0, f"Persona {persona_key} temperature too high")


if __name__ == '__main__':
    unittest.main()
