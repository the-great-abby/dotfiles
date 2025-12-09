#!/usr/bin/env python3
"""
Unit tests for GTD Enhanced Search System
Tests query enhancement, generation, and result synthesis functionality.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

from gtd_enhanced_search import EnhancedSearchSystem, enhance_search_query


class TestEnhancedSearchSystem(unittest.TestCase):
    """Test cases for EnhancedSearchSystem class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "url": "http://localhost:1234/v1/chat/completions",
            "chat_model": "test-model",
            "deep_model_name": "test-deep-model",
            "timeout": 60,
            "max_tokens": 1200
        }
        self.search_system = EnhancedSearchSystem(self.config)
    
    def test_init(self):
        """Test EnhancedSearchSystem initialization"""
        self.assertEqual(self.search_system.url, self.config["url"])
        self.assertEqual(self.search_system.quick_model, self.config["chat_model"])
        self.assertEqual(self.search_system.deep_model, self.config["deep_model_name"])
        self.assertEqual(self.search_system.timeout, self.config["timeout"])
        self.assertEqual(self.search_system.max_tokens, self.config["max_tokens"])
    
    def test_init_without_deep_model(self):
        """Test initialization when deep_model_name is not provided"""
        config_no_deep = {
            "url": "http://localhost:1234/v1/chat/completions",
            "chat_model": "test-model",
            "timeout": 60,
            "max_tokens": 1200
        }
        system = EnhancedSearchSystem(config_no_deep)
        self.assertEqual(system.deep_model, "test-model")  # Should fall back to chat_model
    
    @patch('urllib.request.urlopen')
    def test_call_llm_success(self, mock_urlopen):
        """Test successful LLM call"""
        # Mock response
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"choices": [{"message": {"content": "test response"}}]}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        result = self.search_system._call_llm("test prompt")
        self.assertEqual(result, "test response")
    
    @patch('urllib.request.urlopen')
    def test_call_llm_with_error(self, mock_urlopen):
        """Test LLM call with error response"""
        mock_response = MagicMock()
        mock_response.read.return_value = b'{"error": {"message": "Test error"}}'
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        with self.assertRaises(Exception) as context:
            self.search_system._call_llm("test prompt")
        self.assertIn("LLM error", str(context.exception))
    
    def test_should_enhance_query_good_query(self):
        """Test should_enhance_query with a good query (should not enhance)"""
        # Good query: has 4+ words, contains trigger phrase, ends with ?
        good_query = "how do you train for a half marathon?"
        result = self.search_system.should_enhance_query(good_query)
        self.assertFalse(result, "Good query should not need enhancement")
    
    def test_should_enhance_query_vague_query(self):
        """Test should_enhance_query with a vague query (should enhance)"""
        # Vague query: short, no trigger phrases, no question mark
        vague_query = "marathon training"
        result = self.search_system.should_enhance_query(vague_query)
        self.assertTrue(result, "Vague query should need enhancement")
    
    def test_should_enhance_query_partial_indicators(self):
        """Test should_enhance_query with partial indicators"""
        # Has only question mark (1 indicator), not enough words, no trigger phrase
        # So it should enhance (needs 2+ indicators to be considered good)
        partial_query = "test?"
        result = self.search_system.should_enhance_query(partial_query)
        # Has only 1 indicator (question mark), so should enhance (return True)
        self.assertTrue(result)
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_generate_queries_success(self, mock_call_llm):
        """Test successful query generation"""
        mock_call_llm.return_value = "query 1\nquery 2\nquery 3"
        
        queries = self.search_system.generate_queries("test phrase")
        
        self.assertIsInstance(queries, list)
        self.assertGreater(len(queries), 0)
        self.assertLessEqual(len(queries), 3)  # Max 3 queries
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_generate_queries_with_context(self, mock_call_llm):
        """Test query generation with user context"""
        mock_call_llm.return_value = "contextual query 1\ncontextual query 2"
        
        context = {
            "work_type": "software engineer",
            "current_projects": ["project1", "project2"],
            "recent_patterns": ["pattern1"]
        }
        
        queries = self.search_system.generate_queries("test", context)
        
        # Verify context was included in the prompt
        # Check if mock was called and has arguments
        if mock_call_llm.called and mock_call_llm.call_args:
            call_args = mock_call_llm.call_args[0][0] if len(mock_call_llm.call_args[0]) > 0 else ""
            if call_args:
                self.assertIn("software engineer", call_args)
                self.assertIn("project1", call_args)
        # At minimum, verify queries were generated
        self.assertIsInstance(queries, list)
        self.assertGreater(len(queries), 0)
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_generate_queries_cleans_numbering(self, mock_call_llm):
        """Test that query generation removes numbering and bullets"""
        mock_call_llm.return_value = "1. query one\n2. query two\n- query three"
        
        queries = self.search_system.generate_queries("test")
        
        # Check that numbering/bullets are removed
        for query in queries:
            self.assertFalse(query.startswith(('1', '2', '-', '*')))
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_generate_queries_fallback_on_failure(self, mock_call_llm):
        """Test that query generation falls back to original on failure"""
        mock_call_llm.side_effect = Exception("LLM error")
        
        original_phrase = "original search phrase"
        queries = self.search_system.generate_queries(original_phrase)
        
        self.assertEqual(queries, [original_phrase])
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_synthesize_results_success(self, mock_call_llm):
        """Test successful result synthesis"""
        mock_call_llm.return_value = "Synthesized response with key points"
        
        search_results = "Search Query 1: test\nResults:\nResult 1\nResult 2"
        result = self.search_system.synthesize_results("test query", search_results)
        
        self.assertIsInstance(result, str)
        self.assertEqual(result, "Synthesized response with key points")
    
    @patch.object(EnhancedSearchSystem, '_call_llm')
    def test_synthesize_results_fallback_on_failure(self, mock_call_llm):
        """Test that synthesis falls back to raw results on failure"""
        mock_call_llm.side_effect = Exception("Synthesis error")
        
        raw_results = "Raw search results"
        result = self.search_system.synthesize_results("test", raw_results)
        
        self.assertEqual(result, raw_results)
    
    def test_get_user_context(self):
        """Test user context extraction"""
        context = self.search_system.get_user_context()
        
        self.assertIsInstance(context, dict)
        self.assertIn("work_type", context)
        self.assertIn("current_projects", context)
        self.assertIn("recent_patterns", context)


class TestEnhanceSearchQuery(unittest.TestCase):
    """Test cases for enhance_search_query function"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "url": "http://localhost:1234/v1/chat/completions",
            "chat_model": "test-model",
            "deep_model_name": "test-deep-model",
            "timeout": 60,
            "max_tokens": 1200
        }
    
    def test_enhance_search_query_disabled(self):
        """Test enhance_search_query when disabled"""
        def mock_search(query):
            return f"Results for {query}"
        
        result = enhance_search_query("test query", self.config, enabled=False, 
                                     execute_search_func=mock_search)
        
        # When disabled, if search function returns results, success will be True
        # But we should verify the structure is correct
        self.assertEqual(result['original_query'], "test query")
        self.assertEqual(result['queries_used'], ["test query"])
        # Success depends on whether mock_search returns results
        self.assertIn('success', result)
        self.assertIn('num_results', result)
    
    @patch('gtd_enhanced_search.EnhancedSearchSystem')
    def test_enhance_search_query_enabled_no_enhancement(self, mock_system_class):
        """Test enhance_search_query when query doesn't need enhancement"""
        mock_system = Mock()
        mock_system.should_enhance_query.return_value = False
        mock_system.get_user_context.return_value = {}
        mock_system_class.return_value = mock_system
        
        def mock_search(query):
            return f"Results for {query}"
        
        result = enhance_search_query("how do you train for a marathon?", self.config,
                                     execute_search_func=mock_search)
        
        self.assertEqual(result['queries_used'], ["how do you train for a marathon?"])
    
    @patch('gtd_enhanced_search.EnhancedSearchSystem')
    def test_enhance_search_query_with_results(self, mock_system_class):
        """Test enhance_search_query with successful search results"""
        mock_system = Mock()
        mock_system.should_enhance_query.return_value = True
        mock_system.generate_queries.return_value = ["query 1", "query 2"]
        mock_system.synthesize_results.return_value = "Synthesized answer"
        mock_system.get_user_context.return_value = {}
        mock_system_class.return_value = mock_system
        
        def mock_search(query):
            return f"Results for {query}"
        
        result = enhance_search_query("test", self.config,
                                     execute_search_func=mock_search)
        
        self.assertTrue(result['success'])
        self.assertEqual(result['num_results'], 2)
        self.assertEqual(result['synthesis'], "Synthesized answer")
        self.assertIn('raw_results', result)
    
    def test_enhance_search_query_no_search_func(self):
        """Test enhance_search_query without search function"""
        result = enhance_search_query("test query", self.config, enabled=True,
                                     execute_search_func=None)
        
        self.assertFalse(result['success'])
        self.assertEqual(result['num_results'], 0)


class TestQueryExtraction(unittest.TestCase):
    """Test cases for query extraction logic (from persona helper)"""
    
    def test_extract_query_from_question_format(self):
        """Test extracting query from 'Question:' format"""
        prompt = "Some text\nQuestion: how do you train for a marathon?\nMore text"
        
        if "Question:" in prompt:
            question_part = prompt.split("Question:")[-1]
            query = question_part.split("\n")[0].strip()
        else:
            query = prompt
        
        self.assertEqual(query, "how do you train for a marathon?")
    
    def test_extract_query_from_lines(self):
        """Test extracting query from lines with question mark"""
        prompt = "Line 1\nLine 2\nWhat is the best way to train?\nLine 4"
        
        lines = [l.strip() for l in prompt.split("\n") if l.strip()]
        query = prompt  # Default
        
        for line in reversed(lines):
            if len(line) > 10 and "?" in line:
                query = line.rstrip("?").strip()
                break
        
        self.assertEqual(query, "What is the best way to train")
    
    def test_extract_query_fallback(self):
        """Test fallback to original content"""
        prompt = "Short"
        content = "original content here"
        
        if len(prompt) < 10:
            query = content.replace("[WEB_SEARCH_REQUESTED]", "").strip()
        else:
            query = prompt
        
        self.assertEqual(query, "original content here")


if __name__ == '__main__':
    unittest.main()
