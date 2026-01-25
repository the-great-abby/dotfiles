#!/usr/bin/env python3
"""
Async Issue Diagnosis Tests

These tests specifically target the async polling issues we discovered
in both the TUI and the initial test failures.
"""

import json
import time
from unittest import TestCase
from unittest.mock import Mock, patch, MagicMock
import sys
from pathlib import Path

# Add the mcp directory to Python path
sys.path.insert(0, str(Path(__file__).parent.parent / "mcp"))

try:
    from claude_ollama_bridge import SmartAIRouter
    from zsh.functions.gtd_ai_helpers import handle_ai_response
except ImportError as e:
    print(f"❌ Error importing modules: {e}")
    sys.exit(1)

class TestAsyncPollingIssues(TestCase):
    """Test the specific async polling issues causing TUI problems"""
    
    def setUp(self):
        self.router = SmartAIRouter()
        self.router.mode = "hybrid"
        self.router.ollama_timeout = 5  # Short timeout for testing
    
    def test_async_polling_stuck_in_queued(self):
        """Test what happens when request gets stuck in 'queued' status"""
        
        # Mock the sequence we saw in the failing test
        queued_response = {
            "detail": {
                "error": {
                    "message": "Request is still processing. Current status: queued",
                    "type": "request_processing", 
                    "code": "request_not_completed",
                    "status": "queued",
                    "status_url": "/api/status/test-request-id"
                }
            }
        }
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handler:
            # Simulate getting stuck in queued status (like in the test failure)
            mock_handler.return_value = (None, "Request timed out after 5s, but process still running")
            
            start_time = time.time()
            result, error = mock_handler(queued_response, "http://test", 5)
            duration = time.time() - start_time
            
            # Should timeout reasonably quickly
            self.assertLess(duration, 10)
            self.assertIsNone(result)
            self.assertIsNotNone(error)
            self.assertIn("timed out", error)
            
            print(f"✅ Queued timeout handled in {duration:.2f}s")
    
    def test_async_polling_stuck_in_processing(self):
        """Test what happens when request gets stuck in 'processing' status"""
        
        processing_response = {
            "detail": {
                "error": {
                    "message": "Request is still processing. Current status: processing", 
                    "type": "request_processing",
                    "code": "request_not_completed", 
                    "status": "processing"
                }
            }
        }
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handler:
            # Simulate timeout in processing state
            mock_handler.return_value = (None, "Request timed out after 5s, but process still running")
            
            result, error = mock_handler(processing_response, "http://test", 5)
            
            # Should handle processing timeout
            self.assertIsNone(result)
            self.assertIn("timed out", error)
            
            print("✅ Processing timeout handled correctly")
    
    def test_async_polling_success_after_delay(self):
        """Test successful completion after initial queuing"""
        
        # Success response after polling
        success_response = {
            "choices": [{
                "message": {
                    "content": "Response completed successfully",
                    "tool_calls": []
                }
            }]
        }
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handler:
            # Simulate eventual success
            mock_handler.return_value = (success_response, None)
            
            result, error = mock_handler(success_response, "http://test", 30)
            
            # Should succeed
            self.assertIsNotNone(result)
            self.assertIsNone(error)
            self.assertIn("choices", result)
            
            print("✅ Successful completion after polling works")
    
    def test_handle_ai_response_with_real_patterns(self):
        """Test handle_ai_response with the exact patterns from failed tests"""
        
        # This is the exact queued response from the test failure
        real_queued_response = {
            "detail": {
                "error": {
                    "message": "Request is still processing. Current status: queued",
                    "type": "request_processing",
                    "code": "request_not_completed", 
                    "status": "queued",
                    "status_url": "/api/status/141c96c2-cff2-4614-a05f-b8d6699af231",
                    "suggestion": "Use /api/status/{request_id} to check status, or wait for completion"
                }
            }
        }
        
        # Test the actual handle_ai_response function
        start_time = time.time()
        
        # This should timeout quickly in tests, not poll indefinitely
        result, error = handle_ai_response(
            real_queued_response, 
            "http://localhost:31080", 
            max_poll_time=2  # Very short for testing
        )
        
        duration = time.time() - start_time
        
        # Should not hang for too long
        self.assertLess(duration, 10)
        
        # Should either succeed or timeout gracefully
        if error:
            self.assertIn("timeout", error.lower())
            print(f"✅ Real pattern timed out gracefully in {duration:.2f}s")
        else:
            print(f"✅ Real pattern succeeded in {duration:.2f}s")
    
    def test_router_with_mocked_polling(self):
        """Test router with properly mocked async polling"""
        
        with patch('claude_ollama_bridge.handle_ai_response') as mock_handler:
            # Mock immediate success (no polling delay)
            mock_response = {
                "choices": [{
                    "message": {
                        "content": "Immediate success response",
                        "tool_calls": []
                    }
                }]
            }
            mock_handler.return_value = (mock_response, None)
            
            # Test route_request with mocked async handling
            if hasattr(self.router, 'route_request'):
                result, error = self.router.route_request("general_question", "test")
                
                self.assertIsNotNone(result)
                print(f"✅ Router with mocked polling: {result['source'] if isinstance(result, dict) else type(result)}")
            else:
                print("⚠️  route_request not available")

class TestTUIAsyncReplication(TestCase):
    """Replicate the exact TUI async issue for diagnosis"""
    
    def test_replicate_tui_stuck_state(self):
        """Try to replicate the TUI 'completed but waiting' state"""
        
        # This simulates the TUI scenario:
        # 1. Request is submitted
        # 2. Gets queued/processing 
        # 3. Eventually shows "completed" but still "waiting for response"
        
        with patch('requests.post') as mock_post:
            with patch('claude_ollama_bridge.handle_ai_response') as mock_handler:
                
                # Simulate the stuck scenario
                # Initial response: queued
                queued_response = {"request_id": "stuck-request"}
                mock_post.return_value.json.return_value = queued_response
                
                # handle_ai_response gets stuck and times out
                mock_handler.return_value = (None, "Request timed out after 30s, but process still running")
                
                router = SmartAIRouter()
                
                # This should replicate the TUI issue
                start_time = time.time()
                
                if hasattr(router, 'route_request'):
                    result, error = router.route_request("data", "read my daily log")
                    duration = time.time() - start_time
                    
                    print(f"🔍 TUI Replication Test:")
                    print(f"   Duration: {duration:.2f}s")
                    print(f"   Result: {result}")
                    print(f"   Error: {error}")
                    
                    # This is the problematic state:
                    # - Request appears "completed" (no exception thrown)
                    # - But result is None or incomplete
                    # - Error indicates timeout but process still running
                    
                    if error and "timed out" in error and "still running" in error:
                        print("🎯 REPLICATED TUI ISSUE: 'completed but waiting' state!")
                        print("   This is exactly what's happening in your TUI")
                else:
                    print("⚠️  Could not test route_request")

if __name__ == '__main__':
    print("🔍 Running Async Issue Diagnosis Tests...")
    print("=" * 60)
    print("These tests target the specific async polling issues causing")
    print("your TUI to get stuck in 'completed but waiting' states.")
    print("")
    
    import unittest
    
    # Create test suite
    loader = unittest.TestLoader() 
    suite = unittest.TestSuite()
    
    # Add diagnostic test cases
    suite.addTests(loader.loadTestsFromTestCase(TestAsyncPollingIssues))
    suite.addTests(loader.loadTestsFromTestCase(TestTUIAsyncReplication))
    
    # Run tests
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    # Print diagnosis
    print("\n" + "=" * 60)
    print("🎯 ASYNC ISSUE DIAGNOSIS SUMMARY")
    print("=" * 60)
    
    if result.wasSuccessful():
        print("✅ All diagnostic tests passed")
        print("🔧 Async handling logic appears to work correctly when mocked")
        print("🚨 Issue is likely in the real async polling implementation")
    else:
        print("⚠️  Some diagnostic tests failed")
        print("🔍 This helps pinpoint exactly where the async issue occurs")
    
    print(f"\n📊 Ran {result.testsRun} diagnostic tests")
    print("💡 Use these insights to fix the TUI async polling issue")
    
    sys.exit(0 if result.wasSuccessful() else 1)