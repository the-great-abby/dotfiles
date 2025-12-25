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
    Supports both LM Studio and Ollama backends.
    
    Returns:
        Dictionary with embedding configuration
    """
    # Read config files in order - later files override earlier ones
    # .gtd_config_ai is most specific and should override .gtd_config
    config_paths = [
        Path.home() / ".daily_log_config",
        Path.home() / ".gtd_config",
        Path.home() / ".gtd_config_ai",  # Most specific - should override
        Path(__file__).parent.parent / ".daily_log_config",
        Path(__file__).parent.parent / ".gtd_config",
        Path(__file__).parent.parent / ".gtd_config_ai"  # Most specific - should override
    ]
    
    embedding_model = ""
    base_url = "http://localhost:1234/v1"
    timeout = 60
    backend = "lmstudio"  # Default to lmstudio for backward compatibility
    computer_mode = "home"  # Default to home
    
    # First pass: read all config values (later files override earlier ones)
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
                        
                        if key == "AI_BACKEND":
                            backend = value.lower()
                        elif key == "GTD_COMPUTER_MODE":
                            computer_mode = value.lower()
                        elif key == "LM_STUDIO_EMBEDDING_MODEL":
                            embedding_model = value
                        elif key == "LM_STUDIO_URL" and "/v1" in value:
                            base_url = value.replace("/v1/chat/completions", "/v1")
                        elif key == "OLLAMA_EMBEDDING_MODEL":
                            embedding_model = value
                        elif key == "OLLAMA_URL" and "/v1" in value:
                            base_url = value.replace("/v1/chat/completions", "/v1")
                        elif key == "LM_STUDIO_TIMEOUT" or key == "TIMEOUT":
                            try:
                                timeout = int(value)
                            except ValueError:
                                pass
    
    # Second pass: check for mode-specific settings (WORK_* or HOME_*)
    mode_prefix = "WORK_" if computer_mode == "work" else "HOME_"
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
                        
                        # Check for mode-specific settings
                        if key.startswith(mode_prefix):
                            mode_key = key[len(mode_prefix):]  # Remove prefix
                            if mode_key == "AI_BACKEND" and value:
                                backend = value.lower()
                            elif mode_key == "LM_STUDIO_EMBEDDING_MODEL" and value:
                                embedding_model = value
                            elif mode_key == "LM_STUDIO_URL" and "/v1" in value:
                                base_url = value.replace("/v1/chat/completions", "/v1")
                            elif mode_key == "OLLAMA_EMBEDDING_MODEL" and value:
                                embedding_model = value
                            elif mode_key == "OLLAMA_URL" and "/v1" in value:
                                base_url = value.replace("/v1/chat/completions", "/v1")
    
    # Set URL and model based on backend
    if backend == "ollama":
        # Use Ollama defaults if not set
        if not base_url or base_url == "http://localhost:1234/v1":
            base_url = "http://localhost:11434/v1"
        # Override with environment variables
        embedding_model = os.getenv("OLLAMA_EMBEDDING_MODEL", embedding_model)
    else:
        # Use LM Studio defaults if not set
        if not base_url or base_url == "http://localhost:11434/v1":
            base_url = "http://localhost:1234/v1"
        # Override with environment variables
        embedding_model = os.getenv("LM_STUDIO_EMBEDDING_MODEL", embedding_model)
    
    return {
        "embedding_model": embedding_model,
        "base_url": base_url,
        "timeout": timeout,
        "backend": backend
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
    backend = embedding_config.get("backend", "lmstudio").lower()
    
    if not embedding_model:
        # Try environment variable based on backend
        if backend == "ollama":
            embedding_model = os.getenv("OLLAMA_EMBEDDING_MODEL", "")
        else:
            embedding_model = os.getenv("LM_STUDIO_EMBEDDING_MODEL", "")
        
        if not embedding_model:
            backend_name = "Ollama" if backend == "ollama" else "LM Studio"
            env_var = "OLLAMA_EMBEDDING_MODEL" if backend == "ollama" else "LM_STUDIO_EMBEDDING_MODEL"
            print(f"Error: No embedding model configured. Set {env_var} in .gtd_config_ai or set AI_BACKEND={backend}", file=sys.stderr)
            return None
    
    # Get API URL from embedding_config (not config, which may be None)
    base_url = embedding_config.get("base_url", "http://localhost:1234/v1")
    # If base_url contains /v1/chat/completions, remove that part
    if "/v1/chat/completions" in base_url:
        base_url = base_url.replace("/v1/chat/completions", "/v1")
    elif not base_url.endswith("/v1"):
        # Ensure it ends with /v1
        if base_url.endswith("/"):
            base_url = base_url.rstrip("/") + "/v1"
        else:
            base_url = base_url + "/v1"
    
    embedding_url = f"{base_url}/embeddings"
    timeout = embedding_config.get("timeout", 60)
    
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


def estimate_tokens(text: str) -> int:
    """
    Quick approximation of token count: ~4 characters per token.
    
    Args:
        text: Text to estimate
    
    Returns:
        Estimated token count
    """
    return len(text) // 4


def chunk_by_paragraphs(text: str, max_tokens: int, overlap_tokens: int) -> List[str]:
    """
    Split text into chunks by paragraph boundaries with overlap.
    
    Args:
        text: Text to chunk
        max_tokens: Maximum tokens per chunk
        overlap_tokens: Tokens to overlap between chunks
    
    Returns:
        List of text chunks
    """
    paragraphs = [p.strip() for p in text.split('\n\n') if p.strip()]
    
    if not paragraphs:
        return [text] if text.strip() else []
    
    chunks = []
    current_chunk = []
    current_tokens = 0
    
    for para in paragraphs:
        para_tokens = estimate_tokens(para)
        
        if current_tokens + para_tokens > max_tokens and current_chunk:
            # Save current chunk
            chunks.append('\n\n'.join(current_chunk))
            
            # Start new chunk with overlap (keep last paragraph)
            if overlap_tokens > 0 and current_chunk:
                current_chunk = [current_chunk[-1]]
                current_tokens = estimate_tokens(current_chunk[-1])
            else:
                current_chunk = []
                current_tokens = 0
        
        current_chunk.append(para)
        current_tokens += para_tokens
    
    # Don't forget the last chunk
    if current_chunk:
        chunks.append('\n\n'.join(current_chunk))
    
    return chunks if chunks else [text]


def chunk_markdown(
    file_path: str,
    content: str,
    max_tokens: int = 512,
    overlap_tokens: int = 50
) -> List[Dict[str, Any]]:
    """
    Chunks markdown by semantic boundaries (headers > paragraphs > sentences)
    while preserving document structure.
    
    Args:
        file_path: Path to the markdown file
        content: Markdown content to chunk
        max_tokens: Maximum tokens per chunk
        overlap_tokens: Tokens to overlap between chunks
    
    Returns:
        List of chunk dictionaries with metadata
    """
    chunks = []
    
    # Split on headers first (preserves document structure)
    # Pattern matches: \n followed by 1-6 # followed by space and heading text
    sections = re.split(r'(\n#{1,6}\s+.+)', content)
    
    current_heading_stack = []  # Track nested headers like ["# Main", "## Sub"]
    
    for i, section in enumerate(sections):
        # Check if this is a header
        header_match = re.match(r'\n(#{1,6})\s+(.+)', section)
        
        if header_match:
            level = len(header_match.group(1))
            heading_text = header_match.group(2).strip()
            
            # Update heading stack (pop deeper levels)
            current_heading_stack = current_heading_stack[:level-1]
            current_heading_stack.append(heading_text)
            
        elif section.strip():  # Content section
            # Build hierarchical context
            heading_path = " > ".join(current_heading_stack) if current_heading_stack else ""
            
            # Chunk this section if too large
            section_chunks = chunk_by_paragraphs(
                section,
                max_tokens,
                overlap_tokens
            )
            
            for idx, chunk_text in enumerate(section_chunks):
                # Prepend context for better embeddings
                if heading_path:
                    contextualized = f"""Document: {file_path}
Section: {heading_path}

{chunk_text}"""
                else:
                    contextualized = f"""Document: {file_path}

{chunk_text}"""
                
                chunks.append({
                    'content': chunk_text,  # Original without context
                    'content_with_context': contextualized,  # For vectorization
                    'file_path': file_path,
                    'heading_path': heading_path,
                    'chunk_index': len(chunks),
                    'section_chunk_index': idx,
                    'metadata': {
                        'has_code_block': '```' in chunk_text,
                        'has_list': bool(re.search(r'^\s*[-*]\s', chunk_text, re.MULTILINE)),
                        'has_links': '[' in chunk_text and '](' in chunk_text,
                        'chunk_type': 'section',
                    }
                })
    
    # If no headers found, chunk as plain text
    if not chunks:
        section_chunks = chunk_by_paragraphs(content, max_tokens, overlap_tokens)
        for idx, chunk_text in enumerate(section_chunks):
            contextualized = f"""Document: {file_path}

{chunk_text}"""
            chunks.append({
                'content': chunk_text,
                'content_with_context': contextualized,
                'file_path': file_path,
                'heading_path': '',
                'chunk_index': idx,
                'section_chunk_index': idx,
                'metadata': {
                    'has_code_block': '```' in chunk_text,
                    'has_list': bool(re.search(r'^\s*[-*]\s', chunk_text, re.MULTILINE)),
                    'has_links': '[' in chunk_text and '](' in chunk_text,
                    'chunk_type': 'document',
                }
            })
    
    return chunks


def chunk_text(text: str, chunk_size: int = 1000, overlap: int = 200) -> List[str]:
    """
    Split text into chunks for processing (legacy function for non-markdown).
    
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
                # Set connection parameters with timeout (pika 1.3.2 compatible)
                params = pika.URLParameters(rabbitmq_url)
                params.blocked_connection_timeout = 5  # 5 second timeout
                connection = pika.BlockingConnection(params)
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
                    OSError) as e:
                # RabbitMQ not available, fall back to file queue
                if os.getenv("GTD_DEBUG") or os.getenv("DEBUG_VECTORIZATION"):
                    print(f"⚠️  RabbitMQ connection error (falling back to file queue): {e}", file=sys.stderr)
                pass
            except Exception as e:
                # Other RabbitMQ errors, fall back to file queue
                if os.getenv("GTD_DEBUG") or os.getenv("DEBUG_VECTORIZATION"):
                    print(f"⚠️  RabbitMQ error (falling back to file queue): {e}", file=sys.stderr)
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


def vectorize_document(
    file_path: str,
    content_text: str,
    metadata: Optional[Dict[str, Any]] = None,
    db_config: Optional[Dict[str, Any]] = None,
    async_mode: Optional[bool] = None
) -> bool:
    """
    Vectorize a document (file) using smart semantic chunking.
    
    Args:
        file_path: Path to the document file
        content_text: Text content to vectorize
        metadata: Optional metadata dictionary (may contain project, category, tags)
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
        # Use 'file' as content_type for documents
        content_id = file_path.replace("/", "-").replace("\\", "-")
        status = queue_vectorization("file", content_id, content_text, metadata, db_config)
        return status.startswith("queued_")
    
    # Determine file type
    file_path_lower = file_path.lower()
    if file_path_lower.endswith(('.md', '.markdown')):
        file_type = "markdown"
        # Use smart markdown chunking
        max_tokens = db_config.get("chunk_size", 1000) // 4  # Convert chars to tokens (approx)
        overlap_tokens = db_config.get("chunk_overlap", 200) // 4
        chunks = chunk_markdown(file_path, content_text, max_tokens, overlap_tokens)
    else:
        file_type = "text"
        # Use regular chunking for non-markdown
        chunk_size = db_config.get("chunk_size", 1000)
        chunk_overlap = db_config.get("chunk_overlap", 200)
        text_chunks = chunk_text(content_text, chunk_size, chunk_overlap)
        # Convert to chunk dict format
        chunks = []
        for idx, chunk_text in enumerate(text_chunks):
            contextualized = f"""Document: {file_path}

{chunk_text}"""
            chunks.append({
                'content': chunk_text,
                'content_with_context': contextualized,
                'file_path': file_path,
                'heading_path': '',
                'chunk_index': idx,
                'section_chunk_index': idx,
                'metadata': {
                    'chunk_type': 'text',
                }
            })
    
    if not chunks:
        print(f"Warning: No chunks created for {file_path}", file=sys.stderr)
        return False
    
    # Extract organizational metadata
    project = metadata.get('project') if metadata else None
    category = metadata.get('category') if metadata else None
    tags = metadata.get('tags', []) if metadata else []
    last_modified = metadata.get('modified_time') if metadata else None
    
    # Store chunks in database (without embeddings first)
    db = VectorDatabase(db_config)
    if not db.connect():
        print(f"Error: Could not connect to database", file=sys.stderr)
        return False
    
    try:
        # Store chunks structure
        success = db.store_document_chunks(
            chunks=chunks,
            file_path=file_path,
            file_type=file_type,
            project=project,
            category=category,
            tags=tags,
            last_modified=last_modified
        )
        
        if not success:
            print(f"Error storing chunks for {file_path}", file=sys.stderr)
            db.disconnect()
            return False
        
        # Generate embeddings for each chunk
        for chunk in chunks:
            # Use content_with_context for embedding (better semantic understanding)
            text_to_embed = chunk.get('content_with_context', chunk['content'])
            embedding = generate_embedding(text_to_embed)
            
            if embedding:
                # Store embedding for this chunk
                db.store_document_chunk_embedding(
                    file_path=file_path,
                    chunk_index=chunk['chunk_index'],
                    embedding=embedding
                )
            else:
                print(f"Warning: Failed to generate embedding for chunk {chunk['chunk_index']} of {file_path}", file=sys.stderr)
        
        db.disconnect()
        return True
    except Exception as e:
        print(f"Error vectorizing document: {e}", file=sys.stderr)
        db.disconnect()
        return False


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
    
    # Check if this is a file/document that should use smart chunking
    file_path = None
    if metadata and 'file_path' in metadata:
        file_path = metadata['file_path']
    elif content_type in ('file', 'document', 'note'):
        # Try to reconstruct file path from content_id or metadata
        if metadata and 'file_name' in metadata:
            file_path = metadata.get('file_path', content_id)
    
    # Use smart chunking for files/documents
    if file_path and content_type in ('file', 'document', 'note'):
        return vectorize_document(file_path, content_text, metadata, db_config, async_mode)
    
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
    for text_chunk in chunks:
        embedding = generate_embedding(text_chunk)
        if embedding:
            embeddings.append((text_chunk, embedding))
    
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
    db_config: Optional[Dict[str, Any]] = None,
    exclude_content_types: Optional[List[str]] = None
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
        exclude_content_types: Optional list of content types to exclude (e.g., ['document'] to exclude advice results)
    
    Returns:
        List of similar content items
    """
    if config is None:
        # Use read_embedding_config() instead of read_config() to get embedding model
        config = read_embedding_config()
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
            threshold=threshold,
            exclude_content_types=exclude_content_types
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

