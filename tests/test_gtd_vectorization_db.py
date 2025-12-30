#!/usr/bin/env python3
"""
Database operation unit tests for GTD Vectorization System
Tests database connections, vectorization, and search (requires psycopg2, can be memory-intensive).
These tests are split into a separate file due to memory constraints when running the full test suite.
Run individually: python3 tests/test_gtd_vectorization_db.py
"""

import unittest
from unittest.mock import patch, MagicMock
import sys
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
    if HAS_PSYCOPG2:
        from gtd_vector_db import (
            read_database_config,
            VectorDatabase
        )
        from gtd_vectorization import (
            vectorize_content,
            vectorize_batch,
            search_similar
        )
        HAS_DEPENDENCIES = True
    else:
        read_database_config = None
        VectorDatabase = None
        vectorize_content = None
        vectorize_batch = None
        search_similar = None
except ImportError as e:
    print(f"Warning: Import error ({e}). Some tests will be skipped.", file=sys.stderr)
    read_database_config = None
    VectorDatabase = None
    vectorize_content = None
    vectorize_batch = None
    search_similar = None


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
    
    @patch('gtd_vector_db.psycopg2.connect')
    def test_vector_database_connect(self, mock_connect):
        """Test database connection"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn
        
        # VectorDatabase.__init__ calls _ensure_extension() which tries to connect
        # So we need to mock connect before instantiation - mock it to return mock_conn
        # for the __init__ call, then we'll test connect() separately
        db = VectorDatabase(self.config)
        # Reset call count to test explicit connect() call
        mock_connect.reset_mock()
        mock_connect.return_value = mock_conn
        result = db.connect()
        
        self.assertTrue(result)
        self.assertIsNotNone(db.conn)
        mock_connect.assert_called_once()
    
    @patch('gtd_vector_db.psycopg2.connect')
    def test_vector_database_connect_failure(self, mock_connect):
        """Test database connection failure"""
        mock_connect.side_effect = Exception("Connection failed")
        
        db = VectorDatabase(self.config)
        result = db.connect()
        
        self.assertFalse(result)
        self.assertIsNone(db.conn)
    
    @patch('gtd_vector_db.psycopg2.connect')
    def test_vector_database_disconnect(self, mock_connect):
        """Test database disconnection"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn
        
        db = VectorDatabase(self.config)
        db.connect()
        db.disconnect()
        
        mock_conn.close.assert_called_once()
        self.assertIsNone(db.conn)
    
    @patch('gtd_vector_db.psycopg2.connect')
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
    
    @patch('gtd_vector_db.psycopg2.connect')
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
    
    @patch('gtd_vector_db.psycopg2.connect')
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
    
    @patch('gtd_vector_db.psycopg2.connect')
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
    
    @patch('gtd_vector_db.psycopg2.connect')  # Safety patch - prevent any real DB connections
    @patch('gtd_vectorization.generate_embedding')
    @patch('gtd_vectorization.VectorDatabase')
    @patch('gtd_vectorization.read_database_config')
    @patch('gtd_vectorization.read_embedding_config')
    def test_vectorize_content_success(self, mock_embedding_config, mock_db_config, mock_db_class, mock_embedding, mock_psycopg2_connect):
        """Test successful content vectorization"""
        # Mock config reads to prevent real file I/O
        mock_embedding_config.return_value = {}
        mock_db_config.return_value = {
            "vectorization_enabled": True,
            "chunk_size": 1000,
            "chunk_overlap": 200
        }
        
        # Mock embedding generation
        mock_embedding.return_value = [0.1, 0.2, 0.3]
        
        # Mock database
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
    @patch('pathlib.Path.exists', return_value=False)
    @patch('pathlib.Path.home', return_value=Path("/fake/home"))
    def test_vectorize_content_disabled(self, mock_home, mock_exists, mock_db_config):
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
    
    @patch('gtd_vector_db.psycopg2.connect')  # Safety patch - prevent any real DB connections
    @patch('gtd_vectorization.VectorDatabase')
    @patch('gtd_vectorization.generate_embedding')
    @patch('gtd_vectorization.read_database_config')
    @patch('gtd_vectorization.read_embedding_config')
    def test_search_similar_success(self, mock_embedding_config, mock_db_config, mock_embedding, mock_db_class, mock_psycopg2_connect):
        """Test successful similarity search"""
        mock_embedding_config.return_value = {}
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
    
    @patch('gtd_vector_db.psycopg2.connect')  # Safety patch - prevent any real DB connections
    @patch('gtd_vectorization.VectorDatabase')
    @patch('gtd_vectorization.generate_embedding')
    @patch('gtd_vectorization.read_embedding_config')
    @patch('gtd_vectorization.read_database_config')
    def test_search_similar_no_embedding(self, mock_db_config, mock_embedding_config, mock_embedding, mock_db_class, mock_psycopg2_connect):
        """Test search when embedding generation fails"""
        # Mock config reads to prevent real file I/O
        mock_embedding_config.return_value = {}
        mock_db_config.return_value = {}
        # Mock embedding generation to return None (failure)
        mock_embedding.return_value = None
        # Mock database (shouldn't be created, but mock it just in case)
        mock_db_class.return_value = MagicMock()
        
        results = search_similar("test query")
        
        self.assertEqual(results, [])
        # Verify that generate_embedding was called (and failed)
        mock_embedding.assert_called_once()
        # Verify database was never created/connected (since embedding failed early)
        mock_db_class.assert_not_called()


if __name__ == '__main__':
    unittest.main()

