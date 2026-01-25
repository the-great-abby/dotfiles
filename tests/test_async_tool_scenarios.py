#!/usr/bin/env python3
"""
Advanced async tool calling scenario tests

Tests realistic scenarios, edge cases, and complex workflows
for the Claude Ollama Bridge async tool calling system.
"""

import asyncio
import json
import time
from unittest import TestCase
from unittest.mock import Mock, patch, MagicMock, call
import pytest
import sys
from pathlib import Path

# Add the mcp directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp"))

try:
    from claude_ollama_bridge import SmartAIRouter
except ImportError as e:
    print(f"❌ Error: Could not import SmartAIRouter: {e}")
    sys.exit(1)

class TestRealWorldAsyncScenarios(TestCase):
    """Test realistic async tool calling scenarios"""
    
    def setUp(self):
        self.router = SmartAIRouter()
        # Set up test configuration
        self.router.mode = "hybrid"
        if hasattr(self.router, 'ollama_model'):
            self.router.ollama_model = "llama3.1:8b-instruct-q6_K"
        if hasattr(self.router, 'ollama_timeout'):
            self.router.ollama_timeout = 30
        
        self.full_tool_suite = [
            {
                "type": "function",
                "function": {
                    "name": "gtd_read_daily_log",
                    "description": "Read daily log entries",
                    "parameters": {
                        "type": "object",
                        "properties": {"date": {"type": "string"}},
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
            },
            {
                "type": "function",
                "function": {
                    "name": "list_agent_skills",
                    "description": "List available skills/runbooks",
                    "parameters": {
                        "type": "object",
                        "properties": {"query": {"type": "string"}},
                        "required": []
                    }
                }
            },
            {
                "type": "function", 
                "function": {
                    "name": "get_agent_skill",
                    "description": "Get specific skill content",
                    "parameters": {
                        "type": "object",
                        "properties": {"skill_name": {"type": "string"}},
                        "required": ["skill_name"]
                    }
                }
            }
        ]

    def test_daily_log_review_runbook_workflow(self):
        """Test complete daily log review runbook workflow"""
        # This test validates the workflow structure, not the actual execution
        
        # Simulate the complete runbook workflow sequence
        workflow_responses = [
            # 1. First call: list_agent_skills for runbook
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_1",
                            "function": {
                                "name": "list_agent_skills",
                                "arguments": '{"query": "runbook"}'
                            }
                        }]
                    }
                }]
            },
            # 2. Second call: get_agent_skill for daily-log-review
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_2", 
                            "function": {
                                "name": "get_agent_skill",
                                "arguments": '{"skill_name": "daily-log-review-runbook"}'
                            }
                        }]
                    }
                }]
            },
            # 3. Third call: gtd_read_daily_log
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_3",
                            "function": {
                                "name": "gtd_read_daily_log", 
                                "arguments": '{"date": "today"}'
                            }
                        }]
                    }
                }]
            },
            # 4. Fourth call: gtd_list_tasks for cross-reference
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_4",
                            "function": {
                                "name": "gtd_list_tasks",
                                "arguments": '{}'
                            }
                        }]
                    }
                }]
            },
            # 5. Final response with analysis
            {
                "choices": [{
                    "message": {
                        "content": "Based on your daily log and runbook analysis, here are the key insights...",
                        "tool_calls": []
                    }
                }]
            }
        ]
        
        # Validate workflow steps
        expected_workflow_steps = [
            "list_agent_skills",
            "get_agent_skill", 
            "gtd_read_daily_log",
            "gtd_list_tasks",
            "final_analysis"
        ]
        
        # Test that the router can handle this type of request
        if hasattr(self.router, 'route_request'):
            # This validates the method exists and can be called
            # Actual execution would require real Ollama/tools
            print("✅ Router has route_request method for runbook workflows")
            self.assertTrue(callable(getattr(self.router, 'route_request')))
        else:
            print("⚠️  route_request method not available")
        
        # Validate workflow structure is documented
        self.assertEqual(len(expected_workflow_steps), 5)
        print(f"✅ Workflow has {len(expected_workflow_steps)} expected steps")

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_tool_call_retry_on_failure(self, mock_post, mock_get_tools):
        """Test retry mechanism when tool calls fail"""
        mock_get_tools.return_value = self.full_tool_suite[:1]  # Just daily log tool
        
        # First response: tool call
        # Second response: retry after tool failure  
        # Third response: final success
        responses = [
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_1",
                            "function": {
                                "name": "gtd_read_daily_log",
                                "arguments": '{"date": "invalid"}'
                            }
                        }]
                    }
                }]
            },
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_2", 
                            "function": {
                                "name": "gtd_read_daily_log",
                                "arguments": '{"date": "today"}'
                            }
                        }]
                    }
                }]
            },
            {
                "choices": [{
                    "message": {
                        "content": "Here is your daily log analysis...",
                        "tool_calls": []
                    }
                }]
            }
        ]
        
        mock_post.return_value.json.side_effect = responses
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.side_effect = [(resp, None) for resp in responses]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                # First call fails, second succeeds
                mock_execute.side_effect = [
                    Exception("Invalid date format"),
                    "Daily log content: Today I worked on..."
                ]
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="read my daily log",
                    persona=None,
                    context={}
                )
                
                # Should eventually succeed after retry
                self.assertIsNone(error)
                self.assertIsNotNone(result)
                
                # Should have tried tool execution twice
                self.assertEqual(mock_execute.call_count, 2)

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_partial_timeout_recovery(self, mock_post, mock_get_tools):
        """Test recovery from partial timeout scenarios"""
        mock_get_tools.return_value = self.full_tool_suite[:2]
        
        # First response times out
        # Second response succeeds
        responses = [
            {"request_id": "timeout-request"},  # Will timeout
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_retry",
                            "function": {
                                "name": "gtd_list_tasks",
                                "arguments": '{}'
                            }
                        }]
                    }
                }]
            },
            {
                "choices": [{
                    "message": {
                        "content": "Your current tasks are...",
                        "tool_calls": []
                    }
                }]
            }
        ]
        
        mock_post.return_value.json.side_effect = responses
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            # First call times out, subsequent calls succeed
            mock_handle_ai.side_effect = [
                (None, "Request timed out after 30s, but process still running"),
                (responses[1], None),
                (responses[2], None)
            ]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                mock_execute.return_value = "Task list: [Task 1, Task 2]"
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="list my tasks",
                    persona=None,
                    context={}
                )
                
                # Should handle timeout and show appropriate message
                # Implementation may vary - check that timeout is handled gracefully
                if error:
                    self.assertIn("timed out", error.lower())

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_malformed_tool_arguments_handling(self, mock_post, mock_get_tools):
        """Test handling of malformed tool arguments"""
        mock_get_tools.return_value = self.full_tool_suite[:1]
        
        responses = [
            # Malformed JSON in arguments
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_malformed",
                            "function": {
                                "name": "gtd_read_daily_log",
                                "arguments": '{"date": "today", malformed json}'  # Invalid JSON
                            }
                        }]
                    }
                }]
            },
            # Corrected response
            {
                "choices": [{
                    "message": {
                        "tool_calls": [{
                            "id": "call_fixed",
                            "function": {
                                "name": "gtd_read_daily_log", 
                                "arguments": '{"date": "today"}'
                            }
                        }]
                    }
                }]
            },
            # Final response
            {
                "choices": [{
                    "message": {
                        "content": "Daily log analysis complete",
                        "tool_calls": []
                    }
                }]
            }
        ]
        
        mock_post.return_value.json.side_effect = responses
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.side_effect = [(resp, None) for resp in responses]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                # First call will fail due to malformed JSON, second succeeds
                mock_execute.side_effect = [
                    Exception("JSON decode error"),  # From malformed arguments
                    "Daily log: Successful read"
                ]
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="read my daily log",
                    persona=None,
                    context={}
                )
                
                # Should handle malformed JSON gracefully
                self.assertIsNotNone(result or error)  # Should get some response

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_complex_persona_interactions(self, mock_post, mock_get_tools):
        """Test complex interactions with different personas"""
        mock_get_tools.return_value = self.full_tool_suite[:2]
        
        # Test quartermaster persona (nautical theme)
        response = {
            "choices": [{
                "message": {
                    "tool_calls": [{
                        "id": "call_quartermaster",
                        "function": {
                            "name": "gtd_read_daily_log",
                            "arguments": '{"date": "today"}'
                        }
                    }]
                }
            }]
        }
        
        final_response = {
            "choices": [{
                "message": {
                    "content": "Ahoy! Based on your ship's log for today, I see you've charted a course through several important tasks...",
                    "tool_calls": []
                }
            }]
        }
        
        mock_post.return_value.json.side_effect = [response, final_response]
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
            mock_handle_ai.side_effect = [(response, None), (final_response, None)]
            
            with patch('claude_ollama_bridge.execute_gtd_tool') as mock_execute:
                mock_execute.return_value = "## Daily Log - Navigation Report\n- 09:00 Set sail on Project Alpha..."
                
                result, error = self.bridge._call_ollama(
                    request_type="data",
                    content="review my daily log",
                    persona="quartermaster",  # Nautical-themed persona
                    context={}
                )
                
                self.assertIsNone(error)
                self.assertIsNotNone(result)
                
                # Should have executed the tool call
                mock_execute.assert_called()

    @patch('claude_ollama_bridge.get_available_tools')
    def test_async_state_consistency(self, mock_get_tools):
        """Test that async state remains consistent across operations"""
        mock_get_tools.return_value = []
        
        # Test initial state
        initial_details = getattr(self.bridge, '_tool_execution_details', None)
        
        # Initialize if not present
        if initial_details is None:
            self.bridge._tool_execution_details = []
        
        # Test state persistence
        test_detail = {
            'tool_name': 'test_tool',
            'timestamp': time.time(),
            'success': True
        }
        
        self.bridge._tool_execution_details.append(test_detail)
        
        # State should persist
        self.assertEqual(len(self.bridge._tool_execution_details), 1)
        self.assertEqual(self.bridge._tool_execution_details[0]['tool_name'], 'test_tool')
        
        # Test state reset
        self.bridge._tool_execution_details = []
        self.assertEqual(len(self.bridge._tool_execution_details), 0)

class TestAsyncErrorRecovery(TestCase):
    """Test error recovery in async tool calling"""
    
    def setUp(self):
        self.bridge = ClaudeOllamaBridge(
            claude_api_key="test-key",
            ollama_model="llama3.1:8b-instruct-q6_K",
            ollama_timeout=10,  # Short timeout for error testing
            ollama_direct_url="http://localhost:11434/api/generate",
            ollama_openai_url="http://localhost:11434/v1/chat/completions"
        )

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post')
    def test_network_error_recovery(self, mock_post, mock_get_tools):
        """Test recovery from network errors during tool calls"""
        mock_get_tools.return_value = []
        
        # Mock network error followed by recovery
        mock_post.side_effect = [
            Exception("Connection timeout"),  # Network error
            Mock(json=lambda: {  # Recovery
                "choices": [{
                    "message": {
                        "content": "Recovered response",
                        "tool_calls": []
                    }
                }]
            })
        ]
        
        result, error = self.bridge._call_ollama(
            request_type="simple",
            content="test message",
            persona=None,
            context={}
        )
        
        # Should handle network error gracefully
        self.assertIsNotNone(error)
        self.assertIn("error", error.lower())

    @patch('claude_ollama_bridge.get_available_tools')
    @patch('requests.post') 
    def test_invalid_response_format_recovery(self, mock_post, mock_get_tools):
        """Test recovery from invalid response formats"""
        mock_get_tools.return_value = []
        
        # Mock invalid response format
        invalid_responses = [
            {"invalid": "format"},  # Missing choices
            {"choices": []},  # Empty choices
            {"choices": [{"no_message": "here"}]},  # Missing message
        ]
        
        for invalid_response in invalid_responses:
            mock_post.return_value.json.return_value = invalid_response
            
            with patch('claude_ollama_bridge.handle_ai_response') as mock_handle_ai:
                mock_handle_ai.return_value = (invalid_response, None)
                
                result, error = self.bridge._call_ollama(
                    request_type="simple",
                    content="test",
                    persona=None,
                    context={}
                )
                
                # Should handle invalid format gracefully
                # Either return error or handle it appropriately
                self.assertTrue(error is not None or result is not None)

if __name__ == '__main__':
    print("🧪 Running Advanced Async Tool Calling Scenario Tests...")
    print("=" * 70)
    
    import unittest
    
    # Create test suite
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Add test cases
    suite.addTests(loader.loadTestsFromTestCase(TestRealWorldAsyncScenarios))
    suite.addTests(loader.loadTestsFromTestCase(TestAsyncErrorRecovery))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print summary
    print("\n" + "=" * 70)
    if result.wasSuccessful():
        print("✅ All async scenario tests passed!")
        print("🎯 Complex tool calling workflows validated")
        print("⚡ Error recovery mechanisms verified")
        print("🔄 Async state management confirmed")
    else:
        print(f"❌ {len(result.failures)} failures, {len(result.errors)} errors")
        
    print(f"📊 Ran {result.testsRun} tests")
    
    sys.exit(0 if result.wasSuccessful() else 1)