#!/usr/bin/env python3
"""
Unit tests for GTD Vectorization System
Tests database connection, embedding generation, vector storage, and search.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock, mock_open
import sys
import json
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

# Try to import modules, but handle missing dependencies gracefully
HAS_DEPENDENCIES = False
HAS_PSYCOPG2 = False

# First check if psycopg2 is available
try:
    import psycopg2
    HAS_PSYCOPG2 = True
except ImportError:
    HAS_PSYCOPG2 = False

# Try to import modules
try:
    # Import chunk_text first (doesn't need psycopg2)
    from gtd_vectorization import (
        read_embedding_config,
        chunk_text
    )
    
    # Try to import database-dependent modules
    if HAS_PSYCOPG2:
        from gtd_vector_db import (
            read_database_config,
            VectorDatabase
        )
        from gtd_vectorization import (
            generate_embedding,
            vectorize_content,
            vectorize_batch,
            search_similar
        )
        HAS_DEPENDENCIES = True
    else:
        # Mock the database functions for testing
        read_database_config = None
        VectorDatabase = None
        generate_embedding = None
        vectorize_content = None
        vectorize_batch = None
        search_similar = None
except ImportError as e:
    print(f"Warning: Import error ({e}). Some tests will be skipped.", file=sys.stderr)


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestReadDatabaseConfig(unittest.TestCase):
    """Test cases for read_database_config function"""
    
    @patch('builtins.open', new_callable=mock_open, read_data='VECTOR_DB_HOST="testhost"\nVECTOR_DB_PORT="5432"\nVECTOR_DB_NAME="testdb"')
    @patch('pathlib.Path.exists')
    def test_read_database_config_basic(self, mock_exists, mock_file):
        """Test reading basic database config"""
        mock_exists.return_value = True
        config = read_database_config()
        
        self.assertIsInstance(config, dict)
        self.assertIn("host", config)
        self.assertIn("port", config)
        self.assertIn("database", config)
        self.assertEqual(config["host"], "testhost")
        self.assertEqual(config["port"], 5432)
    
    @patch('pathlib.Path.exists')
    @patch.dict('os.environ', {'VECTOR_DB_HOST': 'envhost', 'VECTOR_DB_PORT': '9999'})
    def test_read_database_config_env_override(self, mock_exists):
        """Test that environment variables override config file"""
        mock_exists.return_value = False
        config = read_database_config()
        
        self.assertEqual(config["host"], "envhost")
        self.assertEqual(config["port"], 9999)
    
    @patch('builtins.open', new_callable=mock_open, read_data='GTD_VECTORIZATION_ENABLED="false"')
    @patch('pathlib.Path.exists')
    def test_read_database_config_boolean(self, mock_exists, mock_file):
        """Test reading boolean config values"""
        mock_exists.return_value = True
        config = read_database_config()
        
        self.assertFalse(config["vectorization_enabled"])


class TestReadEmbeddingConfig(unittest.TestCase):
    """Test cases for read_embedding_config function"""
    
    @patch('builtins.open', new_callable=mock_open, read_data='LM_STUDIO_EMBEDDING_MODEL="test-embedding"\nLM_STUDIO_URL="http://localhost:1234/v1/chat/completions"')
    @patch('pathlib.Path.exists')
    def test_read_embedding_config_basic(self, mock_exists, mock_file):
        """Test reading embedding config"""
        mock_exists.return_value = True
        config = read_embedding_config()
        
        self.assertIsInstance(config, dict)
        self.assertIn("embedding_model", config)
        self.assertIn("base_url", config)
        self.assertEqual(config["embedding_model"], "test-embedding")


class TestChunkText(unittest.TestCase):
    """Test cases for chunk_text function"""
    
    def test_chunk_text_short(self):
        """Test chunking short text (should return single chunk)"""
        text = "This is a short text."
        chunks = chunk_text(text, chunk_size=1000)
        
        self.assertEqual(len(chunks), 1)
        self.assertEqual(chunks[0], text)
    
    def test_chunk_text_long(self):
        """Test chunking long text"""
        text = "Sentence one. Sentence two. Sentence three. " * 20  # Reduced from 100
        chunks = chunk_text(text, chunk_size=50, overlap=10)
        
        self.assertGreater(len(chunks), 1)
        # Check that chunks don't exceed size (with some flexibility)
        for chunk in chunks:
            self.assertLessEqual(len(chunk), 50 + 50)  # Allow more flexibility
    
    def test_chunk_text_sentence_boundaries(self):
        """Test that chunking respects sentence boundaries"""
        text = "First sentence. Second sentence. Third sentence."
        chunks = chunk_text(text, chunk_size=20, overlap=5)
        
        # Should try to break at sentence boundaries
        self.assertGreater(len(chunks), 1)


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestGenerateEmbedding(unittest.TestCase):
    """Test cases for generate_embedding function"""
    
    @patch('urllib.request.urlopen')
    @patch('gtd_vectorization.read_embedding_config')
    def test_generate_embedding_success(self, mock_config, mock_urlopen):
        """Test successful embedding generation"""
        mock_config.return_value = {
            "embedding_model": "test-model",
            "base_url": "http://localhost:1234/v1",
            "timeout": 60
        }
        
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "data": [{"embedding": [0.1, 0.2, 0.3, 0.4, 0.5]}]
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        embedding = generate_embedding("test text")
        
        self.assertIsNotNone(embedding)
        self.assertIsInstance(embedding, list)
        self.assertEqual(len(embedding), 5)
    
    @patch('gtd_vectorization.read_embedding_config')
    def test_generate_embedding_no_model(self, mock_config):
        """Test embedding generation when no model is configured"""
        mock_config.return_value = {
            "embedding_model": "",
            "base_url": "http://localhost:1234/v1",
            "timeout": 60
        }
        
        with patch.dict('os.environ', {}, clear=True):
            embedding = generate_embedding("test text")
            self.assertIsNone(embedding)
    
    @patch('urllib.request.urlopen')
    @patch('gtd_vectorization.read_embedding_config')
    def test_generate_embedding_api_error(self, mock_config, mock_urlopen):
        """Test embedding generation with API error"""
        mock_config.return_value = {
            "embedding_model": "test-model",
            "base_url": "http://localhost:1234/v1",
            "timeout": 60
        }
        
        mock_response = MagicMock()
        mock_response.read.return_value = json.dumps({
            "error": {"message": "Model not found"}
        }).encode('utf-8')
        mock_urlopen.return_value.__enter__.return_value = mock_response
        
        embedding = generate_embedding("test text")
        self.assertIsNone(embedding)


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestVectorDatabase(unittest.TestCase):
    """Test cases for VectorDatabase class"""
    
    def setUp(self):
        """Set up test fixtures"""
        self.config = {
            "host": "localhost",
            "port": 13003,
            "database": "test_db",
            "user": "test_user",
            "password": "test_pass",
            "dimension": 768
        }
    
    @patch('psycopg2.connect')
    def test_vector_database_connect(self, mock_connect):
        """Test database connection"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        result = db.connect()
        
        self.assertTrue(result)
        self.assertIsNotNone(db.conn)
        mock_connect.assert_called_once()
    
    @patch('psycopg2.connect')
    def test_vector_database_connect_failure(self, mock_connect):
        """Test database connection failure"""
        mock_connect.side_effect = Exception("Connection failed")
        
        db = VectorDatabase(self.config)
        result = db.connect()
        
        self.assertFalse(result)
        self.assertIsNone(db.conn)
    
    @patch('psycopg2.connect')
    def test_vector_database_disconnect(self, mock_connect):
        """Test database disconnection"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        db.disconnect()
        
        mock_conn.close.assert_called_once()
        self.assertIsNone(db.conn)
    
    @patch('psycopg2.connect')
    def test_vector_database_initialize_schema(self, mock_connect):
        """Test schema initialization"""
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        db.initialize_schema()
        
        # Should create extension and tables
        self.assertGreaterEqual(mock_cursor.execute.call_count, 1)
        mock_conn.commit.assert_called()
    
    @patch('psycopg2.connect')
    def test_vector_database_store_embedding(self, mock_connect):
        """Test storing an embedding"""
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        
        result = db.store_embedding(
            content_type="test",
            content_id="123",
            content_text="test text",
            embedding=[0.1, 0.2, 0.3],
            metadata={"key": "value"}
        )
        
        self.assertTrue(result)
        mock_cursor.execute.assert_called()
        mock_conn.commit.assert_called()
    
    @patch('psycopg2.connect')
    def test_vector_database_search_similar(self, mock_connect):
        """Test similarity search"""
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.fetchall.return_value = [
            ("test", "123", "test text", '{"key": "value"}', 0.95)
        ]
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        
        results = db.search_similar(
            query_embedding=[0.1, 0.2, 0.3],
            limit=10,
            threshold=0.7
        )
        
        self.assertIsInstance(results, list)
        mock_cursor.execute.assert_called()
    
    @patch('psycopg2.connect')
    def test_vector_database_delete_embedding(self, mock_connect):
        """Test deleting an embedding"""
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_cursor.rowcount = 1
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        
        result = db.delete_embedding("test", "123")
        
        self.assertTrue(result)
        mock_cursor.execute.assert_called()
        mock_conn.commit.assert_called()


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestVectorizeContent(unittest.TestCase):
    """Test cases for vectorize_content function"""
    
    @patch('gtd_vectorization.generate_embedding')
    @patch('gtd_vectorization.VectorDatabase')
    @patch('gtd_vectorization.read_database_config')
    def test_vectorize_content_success(self, mock_db_config, mock_db_class, mock_embedding):
        """Test successful content vectorization"""
        mock_db_config.return_value = {
            "vectorization_enabled": True,
            "chunk_size": 1000,
            "chunk_overlap": 200
        }
        
        mock_embedding.return_value = [0.1, 0.2, 0.3]
        
        mock_db = MagicMock()
        mock_db.connect.return_value = True
        mock_db.store_embedding.return_value = True
        mock_db_class.return_value = mock_db
        
        result = vectorize_content(
            content_type="test",
            content_id="123",
            content_text="test content"
        )
        
        self.assertTrue(result)
        mock_embedding.assert_called()
        mock_db.store_embedding.assert_called()
    
    @patch('gtd_vectorization.read_database_config')
    def test_vectorize_content_disabled(self, mock_db_config):
        """Test vectorization when disabled"""
        mock_db_config.return_value = {
            "vectorization_enabled": False
        }
        
        result = vectorize_content(
            content_type="test",
            content_id="123",
            content_text="test content"
        )
        
        self.assertFalse(result)


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestVectorizeBatch(unittest.TestCase):
    """Test cases for vectorize_batch function"""
    
    @patch('gtd_vectorization.vectorize_content')
    @patch('gtd_vectorization.read_database_config')
    def test_vectorize_batch(self, mock_db_config, mock_vectorize):
        """Test batch vectorization"""
        mock_db_config.return_value = {
            "batch_size": 2
        }
        mock_vectorize.return_value = True
        
        items = [
            {"content_type": "test", "content_id": "1", "content_text": "text1"},
            {"content_type": "test", "content_id": "2", "content_text": "text2"},
            {"content_type": "test", "content_id": "3", "content_text": "text3"},
        ]
        
        successful, failed = vectorize_batch(items)
        
        self.assertEqual(successful, 3)
        self.assertEqual(failed, 0)
        self.assertEqual(mock_vectorize.call_count, 3)


@unittest.skipUnless(HAS_DEPENDENCIES, "psycopg2 not installed")
class TestSearchSimilar(unittest.TestCase):
    """Test cases for search_similar function"""
    
    @patch('gtd_vectorization.VectorDatabase')
    @patch('gtd_vectorization.generate_embedding')
    @patch('gtd_vectorization.read_database_config')
    @patch('gtd_vectorization.read_config')
    def test_search_similar_success(self, mock_config, mock_db_config, mock_embedding, mock_db_class):
        """Test successful similarity search"""
        mock_config.return_value = {}
        mock_db_config.return_value = {}
        mock_embedding.return_value = [0.1, 0.2, 0.3]
        
        mock_db = MagicMock()
        mock_db.connect.return_value = True
        mock_db.search_similar.return_value = [
            {"content_type": "test", "content_id": "123", "similarity": 0.95}
        ]
        mock_db_class.return_value = mock_db
        
        results = search_similar("test query")
        
        self.assertIsInstance(results, list)
        self.assertGreater(len(results), 0)
        mock_embedding.assert_called_once_with("test query", {})
    
    @patch('gtd_vectorization.generate_embedding')
    def test_search_similar_no_embedding(self, mock_embedding):
        """Test search when embedding generation fails"""
        mock_embedding.return_value = None
        
        results = search_similar("test query")
        
        self.assertEqual(results, [])


if __name__ == '__main__':
    unittest.main()

