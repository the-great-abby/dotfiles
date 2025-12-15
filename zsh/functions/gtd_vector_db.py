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
        "host": "127.0.0.1",  # Default to localhost (will be overridden by config)
        "port": 30003,  # NodePort (was 13003)
        "database": "vector",
        "user": "postgres",
        "password": "",
        "vectorization_enabled": True,
        "batch_size": 10,
        "dimension": 768,
        "rabbitmq_enabled": False,
        "rabbitmq_url": "amqp://192.168.64.2:30672",  # NodePort (was localhost:5672)
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
            error_msg = str(e)
            error_type = type(e).__name__
            print(f"Error connecting to database: {e}", file=sys.stderr)
            
            # Check for different types of connection errors and suggest fixes
            connection_error = False
            
            # Connection refused - check if using NodePort or port-forward
            if "Connection refused" in error_msg or "connection to server" in error_msg.lower():
                connection_error = True
                db_host = self.config["host"]
                db_port = self.config["port"]
                
                # Check if using NodePort (192.168.64.2)
                if db_host == "192.168.64.2" or "192.168.64" in db_host:
                    print(f"\n⚠️  Connection refused to NodePort {db_host}:{db_port}", file=sys.stderr)
                    print(f"💡 NodePort should be more reliable than port-forwarding, but it's not working.", file=sys.stderr)
                    print(f"", file=sys.stderr)
                    print(f"💡 Verify NodePort setup:", file=sys.stderr)
                    print(f"   ./bin/verify-nodeport  # Check NodePort configuration", file=sys.stderr)
                    print(f"   kubectl get svc -A -o wide | grep {db_port}  # Find service using this port", file=sys.stderr)
                    print(f"", file=sys.stderr)
                    print(f"💡 Check if database service is running:", file=sys.stderr)
                    print(f"   kubectl get pods -A | grep -i postgres", file=sys.stderr)
                    print(f"   kubectl get svc -A | grep -i postgres", file=sys.stderr)
                    print(f"", file=sys.stderr)
                    print(f"💡 If NodePort isn't configured, you can:", file=sys.stderr)
                    print(f"   1. Set up NodePort service (recommended):", file=sys.stderr)
                    print(f"      gtd-wizard → Configuration → External Services → Database", file=sys.stderr)
                    print(f"   2. Or fall back to port-forwarding (temporary):", file=sys.stderr)
                    print(f"      Change VECTOR_DB_HOST to 'localhost' and VECTOR_DB_PORT to '13003'", file=sys.stderr)
                    print(f"      Then run: setup-port-forward 13003", file=sys.stderr)
                elif db_port in (13003, 5432, 5433):
                    print(f"\n⚠️  Connection refused on port {db_port}. Port-forward may not be running.", file=sys.stderr)
                    print(f"💡 Set up port-forward:", file=sys.stderr)
                    print(f"   gtd-wizard → Configuration → External Services → Database", file=sys.stderr)
            
            # Timeout - service might be down or unreachable
            elif "timeout" in error_msg.lower() or "timed out" in error_msg.lower():
                connection_error = True
                print(f"\n⚠️  Connection timeout. Service may be down or unreachable.", file=sys.stderr)
                print(f"💡 Check if service is running: kubectl get pods -A | grep -i postgres", file=sys.stderr)
            
            # DNS resolution error - wrong hostname
            elif "could not translate host name" in error_msg.lower() or "Name or service not known" in error_msg.lower():
                connection_error = True
                print(f"\n⚠️  DNS resolution failed. Check hostname: {self.config['host']}", file=sys.stderr)
            
            # Authentication error - wrong credentials
            elif "authentication failed" in error_msg.lower() or "password authentication failed" in error_msg.lower():
                connection_error = True
                print(f"\n⚠️  Authentication failed. Check database credentials in .gtd_config_database", file=sys.stderr)
            
            # Database doesn't exist
            elif "database" in error_msg.lower() and ("does not exist" in error_msg.lower() or "not exist" in error_msg.lower()):
                connection_error = True
                print(f"\n⚠️  Database '{self.config['database']}' does not exist.", file=sys.stderr)
                print(f"💡 Create it or check database name in .gtd_config_database", file=sys.stderr)
            
            # Only attempt port-forward for connection refused errors
            if connection_error and ("Connection refused" in error_msg or "connection to server" in error_msg.lower()):
                # Attempt to set up port forwarding for PostgreSQL (port 13003 or 5432)
                db_port = self.config["port"]
                if db_port in (13003, 5432, 5433):
                    print(f"\n⚠️  Connection refused on port {db_port}. Attempting to set up port forwarding...", file=sys.stderr)
                    
                    # Try to call setup-port-forward script
                    script_paths = [
                        Path(__file__).parent.parent.parent / "bin" / "setup-port-forward",
                        Path.home() / "code" / "dotfiles" / "bin" / "setup-port-forward",
                        Path.home() / "code" / "personal" / "dotfiles" / "bin" / "setup-port-forward",
                    ]
                    
                    setup_script = None
                    for path in script_paths:
                        if path.exists() and path.is_file():
                            setup_script = path
                            break
                    
                    if setup_script:
                        import subprocess
                        try:
                            # Run port-forward setup script
                            result = subprocess.run(
                                [str(setup_script), str(db_port)],
                                capture_output=True,
                                text=True,
                                timeout=15
                            )
                            
                            # Print stderr output for debugging (it contains useful diagnostics)
                            if result.stderr:
                                print(result.stderr, file=sys.stderr, end='')
                            
                            if result.returncode == 0:
                                print("✓ Port forwarding set up. Retrying connection...", file=sys.stderr)
                                # Wait a moment for port-forward to establish
                                import time
                                time.sleep(3)
                                # Retry connection
                                try:
                                    self.conn = psycopg2.connect(
                                        host=self.config["host"],
                                        port=self.config["port"],
                                        database=self.config["database"],
                                        user=self.config["user"],
                                        password=self.config["password"]
                                    )
                                    print("✓ Connection successful after port-forward setup!", file=sys.stderr)
                                    return True
                                except Exception as retry_e:
                                    print(f"⚠️  Connection still failed after port-forward setup: {retry_e}", file=sys.stderr)
                                    # Try to deploy the service
                                    print("💡 Attempting to deploy PostgreSQL service...", file=sys.stderr)
                                    try:
                                        deploy_result = subprocess.run(
                                            ["make", "-C", str(Path.home() / "code" / "dotfiles"), "services-deploy-database"],
                                            capture_output=True,
                                            text=True,
                                            timeout=60
                                        )
                                        if deploy_result.returncode == 0:
                                            print("✓ Service deployment initiated. Waiting for service to be ready...", file=sys.stderr)
                                            time.sleep(5)
                                            # Retry connection one more time
                                            try:
                                                self.conn = psycopg2.connect(
                                                    host=self.config["host"],
                                                    port=self.config["port"],
                                                    database=self.config["database"],
                                                    user=self.config["user"],
                                                    password=self.config["password"]
                                                )
                                                print("✓ Connection successful after service deployment!", file=sys.stderr)
                                                return True
                                            except Exception:
                                                print(f"⚠️  Service deployed but still connecting. Wait a moment and try again.", file=sys.stderr)
                                        else:
                                            print(f"⚠️  Service deployment failed: {deploy_result.stderr}", file=sys.stderr)
                                    except (subprocess.TimeoutExpired, FileNotFoundError):
                                        print(f"💡 Check if service is running: kubectl get pods -A | grep -i postgres", file=sys.stderr)
                                        print(f"💡 Or deploy manually: cd ~/code/dotfiles && make services-deploy-database", file=sys.stderr)
                            else:
                                error_output = result.stderr or result.stdout or "Unknown error"
                                if error_output.strip():
                                    print(f"⚠️  Port-forward setup failed: {error_output}", file=sys.stderr)
                                else:
                                    print(f"⚠️  Port-forward setup failed with exit code {result.returncode}", file=sys.stderr)
                        except subprocess.TimeoutExpired:
                            print(f"⚠️  Port-forward setup timed out after 15 seconds", file=sys.stderr)
                        except FileNotFoundError:
                            print(f"⚠️  Port-forward setup script not found at: {setup_script}", file=sys.stderr)
                        except Exception as setup_e:
                            print(f"⚠️  Could not run port-forward setup: {setup_e}", file=sys.stderr)
                    else:
                        print(f"⚠️  Port-forward setup script not found. You may need to run:", file=sys.stderr)
                        print(f"   setup-port-forward {db_port}", file=sys.stderr)
            
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
            # Check if pgvector extension exists
            cur.execute("""
                SELECT EXISTS(
                    SELECT 1 FROM pg_extension WHERE extname = 'vector'
                );
            """)
            extension_exists = cur.fetchone()[0]
            
            if not extension_exists:
                error_msg = """
❌ pgvector extension is not installed in this database.

The extension must be created by a PostgreSQL superuser (typically 'postgres').

To fix this, run:
   gtd-create-pgvector-extension

Or manually connect as postgres superuser:
   psql -h %s -p %s -U postgres -d %s
   Then run: CREATE EXTENSION IF NOT EXISTS vector;
""" % (self.config.get("host", "localhost"), 
       self.config.get("port", "5432"),
       self.config.get("database", "postgres"))
                raise Exception(error_msg)
            
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
            
            # Create document_vectors table for smart semantic chunking
            cur.execute("""
                CREATE TABLE IF NOT EXISTS document_vectors (
                    id SERIAL PRIMARY KEY,
                    file_path TEXT NOT NULL,
                    chunk_index INT NOT NULL,
                    
                    -- Content
                    content TEXT NOT NULL,  -- Original chunk
                    content_with_context TEXT,  -- With heading path prepended
                    
                    -- Vector
                    embedding vector(%s),
                    
                    -- Structure metadata
                    heading_path TEXT,  -- "Main Topic > Subtopic"
                    section_chunk_index INT,  -- Which chunk within this section
                    
                    -- Organizational metadata (from your system)
                    project TEXT,
                    category TEXT,
                    tags TEXT[],
                    
                    -- File metadata
                    file_type TEXT,  -- 'markdown' or 'text'
                    last_modified TIMESTAMP,
                    
                    -- Content characteristics
                    has_code_block BOOLEAN,
                    has_list BOOLEAN,
                    has_links BOOLEAN,
                    
                    -- Additional metadata (flexible)
                    metadata JSONB,
                    
                    created_at TIMESTAMP DEFAULT NOW(),
                    updated_at TIMESTAMP DEFAULT NOW(),
                    
                    UNIQUE(file_path, chunk_index)
                );
            """, (self.config["dimension"],))
            
            # Create indexes for document_vectors
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_embedding 
                ON document_vectors 
                USING ivfflat (embedding vector_cosine_ops)
                WITH (lists = 100);
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_file_path 
                ON document_vectors(file_path);
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_project 
                ON document_vectors(project);
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_tags 
                ON document_vectors USING gin(tags);
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_heading_path 
                ON document_vectors 
                USING gin(to_tsvector('english', heading_path));
            """)
            
            cur.execute("""
                CREATE INDEX IF NOT EXISTS idx_vectors_metadata 
                ON document_vectors USING gin(metadata);
            """)
            
            self.conn.commit()
    
    def store_document_chunks(
        self,
        chunks: List[Dict[str, Any]],
        file_path: str,
        file_type: str = "markdown",
        project: Optional[str] = None,
        category: Optional[str] = None,
        tags: Optional[List[str]] = None,
        last_modified: Optional[str] = None
    ) -> bool:
        """
        Store multiple document chunks with rich metadata.
        
        Args:
            chunks: List of chunk dictionaries with keys:
                - content: Original chunk text
                - content_with_context: Chunk with context prepended
                - heading_path: Heading path (e.g., "Main > Sub")
                - chunk_index: Global chunk index
                - section_chunk_index: Index within section
                - metadata: Additional metadata dict
            file_path: Path to the source file
            file_type: Type of file ('markdown' or 'text')
            project: Project name (optional)
            category: Category (optional)
            tags: List of tags (optional)
            last_modified: Last modified timestamp (optional)
        
        Returns:
            True if successful, False otherwise
        """
        if not self.conn:
            if not self.connect():
                return False
        
        try:
            with self.conn.cursor() as cur:
                # Delete existing chunks for this file (for re-vectorization)
                cur.execute("""
                    DELETE FROM document_vectors
                    WHERE file_path = %s;
                """, (file_path,))
                
                # Insert all chunks
                for chunk in chunks:
                    chunk_metadata = chunk.get('metadata', {})
                    has_code_block = chunk_metadata.get('has_code_block', False)
                    has_list = chunk_metadata.get('has_list', False)
                    has_links = chunk_metadata.get('has_links', False)
                    
                    # Merge chunk metadata with additional metadata
                    combined_metadata = chunk_metadata.copy()
                    if 'metadata' in chunk:
                        combined_metadata.update(chunk.get('metadata', {}))
                    
                    cur.execute("""
                        INSERT INTO document_vectors 
                        (file_path, chunk_index, content, content_with_context,
                         heading_path, section_chunk_index, project, category, tags,
                         file_type, last_modified, has_code_block, has_list, has_links,
                         metadata, updated_at)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, CURRENT_TIMESTAMP)
                    """, (
                        file_path,
                        chunk['chunk_index'],
                        chunk['content'],
                        chunk.get('content_with_context', chunk['content']),
                        chunk.get('heading_path', ''),
                        chunk.get('section_chunk_index', 0),
                        project,
                        category,
                        tags,
                        file_type,
                        last_modified,
                        has_code_block,
                        has_list,
                        has_links,
                        json.dumps(combined_metadata) if combined_metadata else None
                    ))
                
                self.conn.commit()
                return True
        except Exception as e:
            print(f"Error storing document chunks: {e}", file=sys.stderr)
            self.conn.rollback()
            return False
    
    def store_document_chunk_embedding(
        self,
        file_path: str,
        chunk_index: int,
        embedding: List[float]
    ) -> bool:
        """
        Store embedding for a specific document chunk.
        
        Args:
            file_path: Path to the source file
            chunk_index: Chunk index
            embedding: Vector embedding
        
        Returns:
            True if successful, False otherwise
        """
        if not self.conn:
            if not self.connect():
                return False
        
        try:
            with self.conn.cursor() as cur:
                cur.execute("""
                    UPDATE document_vectors
                    SET embedding = %s::vector, updated_at = CURRENT_TIMESTAMP
                    WHERE file_path = %s AND chunk_index = %s;
                """, (str(embedding), file_path, chunk_index))
                self.conn.commit()
                return cur.rowcount > 0
        except Exception as e:
            print(f"Error storing chunk embedding: {e}", file=sys.stderr)
            self.conn.rollback()
            return False
    
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
    
    def search_document_vectors(
        self,
        query_embedding: List[float],
        file_path: Optional[str] = None,
        project: Optional[str] = None,
        heading_path_query: Optional[str] = None,
        limit: int = 10,
        threshold: float = 0.7
    ) -> List[Dict[str, Any]]:
        """
        Search document_vectors with rich metadata filtering.
        
        Args:
            query_embedding: Query vector embedding
            file_path: Optional filter by file path
            project: Optional filter by project
            heading_path_query: Optional full-text search on heading_path
            limit: Maximum number of results
            threshold: Minimum similarity threshold (0.0-1.0)
        
        Returns:
            List of matching chunks with metadata
        """
        if not self.conn:
            if not self.connect():
                return []
        
        try:
            with self.conn.cursor() as cur:
                # Build WHERE clause
                conditions = []
                params = [str(query_embedding)]
                
                if file_path:
                    conditions.append("file_path = %s")
                    params.append(file_path)
                
                if project:
                    conditions.append("project = %s")
                    params.append(project)
                
                if heading_path_query:
                    conditions.append("to_tsvector('english', heading_path) @@ to_tsquery(%s)")
                    params.append(heading_path_query)
                
                where_clause = " AND ".join(conditions) if conditions else "1=1"
                
                query = f"""
                    SELECT 
                        file_path,
                        chunk_index,
                        content,
                        content_with_context,
                        heading_path,
                        project,
                        category,
                        tags,
                        metadata,
                        1 - (embedding <=> %s::vector) as similarity
                    FROM document_vectors
                    WHERE embedding IS NOT NULL AND {where_clause}
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s;
                """
                params.append(str(query_embedding))  # For ORDER BY
                params.append(limit)
                
                cur.execute(query, params)
                
                results = []
                for row in cur.fetchall():
                    similarity = float(row[9])
                    if similarity >= threshold:
                        # Handle metadata - may already be a dict if psycopg2 parsed it
                        metadata = row[8]
                        if metadata:
                            if isinstance(metadata, dict):
                                # Already parsed
                                pass
                            elif isinstance(metadata, str):
                                # Need to parse JSON string
                                try:
                                    metadata = json.loads(metadata)
                                except (json.JSONDecodeError, TypeError):
                                    metadata = {}
                            else:
                                metadata = {}
                        else:
                            metadata = {}
                        
                        results.append({
                            "file_path": row[0],
                            "chunk_index": row[1],
                            "content": row[2],
                            "content_with_context": row[3],
                            "heading_path": row[4],
                            "project": row[5],
                            "category": row[6],
                            "tags": row[7] if row[7] else [],
                            "metadata": metadata,
                            "similarity": similarity
                        })
                return results
        except Exception as e:
            print(f"Error searching document vectors: {e}", file=sys.stderr)
            return []
    
    def search_similar(
        self,
        query_embedding: List[float],
        content_type: Optional[str] = None,
        limit: int = 10,
        threshold: float = 0.7,
        exclude_content_types: Optional[List[str]] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for similar content using vector similarity.
        
        Args:
            query_embedding: Query vector embedding
            content_type: Optional filter by content type
            limit: Maximum number of results
            threshold: Minimum similarity threshold (0.0-1.0)
            exclude_content_types: Optional list of content types to exclude
        
        Returns:
            List of similar content items with similarity scores
        """
        if not self.conn:
            if not self.connect():
                return []
        
        try:
            with self.conn.cursor() as cur:
                # Build WHERE clause
                conditions = []
                params = [str(query_embedding)]
                
                if content_type:
                    conditions.append("content_type = %s")
                    params.append(content_type)
                
                if exclude_content_types:
                    placeholders = ','.join(['%s'] * len(exclude_content_types))
                    conditions.append(f"content_type NOT IN ({placeholders})")
                    params.extend(exclude_content_types)
                
                where_clause = " AND ".join(conditions) if conditions else "1=1"
                
                query = f"""
                    SELECT 
                        content_type,
                        content_id,
                        content_text,
                        metadata,
                        1 - (embedding <=> %s::vector) as similarity
                    FROM vector_embeddings
                    WHERE {where_clause}
                    ORDER BY embedding <=> %s::vector
                    LIMIT %s;
                """
                params.append(str(query_embedding))  # For ORDER BY
                params.append(limit)
                
                cur.execute(query, params)
                
                results = []
                for row in cur.fetchall():
                    similarity = float(row[4])
                    if similarity >= threshold:
                        # Handle metadata - may already be a dict if psycopg2 parsed it
                        metadata = row[3]
                        if metadata:
                            if isinstance(metadata, dict):
                                # Already parsed
                                pass
                            elif isinstance(metadata, str):
                                # Need to parse JSON string
                                try:
                                    metadata = json.loads(metadata)
                                except (json.JSONDecodeError, TypeError):
                                    metadata = {}
                            else:
                                metadata = {}
                        else:
                            metadata = {}
                        
                        # Filter out advice results by checking file_path in metadata
                        # Skip results from advice_results directory
                        file_path = metadata.get('file_path', '') if isinstance(metadata, dict) else ''
                        if 'advice_results' in file_path:
                            continue  # Skip advice results
                        
                        results.append({
                            "content_type": row[0],
                            "content_id": row[1],
                            "content_text": row[2],
                            "metadata": metadata,
                            "similarity": similarity
                        })
                return results
        except Exception as e:
            print(f"Error searching embeddings: {e}", file=sys.stderr)
            return []
    
    def count_embeddings(self, content_type: Optional[str] = None) -> int:
        """
        Count embeddings in the database.
        
        Args:
            content_type: Optional filter by content type
        
        Returns:
            Number of embeddings
        """
        if not self.conn:
            if not self.connect():
                return 0
        
        try:
            with self.conn.cursor() as cur:
                if content_type:
                    cur.execute("""
                        SELECT COUNT(*) FROM vector_embeddings
                        WHERE content_type = %s;
                    """, (content_type,))
                else:
                    cur.execute("SELECT COUNT(*) FROM vector_embeddings;")
                return cur.fetchone()[0]
        except Exception as e:
            print(f"Error counting embeddings: {e}", file=sys.stderr)
            return 0
    
    def list_embeddings(
        self,
        content_type: Optional[str] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        """
        List embeddings in the database.
        
        Args:
            content_type: Optional filter by content type
            limit: Maximum number of results
            offset: Offset for pagination
        
        Returns:
            List of embeddings with metadata
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
                            LEFT(content_text, 200) as content_preview,
                            metadata,
                            created_at,
                            updated_at
                        FROM vector_embeddings
                        WHERE content_type = %s
                        ORDER BY created_at DESC
                        LIMIT %s OFFSET %s;
                    """, (content_type, limit, offset))
                else:
                    cur.execute("""
                        SELECT 
                            content_type,
                            content_id,
                            LEFT(content_text, 200) as content_preview,
                            metadata,
                            created_at,
                            updated_at
                        FROM vector_embeddings
                        ORDER BY created_at DESC
                        LIMIT %s OFFSET %s;
                    """, (limit, offset))
                
                results = []
                for row in cur.fetchall():
                    # Handle metadata - may already be a dict if psycopg2 parsed it
                    metadata = row[3]
                    if metadata:
                        if isinstance(metadata, dict):
                            # Already parsed
                            pass
                        elif isinstance(metadata, str):
                            # Need to parse JSON string
                            try:
                                metadata = json.loads(metadata)
                            except (json.JSONDecodeError, TypeError):
                                metadata = {}
                        else:
                            metadata = {}
                    else:
                        metadata = {}
                    
                    results.append({
                        "content_type": row[0],
                        "content_id": row[1],
                        "content_preview": row[2],
                        "metadata": metadata,
                        "created_at": row[4].isoformat() if row[4] else None,
                        "updated_at": row[5].isoformat() if row[5] else None
                    })
                return results
        except Exception as e:
            print(f"Error listing embeddings: {e}", file=sys.stderr)
            return []
    
    def get_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about the vector database.
        
        Returns:
            Dictionary with statistics
        """
        if not self.conn:
            if not self.connect():
                return {}
        
        try:
            with self.conn.cursor() as cur:
                # Total count
                cur.execute("SELECT COUNT(*) FROM vector_embeddings;")
                total_count = cur.fetchone()[0]
                
                # Count by content type
                cur.execute("""
                    SELECT content_type, COUNT(*) as count
                    FROM vector_embeddings
                    GROUP BY content_type
                    ORDER BY count DESC;
                """)
                by_type = {row[0]: row[1] for row in cur.fetchall()}
                
                # Most recent
                cur.execute("""
                    SELECT MAX(created_at), MAX(updated_at)
                    FROM vector_embeddings;
                """)
                latest = cur.fetchone()
                
                # Oldest
                cur.execute("""
                    SELECT MIN(created_at)
                    FROM vector_embeddings;
                """)
                oldest = cur.fetchone()
                
                return {
                    "total_embeddings": total_count,
                    "by_content_type": by_type,
                    "latest_created": latest[0].isoformat() if latest[0] else None,
                    "latest_updated": latest[1].isoformat() if latest[1] else None,
                    "oldest_created": oldest[0].isoformat() if oldest[0] else None
                }
        except Exception as e:
            print(f"Error getting statistics: {e}", file=sys.stderr)
            return {}
    
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
    
    def get_system_stats(self) -> Dict[str, Any]:
        """
        Get current state of the organizational system from document_vectors table.
        
        Returns:
            Dictionary with system statistics
        """
        if not self.conn:
            if not self.connect():
                return {}
        
        try:
            with self.conn.cursor() as cur:
                # Get overall stats
                cur.execute("""
                    SELECT 
                        COUNT(DISTINCT file_path) as total_files,
                        COUNT(*) as total_chunks,
                        COUNT(DISTINCT project) FILTER (WHERE project IS NOT NULL) as total_projects,
                        MAX(updated_at) as last_vectorization,
                        pg_size_pretty(pg_total_relation_size('document_vectors')) as storage_size
                    FROM document_vectors
                """)
                stats_row = cur.fetchone()
                
                if not stats_row:
                    return {
                        'total_files': 0,
                        'total_chunks': 0,
                        'total_projects': 0,
                        'last_vectorization': None,
                        'storage_size': '0 bytes',
                        'projects': [],
                        'needs_index': False
                    }
                
                # Get project breakdown
                cur.execute("""
                    SELECT 
                        project,
                        COUNT(DISTINCT file_path) as files,
                        COUNT(*) as chunks
                    FROM document_vectors
                    WHERE project IS NOT NULL
                    GROUP BY project
                    ORDER BY files DESC
                """)
                project_rows = cur.fetchall()
                
                projects = []
                for row in project_rows:
                    projects.append({
                        'project': row[0],
                        'files': row[1],
                        'chunks': row[2]
                    })
                
                return {
                    'total_files': stats_row[0] or 0,
                    'total_chunks': stats_row[1] or 0,
                    'total_projects': stats_row[2] or 0,
                    'last_vectorization': stats_row[3].isoformat() if stats_row[3] else None,
                    'storage_size': stats_row[4] or '0 bytes',
                    'projects': projects,
                    'needs_index': (stats_row[1] or 0) > 10000  # Flag when to add index
                }
        except Exception as e:
            print(f"Error getting system stats: {e}", file=sys.stderr)
            return {}
    
    def get_file_info(self, file_path: str) -> Optional[Dict[str, Any]]:
        """
        Get detailed info about a specific file.
        
        Args:
            file_path: Path to the file
        
        Returns:
            Dictionary with file information or None if not found
        """
        if not self.conn:
            if not self.connect():
                return None
        
        try:
            with self.conn.cursor() as cur:
                # Get basic file info
                cur.execute("""
                    SELECT 
                        file_path,
                        COUNT(*) as num_chunks,
                        MAX(heading_path) FILTER (WHERE heading_path != '' AND heading_path IS NOT NULL) as deepest_heading,
                        MAX(updated_at) as last_updated
                    FROM document_vectors
                    WHERE file_path = %s
                    GROUP BY file_path
                """, (file_path,))
                
                row = cur.fetchone()
                
                if not row:
                    return None
                
                # Get tags separately (unnest tags array)
                cur.execute("""
                    SELECT DISTINCT unnest(tags) as tag
                    FROM document_vectors
                    WHERE file_path = %s AND tags IS NOT NULL AND array_length(tags, 1) > 0
                """, (file_path,))
                
                tag_rows = cur.fetchall()
                all_tags = [tag[0] for tag in tag_rows] if tag_rows else []
                
                return {
                    'file_path': row[0],
                    'num_chunks': row[1],
                    'deepest_heading': row[2] or '',
                    'all_tags': all_tags,
                    'last_updated': row[3].isoformat() if row[3] else None
                }
        except Exception as e:
            print(f"Error getting file info: {e}", file=sys.stderr)
            return None
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.disconnect()


if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Vector Database Management")
    parser.add_argument("action", choices=["test", "init", "stats", "list", "count", "system-stats", "file-info"], 
                       help="Action to perform")
    parser.add_argument("--content-type", help="Filter by content type")
    parser.add_argument("--limit", type=int, default=100, help="Limit for list (default: 100)")
    parser.add_argument("--offset", type=int, default=0, help="Offset for list (default: 0)")
    parser.add_argument("file_path", nargs="?", help="File path for file-info action")
    
    args = parser.parse_args()
    
    db = VectorDatabase()
    
    if args.action == "test":
        if db.connect():
            print("✓ Database connection successful")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "init":
        if db.connect():
            db.initialize_schema()
            print("✓ Schema initialized")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "stats":
        if db.connect():
            stats = db.get_statistics()
            print("📊 Vector Database Statistics")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"\nTotal embeddings: {stats.get('total_embeddings', 0)}")
            if stats.get('by_content_type'):
                print("\nBy content type:")
                for content_type, count in stats['by_content_type'].items():
                    print(f"  • {content_type}: {count}")
            if stats.get('latest_created'):
                print(f"\nLatest created: {stats['latest_created']}")
            if stats.get('latest_updated'):
                print(f"Latest updated: {stats['latest_updated']}")
            if stats.get('oldest_created'):
                print(f"Oldest created: {stats['oldest_created']}")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "count":
        if db.connect():
            count = db.count_embeddings(args.content_type)
            if args.content_type:
                print(f"Embeddings of type '{args.content_type}': {count}")
            else:
                print(f"Total embeddings: {count}")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "list":
        if db.connect():
            embeddings = db.list_embeddings(args.content_type, args.limit, args.offset)
            if embeddings:
                print(f"📋 Vector Database Entries (showing {len(embeddings)})")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                for i, emb in enumerate(embeddings, 1):
                    print(f"\n[{i}] {emb['content_type']} / {emb['content_id']}")
                    if emb['content_preview']:
                        preview = emb['content_preview'].replace('\n', ' ')
                        if len(preview) > 150:
                            preview = preview[:150] + "..."
                        print(f"    Preview: {preview}")
                    if emb['metadata']:
                        print(f"    Metadata: {emb['metadata']}")
                    if emb['created_at']:
                        print(f"    Created: {emb['created_at']}")
            else:
                if args.content_type:
                    print(f"No embeddings found for type '{args.content_type}'")
                else:
                    print("No embeddings found in database")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "system-stats":
        if db.connect():
            stats = db.get_system_stats()
            print("📊 System Statistics (document_vectors)")
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            print(f"\nTotal files: {stats.get('total_files', 0)}")
            print(f"Total chunks: {stats.get('total_chunks', 0)}")
            print(f"Total projects: {stats.get('total_projects', 0)}")
            if stats.get('last_vectorization'):
                print(f"Last vectorization: {stats['last_vectorization']}")
            print(f"Storage size: {stats.get('storage_size', '0 bytes')}")
            
            if stats.get('projects'):
                print("\nProject Breakdown:")
                for project in stats['projects']:
                    print(f"  • {project['project']}: {project['files']} files, {project['chunks']} chunks")
            
            if stats.get('needs_index'):
                print("\n⚠️  Note: Consider adding additional indexes (chunks > 10,000)")
            
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif args.action == "file-info":
        if not args.file_path:
            print("Error: file_path required for file-info action")
            print("Usage: gtd_vector_db.py file-info <file_path>")
            sys.exit(1)
        
        if db.connect():
            file_info = db.get_file_info(args.file_path)
            if file_info:
                print(f"📄 File Information: {file_info['file_path']}")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print(f"\nNumber of chunks: {file_info['num_chunks']}")
                if file_info.get('deepest_heading'):
                    print(f"Deepest heading: {file_info['deepest_heading']}")
                if file_info.get('all_tags'):
                    print(f"Tags: {', '.join(file_info['all_tags'])}")
                else:
                    print("Tags: (none)")
                if file_info.get('last_updated'):
                    print(f"Last updated: {file_info['last_updated']}")
            else:
                print(f"✗ File not found in database: {args.file_path}")
                sys.exit(1)
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)

