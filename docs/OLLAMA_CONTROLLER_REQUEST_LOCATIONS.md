# Ollama Controller Request Locations

This document lists all places in the codebase that send requests to Ollama Controller (or other AI backends) via `/v1/chat/completions`.

## Main Request Functions

### 1. `gtd_persona_helper.py` - `call_persona()`
**Status:** ✅ **Tools enabled for Ollama Controller**  
**Location:** `zsh/functions/gtd_persona_helper.py`

- **Used by:** Persona helper scripts, interactive advice requests
- **Tool support:** ✅ Yes - Tools enabled when using Ollama Controller
- **Logging:** ✅ Logs to `~/.gtd_logs/tool_calls.log`
- **Tool categories:** Web tools (if requested), GTD tools (if `enable_gtd_tools=True`)

### 2. `gtd_deep_analysis_worker.py` - `call_deep_ai()`
**Status:** ✅ **Tools enabled for Ollama Controller** (with logging added)  
**Location:** `mcp/gtd_deep_analysis_worker.py`

- **Used by:** Advice worker, deep analysis worker, weekly reviews, insights
- **Tool support:** ✅ Yes - GTD tools enabled by default when using Ollama Controller
- **Logging:** ✅ Now logs to `~/.gtd_logs/tool_calls.log` (just added)
- **Tool categories:** GTD tools (always included for deep analysis)
- **Note:** This is what the advice worker uses!

### 3. `gtd_enhanced_search.py` - `_call_llm()`
**Status:** ⚠️ **No tool support** (but probably doesn't need it)  
**Location:** `zsh/functions/gtd_enhanced_search.py`

- **Used by:** Enhanced web search query generation
- **Tool support:** ❌ No
- **Reason:** This is for query enhancement, not user-facing advice - tools not needed

### 4. `lmstudio_helper.py` - `call_lm_studio()`
**Status:** ⚠️ **No tool support** (but probably doesn't need it)  
**Location:** `zsh/functions/lmstudio_helper.py`

- **Used by:** Daily log reminders (Hank Hill persona)
- **Tool support:** ❌ No
- **Reason:** Simple reminder generation - tools probably not needed
- **Note:** Could add tools if needed for future enhancements

### 5. `gtd_mcp_server.py` - `call_fast_ai()`
**Status:** ⚠️ **No tool support** (but probably doesn't need it)  
**Location:** `mcp/gtd_mcp_server.py`

- **Used by:** MCP server for quick AI responses
- **Tool support:** ❌ No
- **Reason:** Fast/quick responses - tools might add overhead
- **Note:** Could add tools if needed for MCP tool calls

### 6. `gtd_ai_async.py` - `submit_ai_request_async()`
**Status:** ℹ️ **Wrapper function** (doesn't add tools itself)  
**Location:** `zsh/functions/gtd_ai_async.py`

- **Used by:** Async request submission (non-blocking)
- **Tool support:** N/A - Receives payload from caller, doesn't modify it
- **Note:** Tools should be added to payload before calling this function

## Summary

### Functions WITH Tool Support (Ollama Controller)
1. ✅ `call_persona()` - Interactive persona advice
2. ✅ `call_deep_ai()` - Deep analysis and advice worker

### Functions WITHOUT Tool Support
3. ⚠️ `_call_llm()` - Enhanced search (probably doesn't need tools)
4. ⚠️ `call_lm_studio()` - Daily reminders (probably doesn't need tools)
5. ⚠️ `call_fast_ai()` - Fast MCP responses (could add if needed)

## Available GTD Tools

When tools are enabled, these are available:

1. **`gtd_list_tasks`** - List tasks with filters (context, energy, priority, project, status)
2. **`gtd_create_task`** - Create new tasks
3. **`gtd_list_projects`** - List projects
4. **`gtd_read_daily_log`** - Read daily log entries (⚠️ **This is what you need!**)
5. **`perform_web_search`** - Web search (only in `call_persona` when requested)

## Verification

To verify tools are being sent, check the log file:

```bash
tail -f ~/.gtd_logs/tool_calls.log
```

You should see entries like:
```
[timestamp] call_deep_ai (blocking) - Model: model_name, URL: http://127.0.0.1:31080/v1/chat/completions
  -> Ollama Controller: True
  -> ✅ Added X tool(s): gtd_list_tasks, gtd_create_task, gtd_list_projects, gtd_read_daily_log
  -> Tool choice: auto
  -> ✅ Tools in payload: X tool(s)
```

## Next Steps

If tools still aren't working after restarting the advice worker:

1. **Check the log file** to see if tools are being added
2. **Verify tool registry import** - Check for import errors in the log
3. **Check if tools are empty** - The log will show if `get_tool_definitions` returns empty
4. **Verify Ollama Controller detection** - Make sure URL contains `:31080`
