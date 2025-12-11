#!/usr/bin/env python3
"""
GTD Vector Database Helper - PostgreSQL with pgvector integration

Provides database connection and vector operations for the GTD system.
"""

import os
import sys
from pathlib import Path
from typing import Optional, Dict, Any, List, Tuple
import json

try:
    import psycopg2
    from psycopg2.extras import execute_values
    from psycopg2 import sql
    HAS_PSYCOPG2 = True
except ImportError:
    HAS_PSYCOPG2 = False
    # Only exit if running as main script, not when imported
    if __name__ == "__main__":
        print("Error: psycopg2 not installed. Install with: pip install psycopg2-binary", file=sys.stderr)
        sys.exit(1)

# Add parent directory to path for imports
# Handle both direct execution and import scenarios
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent.parent
sys.path.insert(0, str(dotfiles_dir))

try:
    from zsh.functions.gtd_persona_helper import read_config
except ImportError:
    # Fallback for direct execution - try relative import
    try:
        from gtd_persona_helper import read_config
    except ImportError:
        # If still fails, define a minimal read_config
        def read_config():
            return {}


def read_database_config() -> Dict[str, Any]:
    """
    Read database configuration from .gtd_config_database file.
    
    Returns:
        Dictionary with database configuration settings
    """
    config_paths = [
        # Home directory configs (base settings)
        Path.home() / ".gtd_config_database",
        # Dotfiles directory configs (override home)
        Path(__file__).parent.parent / ".gtd_config_database"
    ]
    
    config = {
        "host": "localhost",
        "port": 13003,
        "database": "vector",
        "user": "postgres",
        "password": "",
        "vectorization_enabled": True,
        "batch_size": 10,
        "dimension": 768,
        "rabbitmq_enabled": False,
        "rabbitmq_url": "amqp://localhost:5672",
        "rabbitmq_queue": "gtd_vectorization",
    }
    
    # Read from config files (later files override earlier ones)
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        # Remove comments
                        if '#' in value:
                            value = value.split('#')[0].strip()
                        # Remove quotes
                        value = value.strip('"').strip("'")
                        # Handle variable expansion syntax like ${VAR:-default}
                        if value.startswith("${") and ":-" in value:
                            value = value.split(":-", 1)[1].rstrip("}")
                        
                        # Map config keys
                        if key == "VECTOR_DB_HOST":
                            config["host"] = value
                        elif key == "VECTOR_DB_PORT":
                            try:
                                config["port"] = int(value)
                            except ValueError:
                                pass
                        elif key == "VECTOR_DB_NAME":
                            config["database"] = value
                        elif key == "VECTOR_DB_USER":
                            config["user"] = value
                        elif key == "VECTOR_DB_PASSWORD":
                            config["password"] = value
                        elif key == "GTD_VECTORIZATION_ENABLED":
                            config["vectorization_enabled"] = value.lower() in ("true", "1", "yes")
                        elif key == "VECTOR_BATCH_SIZE":
                            try:
                                config["batch_size"] = int(value)
                            except ValueError:
                                pass
                        elif key == "VECTOR_DIMENSION":
                            try:
                                config["dimension"] = int(value)
                            except ValueError:
                                pass
                        elif key == "RABBITMQ_ENABLED":
                            config["rabbitmq_enabled"] = value.lower() in ("true", "1", "yes")
                        elif key == "RABBITMQ_URL":
                            config["rabbitmq_url"] = value
                        elif key == "RABBITMQ_USER":
                            config["rabbitmq_user"] = value
                        elif key == "RABBITMQ_PASS":
                            config["rabbitmq_pass"] = value
                        elif key == "RABBITMQ_VECTOR_QUEUE":
                            config["rabbitmq_queue"] = value
    
    # Override with environment variables if set
    config["host"] = os.getenv("VECTOR_DB_HOST", config["host"])
    config["port"] = int(os.getenv("VECTOR_DB_PORT", str(config["port"])))
    config["database"] = os.getenv("VECTOR_DB_NAME", config["database"])
    config["user"] = os.getenv("VECTOR_DB_USER", config["user"])
    config["password"] = os.getenv("VECTOR_DB_PASSWORD", config["password"])
    
    # Build RabbitMQ URL with credentials if provided
    rabbitmq_url = os.getenv("RABBITMQ_URL", config.get("rabbitmq_url", "amqp://localhost:5672"))
    rabbitmq_user = os.getenv("RABBITMQ_USER", config.get("rabbitmq_user", ""))
    rabbitmq_pass = os.getenv("RABBITMQ_PASS", config.get("rabbitmq_pass", ""))
    
    # If URL doesn't have credentials and we have user/pass, add them
    if "//" in rabbitmq_url:
        url_parts = rabbitmq_url.split("//", 1)
        if len(url_parts) == 2 and "@" not in url_parts[1] and rabbitmq_user:
            host_part = url_parts[1]
            if rabbitmq_pass:
                rabbitmq_url = f"{url_parts[0]}//{rabbitmq_user}:{rabbitmq_pass}@{host_part}"
            else:
                rabbitmq_url = f"{url_parts[0]}//{rabbitmq_user}@{host_part}"
    
    config["rabbitmq_url"] = rabbitmq_url
    
    return config


class VectorDatabase:
    """
    PostgreSQL vector database connection and operations.
    """
    
    def __init__(self, config: Optional[Dict[str, Any]] = None):
        """
        Initialize database connection.
        
        Args:
            config: Database configuration dict. If None, reads from config files.
        """
        if config is None:
            config = read_database_config()
        
        self.config = config
        self.conn = None
        self._ensure_extension()
    
    def connect(self) -> bool:
        """
        Connect to the database.
        
        Returns:
            True if connection successful, False otherwise
        """
        if not HAS_PSYCOPG2:
            print("Error: psycopg2 not installed. Install with: pip install psycopg2-binary", file=sys.stderr)
            return False
        try:
            self.conn = psycopg2.connect(
                host=self.config["host"],
                port=self.config["port"],
                database=self.config["database"],
                user=self.config["user"],
                password=self.config["password"]
            )
            return True
        except Exception as e:
            print(f"Error connecting to database: {e}", file=sys.stderr)
            return False
    
    def disconnect(self):
        """Close database connection."""
        if self.conn:
            self.conn.close()
            self.conn = None
    
    def _ensure_extension(self):
        """Ensure pgvector extension is installed."""
        if not self.conn:
            if not self.connect():
                return
        
        try:
            with self.conn.cursor() as cur:
                cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
                self.conn.commit()
        except Exception as e:
            print(f"Warning: Could not ensure pgvector extension: {e}", file=sys.stderr)
    
    def initialize_schema(self):
        """
        Initialize database schema for vector storage.
        Creates tables for different content types.
        """
        if not self.conn:
            if not self.connect():
                raise Exception("Cannot connect to database")
        
        with self.conn.cursor() as cur:
            # Create vector embeddings table
            cur.execute("""
                CREATE TABLE IF NOT EXISTS vector_embeddings (
                    id SERIAL PRIMARY KEY,
                    content_type VARCHAR(50) NOT NULL,
                    content_id VARCHAR(255) NOT NULL,
                    content_text TEXT NOT NULL,
                    embedding vector(%s) NOT NULL,
                    metadata JSONB,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    UNIQUE(content_type, content_id)
                );
            """, (self.config["dimension"],))
            
            # Create index for vector similarity search
            cur.execute("""
                CREATE INDEX IF NOT EXISTS vector_embeddings_embedding_idx 
                ON vector_embeddings 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100);
            """)
            
            # Create index for content lookup
            cur.execute("""
                CREATE INDEX IF NOT EXISTS vector_embeddings_content_idx 
                ON vector_embeddings (content_type, content_id);
            """)
            
            # Create index for metadata search
            cur.execute("""
                CREATE INDEX IF NOT EXISTS vector_embeddings_metadata_idx 
                ON vector_embeddings USING gin (metadata);
            """)
            
            self.conn.commit()
    
    def store_embedding(
        self,
        content_type: str,
        content_id: str,
        content_text: str,
        embedding: List[float],
        metadata: Optional[Dict[str, Any]] = None
    ) -> bool:
        """
        Store an embedding in the database.
        
        Args:
            content_type: Type of content (e.g., 'daily_log', 'task', 'project')
            content_id: Unique identifier for the content
            content_text: Original text content
            embedding: Vector embedding (list of floats)
            metadata: Optional metadata dictionary
            
        Returns:
            True if successful, False otherwise
        """
        if not self.conn:
            if not self.connect():
                return False
        
        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    INSERT INTO vector_embeddings 
                    (content_type, content_id, content_text, embedding, metadata, updated_at)
                    VALUES (%s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                    ON CONFLICT (content_type, content_id)
                    DO UPDATE SET
                        content_text = EXCLUDED.content_text,
                        embedding = EXCLUDED.embedding,
                        metadata = EXCLUDED.metadata,
                        updated_at = CURRENT_TIMESTAMP;
                """, (
                    content_type,
                    content_id,
                    content_text,
                    str(embedding),  # psycopg2 will handle vector conversion
                    json.dumps(metadata) if metadata else None
                ))
                self.conn.commit()
                return True
        except Exception as e:
            print(f"Error storing embedding: {e}", file=sys.stderr)
            self.conn.rollback()
            return False
    
    def search_similar(
        self,
        query_embedding: List[float],
        content_type: Optional[str] = None,
        limit: int = 10,
        threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """
        Search for similar content using vector similarity.
        
        Args:
            query_embedding: Query vector embedding
            content_type: Optional filter by content type
            limit: Maximum number of results
            threshold: Minimum similarity threshold (0.0-1.0)
        
        Returns:
            List of similar content items with similarity scores
        """
        if not self.conn:
            if not self.connect():
                return []
        
        try:
            with self.conn.cursor() as cur:
                if content_type:
                    cur.execute("""
                        SELECT 
                            content_type,
                            content_id,
                            content_text,
                            metadata,
                            1 - (embedding <=> %s::vector) as similarity
                        FROM vector_embeddings
                        WHERE content_type = %s
                        ORDER BY embedding <=> %s::vector
                        LIMIT %s;
                    """, (str(query_embedding), content_type, str(query_embedding), limit))
                else:
                    cur.execute("""
                        SELECT 
                            content_type,
                            content_id,
                            content_text,
                            metadata,
                            1 - (embedding <=> %s::vector) as similarity
                        FROM vector_embeddings
                        ORDER BY embedding <=> %s::vector
                        LIMIT %s;
                    """, (str(query_embedding), str(query_embedding), limit))
                
                results = []
                for row in cur.fetchall():
                    similarity = float(row[4])
                    if similarity >= threshold:
                        results.append({
                            "content_type": row[0],
                            "content_id": row[1],
                            "content_text": row[2],
                            "metadata": json.loads(row[3]) if row[3] else {},
                            "similarity": similarity
                        })
                return results
        except Exception as e:
            print(f"Error searching embeddings: {e}", file=sys.stderr)
            return []
    
    def delete_embedding(self, content_type: str, content_id: str) -> bool:
        """
        Delete an embedding from the database.
        
        Args:
            content_type: Type of content
            content_id: Unique identifier for the content
        
        Returns:
            True if successful, False otherwise
        """
        if not self.conn:
            if not self.connect():
                return False
        
        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    DELETE FROM vector_embeddings
                    WHERE content_type = %s AND content_id = %s;
                """, (content_type, content_id))
                self.conn.commit()
                return cur.rowcount > 0
        except Exception as e:
            print(f"Error deleting embedding: {e}", file=sys.stderr)
            self.conn.rollback()
            return False
    
    def __enter__(self):
        """Context manager entry."""
        self.connect()
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.disconnect()


if __name__ == "__main__":
    # Test database connection
    db = VectorDatabase()
    if db.connect():
        print("✓ Database connection successful")
        db.initialize_schema()
        print("✓ Schema initialized")
        db.disconnect()
    else:
        print("✗ Database connection failed")
        sys.exit(1)

