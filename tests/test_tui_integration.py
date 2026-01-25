#!/usr/bin/env python3
"""
TUI Integration Testing Framework

This module provides automated testing capabilities for the claude-ask-interactive TUI,
including keypress simulation, state validation, and debugging support.
"""

import subprocess
import time
import json
import re
import threading
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
import pexpect
import pytest

@dataclass
class TUIState:
    """Represents the current state of the TUI"""
    current_screen: str
    status: str
    location: str
    message: str
    input_text: str
    active_command: Optional[str] = None
    error_messages: List[str] = None
    
    def __post_init__(self):
        if self.error_messages is None:
            self.error_messages = []

class TUITester:
    """Automated TUI testing framework"""
    
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.session: Optional[pexpect.spawn] = None
        self.debug_mode = False
        self.state_history: List[TUIState] = []
        
    def start_tui(self, command: str = "make claude-ask-interactive") -> bool:
        """Start the TUI and wait for it to be ready"""
        try:
            self.session = pexpect.spawn(command, timeout=self.timeout, cwd='/Users/abby/code/dotfiles')
            self.session.expect_exact("Type your question here", timeout=10)
            self._capture_state()
            return True
        except (pexpect.TIMEOUT, pexpect.EOF) as e:
            if self.debug_mode:
                print(f"Failed to start TUI: {e}")
            return False
    
    def stop_tui(self) -> None:
        """Gracefully stop the TUI"""
        if self.session:
            self.session.sendcontrol('c')
            self.session.close()
            self.session = None
    
    def send_keys(self, keys: str, expect_change: bool = True) -> bool:
        """Send keypresses to the TUI and optionally wait for state change"""
        if not self.session:
            return False
            
        try:
            # Record state before
            before_state = self._capture_state()
            
            # Send keys
            if keys == 'CTRL_J':
                self.session.sendcontrol('j')
            elif keys == 'CTRL_C':
                self.session.sendcontrol('c')
            elif keys == 'ESC':
                self.session.send('\x1b')
            elif keys == 'TAB':
                self.session.send('\t')
            else:
                self.session.send(keys)
            
            # Wait for change if expected
            if expect_change:
                time.sleep(0.5)  # Give TUI time to update
                after_state = self._capture_state()
                return before_state.current_screen != after_state.current_screen
                
            return True
            
        except (pexpect.TIMEOUT, pexpect.EOF):
            return False
    
    def type_message(self, message: str) -> bool:
        """Type a message in the input field"""
        return self.send_keys(message, expect_change=False)
    
    def send_message(self, message: str) -> bool:
        """Type message and send it"""
        if not self.type_message(message):
            return False
        return self.send_keys('CTRL_J', expect_change=True)
    
    def wait_for_response(self, timeout: int = 30) -> bool:
        """Wait for TUI to finish processing and show response"""
        start_time = time.time()
        
        while time.time() - start_time < timeout:
            state = self._capture_state()
            
            # Check if we're stuck in processing
            if "waiting for the response" in state.current_screen.lower():
                if time.time() - start_time > 10:  # Stuck for more than 10 seconds
                    return False
                    
            # Check if we have a completed response
            if "completed" in state.status.lower() and "waiting" not in state.current_screen.lower():
                return True
                
            time.sleep(1)
        
        return False
    
    def _capture_state(self) -> TUIState:
        """Capture the current TUI state"""
        if not self.session:
            return TUIState("", "", "", "", "")
        
        try:
            # Get current screen content
            screen = self.session.before.decode() if self.session.before else ""
            screen += self.session.after.decode() if self.session.after else ""
            
            # Parse TUI elements
            location = self._extract_location(screen)
            status = self._extract_status(screen)
            message = self._extract_message(screen)
            input_text = self._extract_input_text(screen)
            active_command = self._extract_active_command(screen)
            error_messages = self._extract_error_messages(screen)
            
            state = TUIState(
                current_screen=screen,
                status=status,
                location=location,
                message=message,
                input_text=input_text,
                active_command=active_command,
                error_messages=error_messages
            )
            
            self.state_history.append(state)
            return state
            
        except Exception as e:
            if self.debug_mode:
                print(f"Error capturing state: {e}")
            return TUIState("", "", "", "", "")
    
    def _extract_location(self, screen: str) -> str:
        """Extract location from TUI screen"""
        match = re.search(r'📍 Location: (.+)', screen)
        return match.group(1).strip() if match else ""
    
    def _extract_status(self, screen: str) -> str:
        """Extract status from TUI screen"""
        match = re.search(r'Status: (.+)', screen)
        return match.group(1).strip() if match else ""
    
    def _extract_message(self, screen: str) -> str:
        """Extract message from TUI screen"""
        match = re.search(r'Message: (.+)', screen)
        return match.group(1).strip() if match else ""
    
    def _extract_input_text(self, screen: str) -> str:
        """Extract current input text"""
        # This would need to be implemented based on TUI structure
        return ""
    
    def _extract_active_command(self, screen: str) -> Optional[str]:
        """Extract active command from screen"""
        match = re.search(r'📜 Executing: (.+)', screen)
        return match.group(1).strip() if match else None
    
    def _extract_error_messages(self, screen: str) -> List[str]:
        """Extract any error messages"""
        # Look for error patterns
        errors = []
        error_patterns = [
            r'❌ (.+)',
            r'Error: (.+)',
            r'Failed: (.+)',
        ]
        
        for pattern in error_patterns:
            matches = re.findall(pattern, screen)
            errors.extend(matches)
        
        return errors
    
    def validate_tui_health(self) -> Dict[str, Any]:
        """Comprehensive TUI health check"""
        health_report = {
            'tui_responsive': False,
            'ollama_connected': False,
            'advice_worker_functional': False,
            'async_handling_ok': False,
            'stuck_processes': [],
            'error_messages': [],
            'recommendations': []
        }
        
        try:
            # Test TUI responsiveness
            if self.session and self.send_keys('', expect_change=False):
                health_report['tui_responsive'] = True
            
            # Check for stuck processes
            state = self._capture_state()
            if state.active_command and "request-status" in state.active_command:
                # Check if it's been stuck for too long
                stuck_duration = self._check_stuck_duration(state.active_command)
                if stuck_duration > 30:  # 30 seconds
                    health_report['stuck_processes'].append({
                        'command': state.active_command,
                        'duration': stuck_duration
                    })
            
            # Check async handling
            if "waiting for the response" in state.current_screen.lower() and "completed" in state.status.lower():
                health_report['async_handling_ok'] = False
                health_report['error_messages'].append("Inconsistent async state: completed but waiting")
            else:
                health_report['async_handling_ok'] = True
            
            # Add recommendations
            if not health_report['tui_responsive']:
                health_report['recommendations'].append("Restart TUI with Ctrl+C and 'make claude-ask-interactive'")
            
            if health_report['stuck_processes']:
                health_report['recommendations'].append("Kill stuck processes and restart")
            
            if not health_report['async_handling_ok']:
                health_report['recommendations'].append("Check Ollama Controller async response handling")
            
        except Exception as e:
            health_report['error_messages'].append(f"Health check failed: {e}")
        
        return health_report
    
    def _check_stuck_duration(self, command: str) -> int:
        """Check how long a command has been stuck"""
        # This would check process timestamps - simplified for now
        return 60  # Assume stuck if we detect stuck command
    
    def export_debug_info(self, filepath: str) -> None:
        """Export comprehensive debug information"""
        debug_info = {
            'timestamp': time.time(),
            'state_history': [
                {
                    'screen': state.current_screen,
                    'status': state.status,
                    'location': state.location,
                    'message': state.message,
                    'active_command': state.active_command,
                    'errors': state.error_messages
                }
                for state in self.state_history
            ],
            'health_report': self.validate_tui_health()
        }
        
        with open(filepath, 'w') as f:
            json.dump(debug_info, f, indent=2)

# Test Cases
class TestTUIIntegration:
    """Test suite for TUI integration"""
    
    def setup_method(self):
        self.tester = TUITester()
        self.tester.debug_mode = True
    
    def teardown_method(self):
        if self.tester:
            self.tester.stop_tui()
    
    def test_tui_startup(self):
        """Test TUI starts successfully"""
        assert self.tester.start_tui(), "TUI should start successfully"
    
    def test_tui_responsiveness(self):
        """Test TUI responds to input"""
        self.tester.start_tui()
        assert self.tester.send_keys('test'), "TUI should respond to input"
    
    def test_message_sending(self):
        """Test sending a message works"""
        self.tester.start_tui()
        assert self.tester.send_message('hello'), "Should be able to send message"
        assert self.tester.wait_for_response(timeout=60), "Should receive response"
    
    def test_health_validation(self):
        """Test TUI health validation"""
        self.tester.start_tui()
        health = self.tester.validate_tui_health()
        assert health['tui_responsive'], "TUI should be responsive"
        assert len(health['error_messages']) == 0, f"Should have no errors: {health['error_messages']}"
    
    def test_async_response_handling(self):
        """Test async response handling doesn't get stuck"""
        self.tester.start_tui()
        self.tester.send_message('test async handling')
        
        # Wait and check for stuck state
        time.sleep(5)
        state = self.tester._capture_state()
        
        # Should not be both completed and waiting
        assert not (
            "completed" in state.status.lower() and 
            "waiting for the response" in state.current_screen.lower()
        ), "Should not have inconsistent async state"

if __name__ == '__main__':
    # Quick test run
    tester = TUITester()
    tester.debug_mode = True
    
    print("🧪 Starting TUI Integration Test...")
    
    if tester.start_tui():
        print("✅ TUI started successfully")
        
        health = tester.validate_tui_health()
        print(f"📊 Health Report: {json.dumps(health, indent=2)}")
        
        # Export debug info
        debug_file = "/tmp/tui_debug_info.json"
        tester.export_debug_info(debug_file)
        print(f"📁 Debug info exported to: {debug_file}")
        
        tester.stop_tui()
    else:
        print("❌ Failed to start TUI")