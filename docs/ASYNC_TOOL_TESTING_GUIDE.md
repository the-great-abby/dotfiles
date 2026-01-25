# Async Tool Calling Testing Guide

## Overview

This guide covers comprehensive testing for the async tool calling methods in the Claude Ollama Bridge, addressing complex scenarios, error handling, and performance validation.

## Test Suite Components

### 1. Core Async Tool Tests (`test_claude_ollama_bridge_async.py`)

**Purpose**: Tests fundamental async tool calling functionality

**Test Categories**:

#### Tool Calling Initialization
- ✅ `test_tool_calling_initialization()` - Tool registry setup and state initialization
- ✅ `test_tool_execution_details_tracking()` - Tool execution tracking system

#### Successful Workflows
- ✅ `test_successful_tool_calling_flow()` - End-to-end tool calling with proper responses
- ✅ `test_complex_multi_tool_sequence()` - Multiple tool calls in sequence

#### Error Handling
- ✅ `test_tool_call_timeout_handling()` - Timeout scenarios and recovery
- ✅ `test_tool_execution_error_handling()` - Tool execution failures
- ✅ `test_ai_describes_tools_instead_of_calling()` - AI enforcement when describing vs calling tools

#### Workflow Validation  
- ✅ `test_runbook_request_detection_and_workflow()` - Runbook workflow enforcement
- ✅ `test_max_iterations_limit()` - Tool calling loop limits

#### State Management
- ✅ `test_async_response_state_management()` - Async state consistency

#### Performance
- ✅ `test_concurrent_tool_calls_handling()` - Concurrent request handling
- ✅ `test_tool_execution_performance_tracking()` - Performance monitoring

### 2. Advanced Scenario Tests (`test_async_tool_scenarios.py`)

**Purpose**: Tests realistic workflows and complex edge cases

**Test Categories**:

#### Real-World Workflows
- ✅ `test_daily_log_review_runbook_workflow()` - Complete 5-step runbook execution
- ✅ `test_complex_persona_interactions()` - Persona-based tool calling

#### Error Recovery
- ✅ `test_tool_call_retry_on_failure()` - Retry mechanisms
- ✅ `test_partial_timeout_recovery()` - Recovery from partial timeouts
- ✅ `test_malformed_tool_arguments_handling()` - Invalid JSON handling
- ✅ `test_network_error_recovery()` - Network failure recovery
- ✅ `test_invalid_response_format_recovery()` - Malformed response handling

#### State Consistency
- ✅ `test_async_state_consistency()` - State persistence across operations

### 3. Test Runner (`gtd-test-async-tools`)

**Purpose**: Comprehensive test execution with reporting and benchmarking

**Features**:
- 🧪 Runs all async tool tests systematically
- ⚡ Performance benchmarking
- 🔗 Integration testing with live Ollama
- 📊 Detailed reporting and analysis
- 🎯 Selective test execution

## Usage Instructions

### Quick Start
```bash
# Run all async tool tests
gtd-test-async-tools

# Quiet output with report
gtd-test-async-tools --quiet --report async_report.json
```

### Selective Testing
```bash
# Basic functionality only
gtd-test-async-tools --basic

# Advanced scenarios
gtd-test-async-tools --scenarios  

# Integration tests (requires Ollama)
gtd-test-async-tools --integration

# Performance benchmarks
gtd-test-async-tools --benchmarks
```

### Individual Test Modules
```bash
# Core async tests
python3 tests/test_claude_ollama_bridge_async.py

# Scenario tests  
python3 tests/test_async_tool_scenarios.py
```

## Key Scenarios Tested

### 1. Daily Log Review Runbook Workflow
**Test**: `test_daily_log_review_runbook_workflow()`

**Validates**:
1. `list_agent_skills(query='runbook')` → Find runbook
2. `get_agent_skill(skill_name='daily-log-review-runbook')` → Get runbook content  
3. `gtd_read_daily_log(date='today')` → Read actual data
4. `gtd_list_tasks()` → Cross-reference with tasks
5. Final analysis response using real data

**Why Important**: Tests the exact workflow that was failing in your TUI

### 2. AI Tool Description Detection
**Test**: `test_ai_describes_tools_instead_of_calling()`

**Validates**:
- Detects when AI writes "I will call gtd_read_daily_log()" instead of actual tool calls
- Enforces proper function calling API usage
- Recovers with enforcement messages

**Why Important**: Prevents the "completed but waiting" state by ensuring tools are actually called

### 3. Timeout Recovery
**Test**: `test_partial_timeout_recovery()`

**Validates**:
- Handles "Request timed out after 30s, but process still running" scenarios
- Graceful degradation when requests timeout
- Proper error messaging

**Why Important**: Directly addresses your TUI timeout issue

### 4. Complex Multi-Tool Sequences
**Test**: `test_complex_multi_tool_sequence()`  

**Validates**:
- Multiple tool calls in sequence
- Conversation state management between calls
- Tool result integration into responses

**Why Important**: Tests realistic usage patterns like runbooks

## Performance Benchmarks

The test runner includes performance benchmarking for:

### Initialization Benchmarking
- Bridge object creation time
- Tool registry loading
- State initialization

### Execution Benchmarking  
- Tool call parsing speed
- JSON argument processing
- Mock tool execution timing

### Error Handling Benchmarking
- Exception handling speed
- Error message generation
- Recovery mechanism timing

## Addressing Your TUI Issue

### Specific Tests for "Completed but Waiting" State

1. **Async Response State Management**
   ```bash
   # Run specific test
   python3 -m pytest tests/test_claude_ollama_bridge_async.py::TestAsyncToolCalling::test_async_response_state_management -v
   ```

2. **Timeout Handling**
   ```bash
   # Run timeout-specific tests
   python3 -m pytest tests/test_claude_ollama_bridge_async.py::TestAsyncToolCalling::test_tool_call_timeout_handling -v
   python3 -m pytest tests/test_async_tool_scenarios.py::TestAsyncErrorRecovery::test_partial_timeout_recovery -v
   ```

3. **Tool Call State Validation**
   ```bash
   # Test AI enforcement mechanisms
   python3 -m pytest tests/test_claude_ollama_bridge_async.py::TestAsyncToolCalling::test_ai_describes_tools_instead_of_calling -v
   ```

### Integration with TUI Testing

These async tool tests complement your TUI testing framework:

1. **TUI Tests** → Test the interface and user interaction
2. **Async Tool Tests** → Test the underlying tool calling logic  
3. **Combined Analysis** → Identify where interface and logic disconnect

## Test Reports and Debugging

### Detailed Reports
```bash
# Generate comprehensive report
gtd-test-async-tools --report /tmp/async_tool_report.json

# View report
cat /tmp/async_tool_report.json | jq '.test_results'
```

### Debug Individual Failures
```bash
# Verbose output for debugging
python3 tests/test_claude_ollama_bridge_async.py -v

# Run specific failing test
python3 -m pytest tests/test_claude_ollama_bridge_async.py::TestAsyncToolCalling::test_specific_failure -v -s
```

## Mock vs Integration Testing

### Mock Testing (Default)
- Uses `unittest.mock` to simulate API calls
- Tests logic without external dependencies  
- Fast execution, reliable results
- Validates method interactions and error handling

### Integration Testing
- Requires running Ollama instance
- Tests with real API calls
- Slower but validates end-to-end functionality
- Run with `gtd-test-async-tools --integration`

## Common Issues and Solutions

### 1. Import Errors
```bash
# Ensure you're in the dotfiles directory
cd /Users/abby/code/dotfiles

# Install dependencies
pip install pexpect pytest requests
```

### 2. Missing Modules
```bash
# Add mcp directory to Python path
export PYTHONPATH="/Users/abby/code/dotfiles/mcp:$PYTHONPATH"
```

### 3. Mock Failures
- Check that mocks match the actual API signatures
- Verify return value formats match expected structures
- Ensure side_effect sequences are correct

### 4. Integration Test Failures  
- Verify Ollama is running: `ollama list`
- Check network connectivity: `curl http://localhost:11434/api/tags`
- Confirm model availability: `ollama show llama3.1:8b-instruct-q6_K`

## Best Practices

### Writing New Async Tool Tests

1. **Use Descriptive Names**
   ```python
   def test_runbook_workflow_with_tool_execution_failure(self):
   ```

2. **Mock External Dependencies**
   ```python
   @patch('claude_ollama_bridge.get_available_tools')
   @patch('requests.post')
   def test_method(self, mock_post, mock_get_tools):
   ```

3. **Test Both Success and Failure**
   ```python
   # Test success case
   mock_execute.return_value = "Success result"
   
   # Test failure case  
   mock_execute.side_effect = Exception("Tool failed")
   ```

4. **Validate State Changes**
   ```python
   # Before
   self.assertEqual(len(self.bridge._tool_execution_details), 0)
   
   # Execute
   result, error = self.bridge._call_ollama(...)
   
   # After
   self.assertEqual(len(self.bridge._tool_execution_details), 1)
   ```

### Debugging Async Issues

1. **Add Debug Logging**
   ```python
   import logging
   logging.basicConfig(level=logging.DEBUG)
   ```

2. **Check State at Each Step**
   ```python
   print(f"Tool execution details: {self.bridge._tool_execution_details}")
   print(f"Last Ollama call: {self.bridge.last_ollama_call}")
   ```

3. **Validate Mock Call Sequences**
   ```python
   # Check that mocks were called in expected order
   expected_calls = [call(...), call(...)]
   mock_execute.assert_has_calls(expected_calls)
   ```

## Future Enhancements

1. **Async/Await Testing** - Test actual asyncio patterns if bridge becomes truly async
2. **Stress Testing** - High-load concurrent tool calling
3. **Memory Leak Detection** - Long-running tool call sequences
4. **Real-time Monitoring** - Live tool execution tracking during tests
5. **Chaos Engineering** - Random failure injection testing

## Summary

This comprehensive async tool testing framework ensures your Claude Ollama Bridge handles all the complex scenarios that can cause TUI issues like "completed but waiting" states. The tests validate proper tool calling flows, error recovery, timeout handling, and state management - addressing the root causes of your TUI problems.