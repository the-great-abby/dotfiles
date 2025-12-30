# GTD Wizard Web Interface - Integration Guide

This document explains how the web interface integrates with the existing GTD Wizard CLI system.

## Architecture Overview

```
┌─────────────────┐
│  Web Browser   │
│   (Svelte)     │
└────────┬────────┘
         │ HTTP/WebSocket
         │
┌────────▼────────┐
│  FastAPI       │
│  Backend       │
└────────┬────────┘
         │
         │ Subprocess calls
         │
┌────────▼────────┐
│  GTD Bash      │
│  Scripts       │
│  (bin/*)       │
└─────────────────┘
```

## Integration Points

### 1. Command Execution

The backend executes GTD bash scripts via Python's `subprocess` module:

```python
def execute_gtd_command(command: str, *args) -> dict:
    cmd_path = GTD_BASE / "bin" / command
    result = subprocess.run(
        [str(cmd_path)] + list(args),
        capture_output=True,
        text=True,
        cwd=str(GTD_BASE),
        env=env,
        timeout=30
    )
    return {
        "success": result.returncode == 0,
        "stdout": result.stdout,
        "stderr": result.stderr
    }
```

### 2. Command Mapping

| Web Interface Action | CLI Command | Arguments |
|---------------------|-------------|-----------|
| Capture item | `gtd-capture` | `type description [--priority] [--project]` |
| List tasks | `gtd-task list` | `[--priority] [--status]` |
| Create task | `gtd-task add` | `description [--priority] [--project]` |
| Complete task | `gtd-task complete` | `task_id` |
| List projects | `gtd-project list` | |
| List inbox | `gtd-inbox list` | |
| Get status | `gtd-inbox count`, `gtd-task list --count`, etc. | |

### 3. Data Flow

#### Capture Flow

```
User Input (Web) 
  → POST /api/capture 
  → execute_gtd_command("gtd-capture", type, description)
  → Bash script creates file in inbox/
  → WebSocket broadcast status update
  → Frontend updates UI
```

#### Task List Flow

```
User Request (Web)
  → GET /api/tasks
  → execute_gtd_command("gtd-task", "list")
  → Parse stdout
  → Return JSON
  → Frontend displays tasks
```

## Compatibility

### Full Compatibility

The web interface is **fully compatible** with the CLI wizard:

- ✅ Same data files (tasks, projects, inbox items)
- ✅ Same commands and operations
- ✅ Same directory structure
- ✅ Can use both interfaces interchangeably

### Shared State

Both interfaces operate on the same:
- Task files in `tasks/` directory
- Project files in `projects/` directory
- Inbox files in `inbox/` directory
- Configuration files in `zsh/.gtd_config*`

## Extending the Integration

### Adding New Endpoints

To add a new wizard function to the web interface:

1. **Add API Endpoint** (`web/backend/main.py`):

```python
@app.post("/api/new-feature")
async def new_feature(data: NewFeatureModel):
    result = execute_gtd_command("gtd-new-feature", data.arg1, data.arg2)
    if result["success"]:
        return {"success": True, "message": result["stdout"]}
    else:
        raise HTTPException(status_code=400, detail=result["stderr"])
```

2. **Add Frontend Component** (`web/frontend/src/components/NewFeature.svelte`):

```svelte
<script>
  import { api } from '../services/api.js'
  
  const callNewFeature = async () => {
    await api.newFeature({ arg1: 'value1', arg2: 'value2' })
  }
</script>
```

3. **Add API Method** (`web/frontend/src/services/api.js`):

```javascript
async newFeature(data) {
  const response = await fetch(`${API_BASE}/new-feature`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data)
  })
  if (!response.ok) throw new Error('Failed')
  return response.json()
}
```

### Calling Wizard Functions Directly

You can call any wizard function via the API:

```python
# Call a specific wizard function
result = execute_gtd_command("gtd-wizard", "--function", "capture_wizard")
```

However, wizard functions are interactive, so it's better to:
1. Extract the logic from wizard functions
2. Create dedicated commands for each operation
3. Call those commands from the API

### Parsing Command Output

Many GTD commands output text. The backend parses this:

```python
def parse_task_list(output: str) -> List[Dict[str, Any]]:
    tasks = []
    lines = output.strip().split("\n")
    for line in lines:
        if line.strip() and not line.startswith("---"):
            tasks.append({
                "id": len(tasks) + 1,
                "description": line.strip(),
                "priority": "medium"
            })
    return tasks
```

For better parsing, consider:
1. Adding `--json` flags to GTD commands
2. Using structured output formats
3. Parsing markdown frontmatter from files

## Error Handling

### Command Failures

The backend handles command failures gracefully:

```python
result = execute_gtd_command("gtd-task", "list")
if not result["success"]:
    # Fallback: read files directly
    tasks_dir = GTD_BASE / "tasks"
    if tasks_dir.exists():
        tasks = [parse_task_file(f) for f in tasks_dir.glob("*.md")]
```

### Timeout Handling

Commands have a 30-second timeout:

```python
result = subprocess.run(
    [cmd_path] + args,
    timeout=30  # Prevents hanging
)
```

### Missing Commands

If a command doesn't exist, the backend returns an error:

```python
if not cmd_path.exists():
    return {
        "success": False,
        "stderr": f"Command not found: {command}"
    }
```

## Real-Time Updates

### WebSocket Integration

The backend broadcasts updates via WebSocket:

```python
@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    # Send periodic status updates
    while True:
        status = await get_status()
        await websocket.send_json({
            "type": "status_update",
            "data": status.dict()
        })
        await asyncio.sleep(5)
```

### Status Updates

When operations complete, status is broadcast:

```python
await manager.broadcast({
    "type": "status_update",
    "message": "Item captured successfully"
})
```

## File System Integration

### Reading Files

The backend can read GTD files directly:

```python
# Read task file
task_file = GTD_BASE / "tasks" / f"{task_id}.md"
with open(task_file, 'r') as f:
    content = f.read()
```

### Writing Files

Generally, use GTD commands to write files (they handle formatting):

```python
# Don't write directly - use command
execute_gtd_command("gtd-capture", "task", "New task")
```

## Configuration Integration

### Reading Config

The backend reads GTD configuration:

```python
# Config is in environment or files
GTD_BASE = Path.home() / "code" / "dotfiles"
config_file = GTD_BASE / "zsh" / ".gtd_config"
```

### Mode-Specific Settings

The backend respects computer mode (work/home):

```python
# Mode is set in environment or config
# Backend uses same config as CLI
```

## Testing Integration

### Test Commands

Test that commands work:

```bash
# Test capture
curl -X POST http://localhost:8000/api/capture \
  -H "Content-Type: application/json" \
  -d '{"type": "task", "description": "Test task"}'

# Test status
curl http://localhost:8000/api/status
```

### Verify Compatibility

1. Create item via web interface
2. Verify it appears in CLI: `gtd-inbox list`
3. Process via CLI
4. Verify status updates in web interface

## Best Practices

### 1. Use Commands, Not Direct File Access

✅ Good:
```python
execute_gtd_command("gtd-capture", "task", "New task")
```

❌ Bad:
```python
# Don't write files directly
with open(inbox_file, 'w') as f:
    f.write("New task")
```

### 2. Handle Errors Gracefully

```python
try:
    result = execute_gtd_command("gtd-task", "list")
    if result["success"]:
        return parse_tasks(result["stdout"])
    else:
        # Fallback to file reading
        return read_tasks_from_files()
except Exception as e:
    logger.error(f"Error: {e}")
    return {"tasks": []}
```

### 3. Validate Inputs

```python
class CaptureItem(BaseModel):
    type: str  # Validated by Pydantic
    description: str  # Required, non-empty
    priority: Optional[str] = None
```

### 4. Timeout Long Operations

```python
result = execute_gtd_command("gtd-sync", timeout=60)  # 60s for sync
```

### 5. Log Operations

```python
logger.info(f"Executing: gtd-capture {type} {description}")
result = execute_gtd_command("gtd-capture", type, description)
logger.info(f"Result: {result['success']}")
```

## Future Enhancements

### 1. JSON Output

Add `--json` flags to GTD commands for better parsing:

```bash
gtd-task list --json
# Output: {"tasks": [{"id": 1, "description": "...", ...}]}
```

### 2. Command Status API

Create status endpoint for long-running operations:

```python
@app.get("/api/operations/{operation_id}/status")
async def get_operation_status(operation_id: str):
    # Check status of async operation
    pass
```

### 3. Batch Operations

Support batch operations:

```python
@app.post("/api/tasks/batch")
async def batch_create_tasks(tasks: List[TaskCreate]):
    results = []
    for task in tasks:
        result = execute_gtd_command("gtd-task", "add", task.description)
        results.append(result)
    return {"results": results}
```

## Summary

The web interface integrates seamlessly with the existing GTD Wizard:

- ✅ Uses same commands and files
- ✅ Fully compatible with CLI
- ✅ Real-time updates via WebSocket
- ✅ Graceful error handling
- ✅ Extensible architecture

You can use both interfaces together without conflicts!





