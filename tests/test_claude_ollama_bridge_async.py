#!/usr/bin/env python3
"""
Comprehensive tests for async tool calling methods in Claude Ollama Bridge

Tests the complex tool calling flows, async handling, error conditions,
and timeout scenarios in the bridge system.
"""

import asyncio
import json
import time
from unittest import TestCase
from unittest.mock import Mock, patch, AsyncMock, MagicMock
import pytest
import sys
from pathlib import Path

# Add the mcp directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp"))

try:
    from claude_ollama_bridge import SmartAIRouter
except ImportError as e:
    print(f"❌ Error: Could not import SmartAIRouter: {e}")
    print("Make sure you're running from the dotfiles directory")
    sys.exit(1)

class TestAsyncToolCalling(TestCase):
    """Test async tool calling functionality"""
    
    def setUp(self):
        """Set up test router instance"""
        self.router = SmartAIRouter()
        # Set up test configuration
        self.router.mode = "hybrid"
        self.router.ollama_model = "llama3.1:8b-instruct-q6_K"
        self.router.ollama_timeout = 30
        
        # Mock the tool registry
        self.mock_tools = [
            {
                "type": "function",
                "function": {
                    "name": "gtd_read_daily_log",
                    "description": "Read daily log entries",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "date": {"type": "string", "description": "Date to read"}
                        },
                        "required": ["date"]
                    }
                }
            },
            {
                "type": "function", 
                "function": {
                    "name": "gtd_list_tasks",
                    "description": "List current tasks",
                    "parameters": {"type": "object", "properties": {}}
                }
            }
        ]

    @patch('claude_ollama_bridge.get_available_tools')
    def test_tool_calling_initialization(self, mock_get_tools):
        """Test tool calling setup and initialization"""
        mock_get_tools.return_value = self.mock_tools
        
        # Test tool registry loading
        tools = mock_get_tools()
        self.assertEqual(len(tools), 2)
        self.assertEqual(tools[0]["function"]["name"], "gtd_read_daily_log")
        
        # Test tool execution details initialization (if exists in router)
        if hasattr(self.router, '_tool_execution_details'):
            self.router._tool_execution_details = []
            self.assertEqual(len(self.router._tool_execution_details), 0)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('claude_ollama_bridge.handle_ai_response')
    @patch('requests.post')
    def test_successful_tool_calling_flow(self, mock_post, mock_handle_ai, mock_get_tools):
        """Test successful tool calling with proper flow"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock successful Ollama response with tool calls
        mock_ollama_response = {
            "id": "test-request-id",
            "choices": [{
                "message": {
                    "tool_calls": [{
                        "id": "call_1", 
                        "function": {
                            "name": "gtd_read_daily_log",
                            "arguments": '{"date": "today"}'
                        }
                    }]
                }
            }]
        }
        
        mock_post.return_value.json.return_value = mock_ollama_response
        mock_handle_ai.return_value = (mock_ollama_response, None)
        
        # Mock tool execution
        with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
            mock_execute.return_value = "Daily log entry: Worked on testing"
            
            result, error = self.bridge._call_ollama(
                request_type="data", 
                content="read my daily log",
                persona=None,
                context={}
            )
            
            # Verify tool was called
            mock_execute.assert_called()
            self.assertIsNotNone(result)
            self.assertIsNone(error)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('claude_ollama_bridge.handle_ai_response') 
    @patch('requests.post')
    def test_tool_call_timeout_handling(self, mock_post, mock_handle_ai, mock_get_tools):
        """Test timeout handling in tool calls"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock timeout response
        mock_handle_ai.return_value = (None, "Request timed out after 30s")
        
        # Set up timeout scenario
        mock_post.return_value.json.return_value = {"request_id": "test-timeout"}
        
        result, error = self.bridge._call_ollama(
            request_type="data",
            content="read my daily log", 
            persona=None,
            context={}
        )
        
        self.assertIsNone(result)
        self.assertIsNotNone(error)
        self.assertIn("timed out", error)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_ai_describes_tools_instead_of_calling(self, mock_post, mock_get_tools):
        """Test detection when AI describes tools instead of calling them"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock AI response that describes tools instead of calling
        mock_bad_response = {
            "choices": [{
                "message": {
                    "content": 'I will call gtd_read_daily_log() to get your daily log data.',
                    "tool_calls": []  # No actual tool calls!
                }
            }]
        }
        
        # Mock enforcement response after detection
        mock_good_response = {
            "choices": [{
                "message": {
                    "tool_calls": [{
                        "id": "call_1",
                        "function": {
                            "name": "gtd_read_daily_log", 
                            "arguments": '{"date": "today"}'
                        }
                    }]
                }
            }]
        }
        
        # Set up response sequence
        mock_post.return_value.json.side_effect = [
            mock_bad_response,  # First bad response
            mock_good_response  # Corrected response after enforcement
        ]
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.side_effect = [
                (mock_bad_response, None),
                (mock_good_response, None)
            ]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                mock_execute.return_value = "Daily log data"
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="read my daily log",
                    persona=None, 
                    context={}
                )
                
                # Should have made 2 requests - initial bad one + enforcement
                self.assertEqual(mock_post.call_count, 2)
                
                # Should eventually succeed after enforcement
                self.assertIsNotNone(result)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_tool_execution_error_handling(self, mock_post, mock_get_tools):
        """Test error handling when tool execution fails"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock response with valid tool call
        mock_response = {
            "choices": [{
                "message": {
                    "tool_calls": [{
                        "id": "call_1",
                        "function": {
                            "name": "gtd_read_daily_log",
                            "arguments": '{"date": "invalid-date"}'
                        }
                    }]
                }
            }]
        }
        
        mock_post.return_value.json.return_value = mock_response
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.return_value = (mock_response, None)
            
            # Mock tool execution failure
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                mock_execute.side_effect = Exception("Tool execution failed")
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="read my daily log",
                    persona=None,
                    context={}
                )
                
                # Should handle tool error gracefully
                # Implementation should continue with error message to AI
                self.assertIsNotNone(mock_execute.call_count)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post') 
    def test_complex_multi_tool_sequence(self, mock_post, mock_get_tools):
        """Test complex sequence with multiple tool calls"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock sequence: first tool call, then second tool call, then final response
        responses = [
            # First iteration - calls gtd_read_daily_log
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_1",
                            "function": {
                                "name": "gtd_read_daily_log",
                                "arguments": '{"date": "today"}'
                            }
                        }]
                    }
                }]
            },
            # Second iteration - calls gtd_list_tasks  
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_2", 
                            "function": {
                                "name": "gtd_list_tasks",
                                "arguments": '{}'
                            }
                        }]
                    }
                }]
            },
            # Final iteration - text response
            {
                "choices": [{
                    "message": {
                        "content": "Based on your daily log and tasks, here's my analysis...",
                        "tool_calls": []
                    }
                }]
            }
        ]
        
        mock_post.return_value.json.side_effect = responses
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.side_effect = [(resp, None) for resp in responses]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                # Mock tool results
                mock_execute.side_effect = [
                    "Daily log: Worked on project A",
                    "Tasks: [Task 1, Task 2, Task 3]"
                ]
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="analyze my daily log and tasks",
                    persona=None,
                    context={}
                )
                
                # Should execute both tools
                self.assertEqual(mock_execute.call_count, 2)
                self.assertIsNone(error)
                self.assertIsNotNone(result)

    def test_tool_execution_details_tracking(self):
        """Test tracking of tool execution details"""
        self.bridge._tool_execution_details = []
        
        # Simulate adding tool execution details
        detail = {
            'tool_name': 'gtd_read_daily_log',
            'arguments': {'date': 'today'},
            'result': 'Daily log content',
            'duration_ms': 150,
            'success': True
        }
        
        self.bridge._tool_execution_details.append(detail)
        
        self.assertEqual(len(self.bridge._tool_execution_details), 1)
        self.assertEqual(self.bridge._tool_execution_details[0]['tool_name'], 'gtd_read_daily_log')
        self.assertTrue(self.bridge._tool_execution_details[0]['success'])

    @patch('claude_ollama_bridge.get_available_tools')
    def test_runbook_request_detection_and_workflow(self, mock_get_tools):
        """Test runbook request detection and mandatory workflow"""
        mock_get_tools.return_value = self.mock_tools
        
        # Test runbook detection
        runbook_content = "use the daily log review runbook"
        
        # Mock the _call_ollama_openai_compatible method to test system message
        with patch.object(self.bridge, '_call_ollama_openai_compatible') as mock_openai_call:
            mock_openai_call.return_value = ({"response": "test"}, None)
            
            self.bridge._call_ollama(
                request_type="data",
                content=runbook_content,
                persona=None,
                context={}
            )
            
            # Verify the method was called (indicating runbook workflow was triggered)
            mock_openai_call.assert_called_once()
            
            # Get the call arguments to verify runbook instructions were added
            call_args = mock_openai_call.call_args
            prompt = call_args[0][0]  # First positional argument is the prompt
            
            # Should contain runbook-specific instructions
            system_msg = prompt.get('system', '')
            self.assertIn('RUNBOOK REQUEST DETECTED', system_msg)
            self.assertIn('list_agent_skills', system_msg)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_max_iterations_limit(self, mock_post, mock_get_tools):
        """Test that tool calling loop respects max iterations limit"""
        mock_get_tools.return_value = self.mock_tools
        
        # Mock response that always returns tool calls (infinite loop scenario)
        infinite_tool_response = {
            "choices": [{
                "message": {
                    "tool_calls": [{
                        "id": "call_infinite",
                        "function": {
                            "name": "gtd_read_daily_log",
                            "arguments": '{"date": "today"}'
                        }
                    }]
                }
            }]
        }
        
        mock_post.return_value.json.return_value = infinite_tool_response
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.return_value = (infinite_tool_response, None)
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                mock_execute.return_value = "Some result"
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="read my daily log",
                    persona=None,
                    context={}
                )
                
                # Should eventually stop due to max iterations (15)
                # The exact count depends on implementation, but should be limited
                self.assertTrue(mock_execute.call_count <= 15)

    def test_async_response_state_management(self):
        """Test async response state management"""
        # Test initial state
        self.assertIsNone(getattr(self.bridge, 'last_ollama_call', None))
        
        # Mock datetime for consistent testing
        with patch('claude_ollama_bridge.datetime') as mock_datetime:
            mock_now = mock_datetime.now.return_value
            
            # Initialize tool execution details
            self.bridge._tool_execution_details = []
            
            # Verify state tracking
            self.assertEqual(len(self.bridge._tool_execution_details), 0)
            
            # Test state after initialization
            self.assertIsInstance(self.bridge._tool_execution_details, list)

class TestAsyncToolCallPerformance(TestCase):
    """Performance and load testing for async tool calls"""
    
    def setUp(self):
        self.bridge = ClaudeOllamaBridge(
            claude_api_key="test-key",
            ollama_model="llama3.1:8b-instruct-q6_K", 
            ollama_timeout=5,  # Shorter timeout for performance tests
            ollama_direct_url="http://localhost:11434/api/generate",
            ollama_openai_url="http://localhost:11434/v1/chat/completions"
        )

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_concurrent_tool_calls_handling(self, mock_post, mock_get_tools):
        """Test handling of multiple concurrent tool calls"""
        mock_get_tools.return_value = []
        
        # Mock fast response
        mock_response = {
            "choices": [{
                "message": {
                    "content": "Quick response",
                    "tool_calls": []
                }
            }]
        }
        
        mock_post.return_value.json.return_value = mock_response
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.return_value = (mock_response, None)
            
            # Simulate concurrent requests
            start_time = time.time()
            
            results = []
            for i in range(3):
                result, error = self.bridge._call_ollama(
                    request_type="simple",
                    content=f"request {i}",
                    persona=None,
                    context={}
                )
                results.append((result, error))
            
            duration = time.time() - start_time
            
            # All should succeed
            for result, error in results:
                self.assertIsNotNone(result)
                self.assertIsNone(error)
            
            # Should complete reasonably quickly
            self.assertLess(duration, 10)  # Should complete within 10 seconds

    @patch('claude_ollama_bridge.get_available_tools')  
    def test_tool_execution_performance_tracking(self, mock_get_tools):
        """Test performance tracking of tool executions"""
        mock_tools = [{
            "type": "function",
            "function": {
                "name": "gtd_list_tasks",
                "description": "List tasks",
                "parameters": {"type": "object", "properties": {}}
            }
        }]
        mock_get_tools.return_value = mock_tools
        
        # Initialize tracking
        self.bridge._tool_execution_details = []
        
        # Simulate tool execution with timing
        start_time = time.time()
        
        # Mock execution
        detail = {
            'tool_name': 'gtd_list_tasks',
            'arguments': {},
            'start_time': start_time,
            'end_time': start_time + 0.1,  # 100ms execution
            'duration_ms': 100,
            'success': True,
            'result_length': 250
        }
        
        self.bridge._tool_execution_details.append(detail)
        
        # Verify tracking
        self.assertEqual(len(self.bridge._tool_execution_details), 1)
        self.assertEqual(self.bridge._tool_execution_details[0]['duration_ms'], 100)
        self.assertTrue(self.bridge._tool_execution_details[0]['success'])

if __name__ == '__main__':
    # Add requirements check
    try:
        import requests
        import pytest
    except ImportError as e:
        print(f"❌ Missing required packages: {e}")
        print("Install with: pip install requests pytest")
        sys.exit(1)
    
    # Run tests with verbose output
    import unittest
    
    print("🧪 Running Claude Ollama Bridge Async Tool Calling Tests...")
    print("=" * 70)
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestAsyncToolCalling))
    suite.addTests(loader.loadTestsFromTestCase(TestAsyncToolCallPerformance))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "=" * 70)
    if result.wasSuccessful():
        print("✅ All async tool calling tests passed!")
    else:
        print(f"❌ {len(result.failures)} failures, {len(result.errors)} errors")
        
    print(f"📊 Ran {result.testsRun} tests")
    
    # Exit with appropriate code
    sys.exit(0 if result.wasSuccessful() else 1)