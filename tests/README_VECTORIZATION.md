# Vectorization System Tests

## Overview

Tests for the GTD vectorization system including database connection, embedding generation, and vector storage.

## Test Files

### `test_gtd_vectorization.py`
Python unit tests using unittest framework. Tests:
- Database configuration reading
- Embedding configuration reading
- Text chunking
- Embedding generation (mocked)
- Vector database operations (mocked)
- Content vectorization
- Batch processing
- Similarity search

### `test_gtd_vector_db_connection.sh`
Shell script that tests actual database connection with real credentials. Tests:
- Database connection
- Schema initialization
- Config file reading
- Python dependencies
- Embedding model configuration

## Running Tests

### Unit Tests (Python)

```bash
# Run all unit tests
python3 tests/test_gtd_vectorization.py

# Run with verbose output
python3 tests/test_gtd_vectorization.py -v
```

### Connection Tests (Shell)

```bash
# Test actual database connection
./tests/test_gtd_vector_db_connection.sh
```

## Prerequisites

### Python Dependencies

```bash
pip install psycopg2-binary
```

### Database Setup

1. PostgreSQL running on configured host/port
2. Database created with pgvector extension
3. Credentials configured in `.gtd_config_database`

### Configuration

Ensure `.gtd_config_database` is configured:
```bash
VECTOR_DB_HOST="localhost"
VECTOR_DB_PORT="13003"
VECTOR_DB_NAME="gtd_organization_system"
VECTOR_DB_USER="gtd_organization_system"
VECTOR_DB_PASSWORD="your_password"
```

## Test Coverage

### Unit Tests (Mocked)
- ✅ Config reading
- ✅ Text chunking
- ✅ Embedding generation (mocked API calls)
- ✅ Database operations (mocked connections)
- ✅ Vector storage and retrieval
- ✅ Similarity search
- ✅ Batch processing
- ✅ Error handling

### Integration Tests (Real Database)
- ✅ Database connection
- ✅ Schema initialization
- ✅ Config file loading
- ✅ Dependency checking

## Troubleshooting

### "psycopg2 not installed"
```bash
pip install psycopg2-binary
```

### "Database connection failed"
1. Check PostgreSQL is running
2. Verify credentials in `.gtd_config_database`
3. Test direct connection: `psql -h localhost -p 13003 -U gtd_organization_system -d gtd_organization_system`

### "pgvector extension not available"
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### "Module not found: zsh"
The tests handle import paths automatically. If you see this error, ensure you're running from the dotfiles root directory.

## Expected Results

### Unit Tests
All unit tests should pass (they use mocks, so no database required).

### Connection Tests
Connection tests require:
- ✅ Database running
- ✅ Credentials configured
- ✅ pgvector extension installed

Some tests may fail if the database isn't set up yet - that's expected.

