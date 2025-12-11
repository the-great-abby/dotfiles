#!/usr/bin/env python3
"""
GTD Vectorization Module - Generate embeddings and store in vector database

Processes GTD content (daily logs, tasks, projects, etc.) and creates vector embeddings
for semantic search and similarity matching.
"""

import json
import sys
import os
import urllib.request
import urllib.error
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
import re

# Add parent directory to path for imports
# Handle both direct execution and import scenarios
script_dir = Path(__file__).parent
dotfiles_dir = script_dir.parent.parent
sys.path.insert(0, str(dotfiles_dir))

try:
    from zsh.functions.gtd_persona_helper import read_config
    from zsh.functions.gtd_vector_db import VectorDatabase, read_database_config
except ImportError:
    # Fallback for direct execution
    sys.path.insert(0, str(script_dir))
    from gtd_persona_helper import read_config
    from gtd_vector_db import VectorDatabase, read_database_config


def read_embedding_config() -> Dict[str, Any]:
    """
    Read embedding model configuration from config files.
    
    Returns:
        Dictionary with embedding configuration
    """
    config_paths = [
        Path.home() / ".daily_log_config",
        Path.home() / ".gtd_config",
        Path.home() / ".gtd_config_ai",
        Path(__file__).parent.parent / ".daily_log_config",
        Path(__file__).parent.parent / ".gtd_config",
        Path(__file__).parent.parent / ".gtd_config_ai"
    ]
    
    embedding_model = ""
    base_url = "http://localhost:1234/v1"
    timeout = 60
    
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip()
                        if '#' in value:
                            value = value.split('#')[0].strip()
                        value = value.strip('"').strip("'")
                        if value.startswith("${") and ":-" in value:
                            value = value.split(":-", 1)[1].rstrip("}")
                        
                        if key == "LM_STUDIO_EMBEDDING_MODEL" and not embedding_model:
                            embedding_model = value
                        elif key == "LM_STUDIO_URL" and "/v1" in value:
                            base_url = value.replace("/v1/chat/completions", "/v1")
                        elif key == "LM_STUDIO_TIMEOUT" or key == "TIMEOUT":
                            try:
                                timeout = int(value)
                            except ValueError:
                                pass
    
    # Override with environment variables
    embedding_model = os.getenv("LM_STUDIO_EMBEDDING_MODEL", embedding_model)
    
    return {
        "embedding_model": embedding_model,
        "base_url": base_url,
        "timeout": timeout
    }


def generate_embedding(text: str, config: Optional[Dict[str, Any]] = None) -> Optional[List[float]]:
    """
    Generate embedding vector for text using configured embedding model.
    
    Args:
        text: Text to embed
        config: Configuration dict. If None, reads from config files.
    
    Returns:
        List of floats representing the embedding, or None if failed
    """
    if config is None:
        embedding_config = read_embedding_config()
    else:
        embedding_config = config
    
    # Get embedding model
    embedding_model = embedding_config.get("embedding_model", "")
    if not embedding_model:
        embedding_model = os.getenv("LM_STUDIO_EMBEDDING_MODEL", "")
        if not embedding_model:
            print("Error: No embedding model configured. Set LM_STUDIO_EMBEDDING_MODEL in .gtd_config_ai", file=sys.stderr)
            return None
    
    # Get API URL
    base_url = embedding_config.get("base_url", "http://localhost:1234/v1")
    embedding_url = f"{base_url}/embeddings"
    timeout = embedding_config.get("timeout", 60)
    
    # Get API URL (use chat completions URL, embeddings use same endpoint pattern)
    base_url = config.get("url", "http://localhost:1234/v1")
    if "/v1/chat/completions" in base_url:
        base_url = base_url.replace("/v1/chat/completions", "/v1")
    
    embedding_url = f"{base_url}/embeddings"
    
    # Prepare request
    payload = {
        "model": embedding_model,
        "input": text
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        embedding_url,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            response_data = response.read()
            result = json.loads(response_data.decode('utf-8'))
            
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                print(f"Error generating embedding: {error_msg}", file=sys.stderr)
                return None
            
            if 'data' in result and len(result['data']) > 0:
                embedding = result['data'][0].get('embedding', [])
                return embedding
            else:
                print("Error: No embedding data in response", file=sys.stderr)
                return None
    except urllib.error.URLError as e:
        print(f"Error connecting to embedding API: {e}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error generating embedding: {e}", file=sys.stderr)
        return None


def chunk_text(text: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
    """
    Split text into chunks for processing.
    
    Args:
        text: Text to chunk
        chunk_size: Maximum characters per chunk
        overlap: Characters to overlap between chunks
    
    Returns:
        List of text chunks
    """
    if len(text) <= chunk_size:
        return [text]
    
    chunks = []
    start = 0
    
    while start < len(text):
        end = start + chunk_size
        
        # Try to break at sentence boundary
        if end < len(text):
            # Look for sentence endings
            sentence_end = max(
                text.rfind('.', start, end),
                text.rfind('!', start, end),
                text.rfind('?', start, end),
                text.rfind('\n', start, end)
            )
            if sentence_end > start:
                end = sentence_end + 1
        
        chunk = text[start:end].strip()
        if chunk:
            chunks.append(chunk)
        
        # Move start position with overlap
        start = end - overlap
        if start >= len(text):
            break
    
    return chunks


def queue_vectorization(
    content_type: str,
    content_id: str,
    content_text: str,
    metadata: Optional[Dict[str, Any]] = None,
    db_config: Optional[Dict[str, Any]] = None
) -> str:
    """
    Queue content for async vectorization via RabbitMQ.
    
    Args:
        content_type: Type of content (e.g., 'daily_log', 'task', 'project')
        content_id: Unique identifier for the content
        content_text: Text content to vectorize
        metadata: Optional metadata dictionary
        db_config: Database configuration. If None, reads from config.
    
    Returns:
        Status string: "queued_to_rabbitmq", "queued_to_file", or "queue_failed"
    """
    if db_config is None:
        db_config = read_database_config()
    
    if not db_config.get("vectorization_enabled", True):
        return "vectorization_disabled"
    
    from datetime import datetime
    
    message = {
        "content_type": content_type,
        "content_id": content_id,
        "content_text": content_text,
        "metadata": metadata or {},
        "timestamp": datetime.now().isoformat(),
    }
    
    # Get RabbitMQ config
    rabbitmq_url = db_config.get("rabbitmq_url", "amqp://localhost:5672")
    rabbitmq_queue = db_config.get("rabbitmq_queue", "gtd_vectorization")
    rabbitmq_enabled = db_config.get("rabbitmq_enabled", False)
    
    # Try RabbitMQ first if enabled
    if rabbitmq_enabled:
        try:
            import pika
            try:
                connection = pika.BlockingConnection(
                    pika.URLParameters(rabbitmq_url),
                    blocked_connection_timeout=2  # 2 second timeout
                )
                channel = connection.channel()
                channel.queue_declare(queue=rabbitmq_queue, durable=True)
                
                channel.basic_publish(
                    exchange='',
                    routing_key=rabbitmq_queue,
                    body=json.dumps(message),
                    properties=pika.BasicProperties(
                        delivery_mode=2,  # Make message persistent
                    )
                )
                connection.close()
                return "queued_to_rabbitmq"
            except (pika.exceptions.AMQPConnectionError,
                    pika.exceptions.AMQPChannelError,
                    ConnectionRefusedError,
                    TimeoutError,
                    OSError):
                # RabbitMQ not available, fall back to file queue
                pass
            except Exception:
                # Other RabbitMQ errors, fall back to file queue
                pass
        except ImportError:
            # pika not installed, use file queue
            pass
    
    # Fallback to file queue
    try:
        queue_file = Path.home() / "Documents" / "gtd" / "vectorization_queue.jsonl"
        queue_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(queue_file, 'a') as f:
            f.write(json.dumps(message) + '\n')
        return "queued_to_file"
    except Exception as e:
        return f"queue_failed: {e}"


def vectorize_content(
    content_type: str,
    content_id: str,
    content_text: str,
    metadata: Optional[Dict[str, Any]] = None,
    chunk: bool = True,
    db_config: Optional[Dict[str, Any]] = None,
    async_mode: Optional[bool] = None
) -> bool:
    """
    Vectorize a single piece of content and store in database.
    
    Args:
        content_type: Type of content (e.g., 'daily_log', 'task', 'project')
        content_id: Unique identifier for the content
        content_text: Text content to vectorize
        metadata: Optional metadata dictionary
        chunk: Whether to chunk large texts
        db_config: Database configuration. If None, reads from config.
        async_mode: If True, queue for async processing. If None, checks config.
    
    Returns:
        True if successful or queued, False otherwise
    """
    if db_config is None:
        db_config = read_database_config()
    
    if not db_config.get("vectorization_enabled", True):
        return False
    
    # Check if we should use async mode
    if async_mode is None:
        async_mode = db_config.get("rabbitmq_enabled", False)
    
    if async_mode:
        # Queue for async processing
        status = queue_vectorization(content_type, content_id, content_text, metadata, db_config)
        return status.startswith("queued_")
    
    # Get chunk settings
    chunk_size = db_config.get("chunk_size", 1000)
    chunk_overlap = db_config.get("chunk_overlap", 200)
    
    # Chunk text if needed
    if chunk and len(content_text) > chunk_size:
        chunks = chunk_text(content_text, chunk_size, chunk_overlap)
    else:
        chunks = [content_text]
    
    # Generate embeddings for each chunk
    embeddings = []
    for chunk_text in chunks:
        embedding = generate_embedding(chunk_text)
        if embedding:
            embeddings.append((chunk_text, embedding))
    
    if not embeddings:
        print(f"Warning: No embeddings generated for {content_type}:{content_id}", file=sys.stderr)
        return False
    
    # Store in database
    db = VectorDatabase(db_config)
    if not db.connect():
        print(f"Error: Could not connect to database", file=sys.stderr)
        return False
    
    try:
        # For now, store the first chunk's embedding (or combine chunks)
        # TODO: Support multiple chunks per content item
        if len(embeddings) == 1:
            text, embedding = embeddings[0]
            success = db.store_embedding(
                content_type=content_type,
                content_id=content_id,
                content_text=text,
                embedding=embedding,
                metadata=metadata
            )
        else:
            # For multiple chunks, combine text and use average embedding
            combined_text = "\n\n".join([text for text, _ in embeddings])
            # Average embeddings
            avg_embedding = [
                sum(emb[i] for _, emb in embeddings) / len(embeddings)
                for i in range(len(embeddings[0][1]))
            ]
            success = db.store_embedding(
                content_type=content_type,
                content_id=content_id,
                content_text=combined_text,
                embedding=avg_embedding,
                metadata=metadata
            )
        
        db.disconnect()
        return success
    except Exception as e:
        print(f"Error storing embedding: {e}", file=sys.stderr)
        db.disconnect()
        return False


def vectorize_batch(
    items: List[Dict[str, Any]],
    db_config: Optional[Dict[str, Any]] = None
) -> Tuple[int, int]:
    """
    Vectorize multiple content items in batch.
    
    Args:
        items: List of dicts with keys: content_type, content_id, content_text, metadata
        db_config: Database configuration. If None, reads from config.
    
    Returns:
        Tuple of (successful_count, failed_count)
    """
    if db_config is None:
        db_config = read_database_config()
    
    batch_size = db_config.get("batch_size", 10)
    successful = 0
    failed = 0
    
    for i in range(0, len(items), batch_size):
        batch = items[i:i + batch_size]
        for item in batch:
            success = vectorize_content(
                content_type=item.get("content_type", "unknown"),
                content_id=item.get("content_id", ""),
                content_text=item.get("content_text", ""),
                metadata=item.get("metadata"),
                db_config=db_config
            )
            if success:
                successful += 1
            else:
                failed += 1
    
    return successful, failed


def search_similar(
    query_text: str,
    content_type: Optional[str] = None,
    limit: int = 10,
    threshold: float = 0.7,
    config: Optional[Dict[str, Any]] = None,
    db_config: Optional[Dict[str, Any]] = None
) -> List[Dict[str, Any]]:
    """
    Search for similar content using vector similarity.
    
    Args:
        query_text: Query text to search for
        content_type: Optional filter by content type
        limit: Maximum number of results
        threshold: Minimum similarity threshold
        config: AI config for embedding generation
        db_config: Database configuration
    
    Returns:
        List of similar content items
    """
    if config is None:
        config = read_config()
    if db_config is None:
        db_config = read_database_config()
    
    # Generate embedding for query
    query_embedding = generate_embedding(query_text, config)
    if not query_embedding:
        return []
    
    # Search database
    db = VectorDatabase(db_config)
    if not db.connect():
        return []
    
    try:
        results = db.search_similar(
            query_embedding=query_embedding,
            content_type=content_type,
            limit=limit,
            threshold=threshold
        )
        return results
    finally:
        db.disconnect()


if __name__ == "__main__":
    # Test vectorization
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: gtd_vectorization.py <command> [args...]")
        print("Commands:")
        print("  test-connection - Test database connection")
        print("  init-schema - Initialize database schema")
        print("  vectorize <type> <id> <text> - Vectorize a piece of content")
        print("  queue <type> <id> <text> - Queue content for async vectorization")
        print("  search <query> - Search for similar content")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "test-connection":
        db = VectorDatabase()
        if db.connect():
            print("✓ Database connection successful")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif command == "queue":
        # Queue content for async vectorization
        if len(sys.argv) < 5:
            print("Usage: gtd_vectorization.py queue <type> <id> <text>")
            sys.exit(1)
        
        content_type = sys.argv[2]
        content_id = sys.argv[3]
        content_text = sys.argv[4]
        
        status = queue_vectorization(content_type, content_id, content_text)
        if status.startswith("queued_"):
            # Success - exit silently (don't spam output)
            sys.exit(0)
        else:
            # Failed - output error
            print(f"Queue failed: {status}", file=sys.stderr)
            sys.exit(1)
    
    elif command == "init-schema":
        db = VectorDatabase()
        if db.connect():
            db.initialize_schema()
            print("✓ Schema initialized")
            db.disconnect()
        else:
            print("✗ Database connection failed")
            sys.exit(1)
    
    elif command == "vectorize":
        if len(sys.argv) < 5:
            print("Usage: gtd_vectorization.py vectorize <type> <id> <text>")
            sys.exit(1)
        
        content_type = sys.argv[2]
        content_id = sys.argv[3]
        content_text = sys.argv[4]
        
        success = vectorize_content(content_type, content_id, content_text)
        if success:
            print(f"✓ Vectorized {content_type}:{content_id}")
        else:
            print(f"✗ Failed to vectorize {content_type}:{content_id}")
            sys.exit(1)
    
    elif command == "search":
        if len(sys.argv) < 3:
            print("Usage: gtd_vectorization.py search <query>")
            sys.exit(1)
        
        query = sys.argv[2]
        results = search_similar(query)
        
        if results:
            print(f"Found {len(results)} similar items:")
            for result in results:
                print(f"  [{result['content_type']}] {result['content_id']}: {result['similarity']:.3f}")
                print(f"    {result['content_text'][:100]}...")
        else:
            print("No similar content found")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)

