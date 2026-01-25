# TUI Testing & Debugging Guide

## Overview

This guide covers the comprehensive testing and debugging solution for the `claude-ask-interactive` TUI, addressing the common issues of:
- 🚫 Unable to copy/paste large TUI output for debugging
- 👁️ Assistant can't see TUI interface directly 
- 🐛 Inconsistent TUI behavior and stuck states
- 🔄 Async response handling issues

## Tools Available

### 1. TUI Integration Testing Framework
**File**: `tests/test_tui_integration.py`

**Purpose**: Automated testing with keypress simulation and state validation

**Key Features**:
- ⌨️ Simulates user keypresses (Ctrl+J, Esc, Tab, etc.)
- 📊 Captures and validates TUI state
- 🏥 Health checks for stuck processes
- 📁 Exports comprehensive debug information

**Usage**:
```bash
# Run all tests
python3 tests/test_tui_integration.py

# Run specific test
pytest tests/test_tui_integration.py::TestTUIIntegration::test_tui_startup -v
```

### 2. Advanced TUI Debugger
**File**: `bin/gtd-tui-debug`

**Purpose**: Interactive debugging and health monitoring

**Commands**:
```bash
# Comprehensive health check
gtd-tui-debug health

# Interactive debugging session
gtd-tui-debug interactive
# Available commands: health, start, stop, send <message>, state, export, quit

# Monitor TUI over time
gtd-tui-debug monitor --duration 60
```

**Interactive Debug Commands**:
- `health` - Check TUI health status
- `start` - Start TUI for testing
- `stop` - Stop TUI
- `send <message>` - Send message to TUI
- `state` - Show current TUI state
- `export` - Export debug info to file
- `quit` - Exit debug session

### 3. Terminal Session Recorder
**File**: `bin/gtd-terminal-recorder`

**Purpose**: Record TUI sessions for analysis and playback

**Commands**:
```bash
# Record a session
gtd-terminal-recorder record --session my_debug_session

# Play back recorded session
gtd-terminal-recorder play --session /tmp/tui_recordings/my_debug_session.json

# Analyze session for issues
gtd-terminal-recorder analyze --session /tmp/tui_recordings/my_debug_session.json
```

## Solving Current Issues

### Problem: TUI Stuck in "completed but waiting" State

**Diagnosis Steps**:

1. **Quick Health Check**:
   ```bash
   gtd-tui-debug health > /tmp/tui_diagnosis.txt
   ```

2. **Interactive Debug**:
   ```bash
   gtd-tui-debug interactive
   # Type: health
   # Type: start
   # Type: state
   ```

3. **Export Debug Info**:
   ```bash
   # In interactive mode
   export
   # Creates timestamped debug file in /tmp/
   ```

### Problem: Can't Copy/Paste TUI Output

**Solution: Automated State Capture**

Instead of manually copying TUI content:

```bash
# Capture comprehensive TUI state
gtd-tui-debug health 2>&1 | tee tui_state_report.txt

# Share with assistant
# "@tui_state_report.txt shows the issue"
```

**What gets captured**:
- 🔍 Running processes
- 📊 TUI health metrics
- ⚡ Async response status
- 💡 Specific recommendations
- 📁 JSON-formatted debug data

### Problem: Assistant Can't See TUI

**Solution: Structured Debug Exports**

The testing framework exports structured data:

```json
{
  "timestamp": 1640995200,
  "startup_successful": false,
  "health_report": {
    "tui_responsive": false,
    "async_handling_ok": false,
    "stuck_processes": [
      {
        "command": "request-status 8a509515-...",
        "duration": 60
      }
    ]
  },
  "recommendations": [
    "Restart TUI with Ctrl+C and 'make claude-ask-interactive'",
    "Check Ollama Controller async response handling"
  ]
}
```

## Common Test Scenarios

### 1. Startup Test
```bash
python3 -c "
from tests.test_tui_integration import TUITester
tester = TUITester()
if tester.start_tui():
    print('✅ TUI starts successfully')
else:
    print('❌ TUI startup failed')
tester.stop_tui()
"
```

### 2. Message Sending Test
```bash
gtd-tui-debug interactive
# Commands:
# start
# send hello world
# state
# export
# quit
```

### 3. Async Response Test
```bash
# Monitor for stuck async states
gtd-tui-debug monitor --duration 30
```

### 4. Health Validation
```bash
gtd-tui-debug health | jq '.health_report.async_handling_ok'
# Should return: true
```

## MCP Integration Possibilities

### Current Limitation
- Browser MCPs (`cursor-ide-browser`, `cursor-browser-extension`) work with **web browsers**, not terminal TUIs
- No direct way to control terminal applications via browser automation

### Potential Solutions

#### 1. Terminal Control MCP (Could Build)
```json
{
  "name": "terminal-controller",
  "tools": [
    "send_keys_to_terminal",
    "capture_terminal_state", 
    "get_running_terminals",
    "execute_in_terminal"
  ]
}
```

#### 2. TUI State API MCP (Better Approach)
- Expose TUI state via HTTP/WebSocket API
- Allow remote monitoring and control
- Enable web-based debugging interface

#### 3. Session Analysis MCP
- Automatically record TUI sessions
- Analyze patterns and detect issues
- Generate health reports

## Dependencies

**Required**:
```bash
pip install pexpect pytest
```

**Optional** (for enhanced features):
```bash
pip install rich        # Better terminal output
pip install websockets  # For TUI API server
```

## Troubleshooting

### Common Issues

1. **"pexpect not found"**
   ```bash
   pip install pexpect
   ```

2. **"Permission denied" on debug tools**
   ```bash
   chmod +x bin/gtd-tui-debug
   chmod +x bin/gtd-terminal-recorder
   ```

3. **TUI won't start in tests**
   - Check Ollama is running: `ollama list`
   - Verify environment: `echo $TERM`
   - Try manual start: `make claude-ask-interactive`

### Debug Tool Output Locations

- Health reports: `/tmp/tui_debug_*.json`
- Session recordings: `/tmp/tui_recordings/`
- Monitor logs: `/tmp/tui_monitoring_*.json`

## Best Practices

### 1. Before Reporting TUI Issues
```bash
# Always run health check first
gtd-tui-debug health > issue_report.txt
```

### 2. When TUI Gets Stuck
```bash
# Capture state before killing
gtd-tui-debug interactive
# Type: state
# Type: export
# Then Ctrl+C to kill stuck TUI
```

### 3. For Intermittent Issues
```bash
# Use monitoring to catch patterns
gtd-tui-debug monitor --duration 300  # 5 minutes
```

### 4. Sharing Debug Info
- Always export to JSON files
- Include both health reports and session recordings
- Use structured data instead of screenshots

## Future Enhancements

1. **Web-based TUI Debugger** - Browser interface for TUI debugging
2. **Automated Issue Detection** - ML-based pattern recognition
3. **Real-time Collaboration** - Share TUI sessions with assistants
4. **Performance Monitoring** - Response time and resource usage tracking
5. **Integration Testing** - End-to-end workflow validation