# Wizard Vectorization Integration

## Summary

Vectorization has been integrated into the GTD wizard to automatically vectorize content when it's created or updated.

## What Was Added

### 1. Vectorization Helper Script (`gtd-vectorize-content`)

A new helper script that:
- Checks if vectorization is enabled
- Vectorizes content in the background (non-blocking)
- Handles errors gracefully (silent failures)
- Works with any content type

**Usage:**
```bash
gtd-vectorize-content <content_type> <content_id> <content_text>
```

### 2. Integration Points

#### Daily Log Wizard (`gtd-wizard-inputs.sh`)
- ✅ **Integrated**: After log entry is saved
- **Content Type**: `daily_log`
- **Content ID**: `{date}_{time}` (e.g., `2024-01-15_14:30`)
- **Content Text**: The log entry text

#### Project Wizard (`gtd-wizard-org.sh`)
- ✅ **Integrated**: After project is created
- **Content Type**: `project`
- **Content ID**: Project slug (e.g., `my-project-name`)
- **Content Text**: Project README content (first 100 lines) or project name

## How It Works

1. **User creates content** (log entry, project, etc.)
2. **Content is saved** to file system
3. **Vectorization is triggered** automatically in background
4. **Embedding is generated** using configured embedding model
5. **Vector is stored** in PostgreSQL database

## Configuration

Vectorization is controlled by settings in `.gtd_config_database`:

```bash
# Enable/disable vectorization
GTD_VECTORIZATION_ENABLED="true"

# Auto-vectorize on creation
VECTORIZE_ON_CREATE="true"

# Auto-vectorize on update
VECTORIZE_ON_UPDATE="true"
```

## Background Processing

Vectorization runs in the background (`&`) so it doesn't block the wizard:
- User can continue using the wizard immediately
- No waiting for embedding generation
- Errors are logged but don't interrupt workflow

## Content Types Supported

Currently integrated:
- ✅ `daily_log` - Daily log entries
- ✅ `project` - Project descriptions
- ✅ `task` - Individual tasks

Future integration points:
- ⏳ `note` - Notes and references
- ⏳ `suggestion` - AI suggestions

## Testing

To test vectorization:

1. **Create a daily log entry:**
   ```bash
   gtd-wizard
   # Choose option 15 (Daily Log)
   # Choose option 1 (Add entry)
   # Enter some text
   ```

2. **Create a project:**
   ```bash
   gtd-wizard
   # Choose option 3 (Projects)
   # Choose option 1 (Create project)
   # Enter project name
   ```

3. **Check if vectorized:**
   ```bash
   python3 zsh/functions/gtd_vectorization.py search "your search query"
   ```

## Benefits

1. **Automatic**: No manual steps required
2. **Non-blocking**: Doesn't slow down wizard
3. **Searchable**: Content becomes searchable via semantic search
4. **Discoverable**: Find related content through similarity search

## Future Enhancements

1. **Task vectorization**: When tasks are created/updated
2. **Batch vectorization**: Process existing content
3. **Update detection**: Re-vectorize when content changes
4. **Search integration**: Add vector search to wizard search function

## Notes

- Vectorization requires:
  - PostgreSQL database running
  - pgvector extension installed
  - Embedding model configured
  - `psycopg2-binary` Python package installed

- If vectorization fails, the wizard continues normally (failures are silent)

- Vectorization can be disabled by setting `GTD_VECTORIZATION_ENABLED="false"`
