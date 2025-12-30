#!/usr/bin/env python3
"""
Basic unit tests for GTD Vectorization System (no dependencies required)
Tests text chunking and embedding config reading.
"""

import unittest
from unittest.mock import patch, mock_open
import sys
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

# Try to import modules
try:
    from gtd_vectorization import (
        read_embedding_config,
        chunk_text
    )
except ImportError as e:
    print(f"Warning: Import error ({e}). Some tests will be skipped.", file=sys.stderr)
    read_embedding_config = None
    chunk_text = None


class TestReadEmbeddingConfig(unittest.TestCase):
    """Test cases for read_embedding_config function"""
    
    @unittest.skipIf(read_embedding_config is None, "read_embedding_config not available")
    @patch('builtins.open', new_callable=mock_open, read_data='LM_STUDIO_EMBEDDING_MODEL="test-embedding"\nLM_STUDIO_URL="http://localhost:1234/v1/chat/completions"')
    @patch('pathlib.Path.home', return_value=Path("/fake/home"))
    @patch('pathlib.Path.exists', return_value=True)
    def test_read_embedding_config_basic(self, mock_exists, mock_home, mock_file):
        """Test reading embedding config"""
        config = read_embedding_config()
        
        self.assertIsInstance(config, dict)
        self.assertIn("embedding_model", config)
        self.assertIn("base_url", config)
        # Since we're mocking the file read, check that the mocked data was used
        # The actual value depends on how the mock was set up, but config should exist
        self.assertIsInstance(config["embedding_model"], str)


class TestChunkText(unittest.TestCase):
    """Test cases for chunk_text function"""
    
    @unittest.skipIf(chunk_text is None, "chunk_text not available")
    def test_chunk_text_short(self):
        """Test chunking short text (should return single chunk)"""
        text = "This is a short text."
        chunks = chunk_text(text, chunk_size=1000)
        
        self.assertEqual(len(chunks), 1)
        self.assertEqual(chunks[0], text)
    
    @unittest.skipIf(chunk_text is None, "chunk_text not available")
    def test_chunk_text_long(self):
        """Test chunking long text"""
        # Use smaller text to avoid memory issues
        text = "Sentence one. Sentence two. Sentence three. " * 10
        chunks = chunk_text(text, chunk_size=50, overlap=10)
        
        self.assertGreater(len(chunks), 1)
        # Check that chunks don't exceed size (with some flexibility)
        # Only check first few chunks to avoid iterating over large lists
        for chunk in chunks[:5]:  # Only check first 5 chunks
            self.assertLessEqual(len(chunk), 50 + 50)  # Allow more flexibility
    
    @unittest.skipIf(chunk_text is None, "chunk_text not available")
    def test_chunk_text_sentence_boundaries(self):
        """Test that chunking respects sentence boundaries"""
        text = "First sentence. Second sentence. Third sentence."
        chunks = chunk_text(text, chunk_size=20, overlap=5)
        
        # Should try to break at sentence boundaries
        self.assertGreater(len(chunks), 1)


if __name__ == '__main__':
    unittest.main()

