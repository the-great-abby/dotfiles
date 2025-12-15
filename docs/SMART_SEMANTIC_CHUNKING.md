# Smart Semantic Chunking Implementation

## Overview

This document describes the implementation of smart semantic chunking for markdown files, as suggested by Claude.ai. The system now respects document structure (headers, sections, paragraphs) and stores rich metadata for better search and retrieval.

## What Changed

### 1. Smart Markdown Chunking

**New Function**: `chunk_markdown()` in `gtd_vectorization.py`

- Respects markdown structure (headers > paragraphs > sentences)
- Tracks heading hierarchy (e.g., "Main Topic > Subtopic > Section")
- Preserves document context by prepending heading paths to chunks
- Chunks at semantic boundaries (paragraphs) rather than arbitrary character counts

**Key Features:**
- Splits on markdown headers (`#`, `##`, etc.)
- Maintains heading stack for hierarchical context
- Chunks sections by paragraphs with overlap
- Detects content characteristics (code blocks, lists, links)

### 2. New Database Schema

**New Table**: `document_vectors`

Stores chunks separately with rich metadata:

```sql
CREATE TABLE document_vectors (
    id SERIAL PRIMARY KEY,
    file_path TEXT NOT NULL,
    chunk_index INT NOT NULL,
    
    -- Content
    content TEXT NOT NULL,  -- Original chunk
    content_with_context TEXT,  -- With heading path prepended
    
    -- Vector
    embedding vector(768),  -- or your dimension
    
    -- Structure metadata
    heading_path TEXT,  -- "Main Topic > Subtopic"
    section_chunk_index INT,
    
    -- Organizational metadata
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
    
    -- Additional metadata
    metadata JSONB,
    
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    UNIQUE(file_path, chunk_index)
);
```

**Indexes:**
- Vector similarity: `ivfflat` on embedding
- File path lookup
- Project filtering
- Tags (GIN index)
- Heading path full-text search
- Metadata (GIN index)

### 3. Contextual Enrichment

Each chunk is enriched with context before vectorization:

```
Document: /path/to/file.md
Section: Main Topic > Subtopic

[actual chunk content]
```

This helps embeddings understand the semantic context of each chunk.

### 4. Separate Chunk Storage

Unlike the old system that averaged multiple chunks, the new system:
- Stores each chunk separately
- Maintains chunk relationships (heading_path, section_chunk_index)
- Allows precise retrieval of specific sections

## Usage

### Automatic (Filewatcher)

The filewatcher automatically uses smart chunking for markdown files:

```bash
# Filewatcher detects .md files and uses smart chunking
gtd-wizard → 27 → 10 → 4  # Start filewatcher
```

### Manual Vectorization

```python
from gtd_vectorization import vectorize_document

vectorize_document(
    file_path="/path/to/document.md",
    content_text=content,
    metadata={
        "project": "acme",
        "category": "analysis",
        "tags": ["market", "research"]
    }
)
```

### Search with Metadata

```python
from gtd_vector_db import VectorDatabase

db = VectorDatabase()
db.connect()

# Semantic search with project filter
results = db.search_document_vectors(
    query_embedding=query_embedding,
    project="acme",
    limit=5
)

# Hybrid: semantic + keyword in headings
results = db.search_document_vectors(
    query_embedding=query_embedding,
    heading_path_query="market & analysis",
    limit=5
)
```

## Migration

### Automatic Schema Creation

The new schema is created automatically when you run:

```bash
gtd-init-vector-db
# or
python3 zsh/functions/gtd_vector_db.py init
```

### Backward Compatibility

- Old `vector_embeddings` table remains unchanged
- New `document_vectors` table is separate
- Existing vectorized content continues to work
- New files use smart chunking automatically

### Re-vectorizing Existing Files

To re-vectorize existing files with smart chunking:

```bash
# Scan and re-vectorize all markdown files
gtd-vector-scan-existing

# Or manually
python3 << 'PYEOF'
import sys
sys.path.insert(0, 'zsh/functions')
from gtd_vectorization import vectorize_document
from pathlib import Path

file_path = Path("/path/to/your/file.md")
if file_path.exists():
    content = file_path.read_text()
    vectorize_document(
        file_path=str(file_path),
        content_text=content,
        metadata={"file_name": file_path.name}
    )
PYEOF
```

## Query Strategies

### 1. Semantic Search with Project Filter

```sql
SELECT content, heading_path, file_path
FROM document_vectors
WHERE project = 'acme'
ORDER BY embedding <=> query_vector
LIMIT 5;
```

### 2. Hybrid: Semantic + Keyword in Headings

```sql
SELECT content, heading_path, file_path
FROM document_vectors
WHERE to_tsvector('english', heading_path) @@ to_tsquery('market & analysis')
ORDER BY embedding <=> query_vector
LIMIT 5;
```

### 3. Find Related Content Across Projects

```sql
SELECT DISTINCT project, COUNT(*)
FROM document_vectors
WHERE embedding <=> query_vector < 0.3  -- similarity threshold
GROUP BY project;
```

## Benefits

1. **Better Search Quality**: Contextual enrichment improves semantic understanding
2. **Precise Retrieval**: Find specific sections, not just documents
3. **Rich Metadata**: Filter by project, category, tags, heading paths
4. **Structure Preservation**: Maintains document hierarchy
5. **Flexible Queries**: Combine semantic search with keyword filtering

## Configuration

Chunking parameters in `.gtd_config_database`:

```bash
# Chunk size (characters, converted to tokens for markdown)
VECTOR_CHUNK_SIZE="${VECTOR_CHUNK_SIZE:-1000}"

# Chunk overlap (characters)
VECTOR_CHUNK_OVERLAP="${VECTOR_CHUNK_OVERLAP:-200}"
```

For markdown files, these are converted to tokens (approximately ÷4) for the smart chunking algorithm.

## Examples

### Example: Chunking a Markdown File

**Input:**
```markdown
# Main Topic

## Subtopic A

This is some content about subtopic A.

## Subtopic B

This is content about subtopic B.
```

**Output Chunks:**
1. `heading_path: "Main Topic > Subtopic A"`, `content: "This is some content about subtopic A."`
2. `heading_path: "Main Topic > Subtopic B"`, `content: "This is content about subtopic B."`

Each chunk stored with:
- Original content
- Content with context prepended
- Heading path
- Chunk index
- Metadata (has_code_block, has_list, has_links)

## Future Enhancements

- [ ] Support for code block chunking
- [ ] Table extraction and chunking
- [ ] Cross-reference tracking
- [ ] Parent document summary generation
- [ ] Surrounding context chunks (±1-2 chunks)

## References

- Original suggestion from Claude.ai conversation
- Implementation based on semantic chunking best practices
- Schema inspired by pgvector documentation and RAG patterns
