#!/usr/bin/env python3
"""
Runbook Session Persistence System

Allows interactive runbooks to be paused, resumed, and tracked across sessions.
Saves progress, user inputs, and step completion state.
"""

import json
import time
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
import hashlib

class RunbookSession:
    """Manages persistent state for interactive runbooks"""
    
    def __init__(self, session_dir: Optional[str] = None):
        """Initialize session manager"""
        if session_dir:
            self.session_dir = Path(session_dir)
        else:
            self.session_dir = Path.home() / "Documents" / "gtd" / ".sessions"
        
        self.session_dir.mkdir(parents=True, exist_ok=True)
        self.active_sessions_file = self.session_dir / "active_sessions.json"
    
    def create_session(self, runbook_name: str, persona: Optional[str] = None, 
                      user_context: Optional[Dict[str, Any]] = None) -> str:
        """Create a new runbook session"""
        session_id = str(uuid.uuid4())[:8]  # Short ID
        timestamp = datetime.now().isoformat()
        
        session_data = {
            'session_id': session_id,
            'runbook_name': runbook_name,
            'persona': persona,
            'created_at': timestamp,
            'last_active': timestamp,
            'current_step': 0,
            'total_steps': None,  # Will be set when runbook structure is known
            'status': 'active',
            'user_context': user_context or {},
            'step_history': [],
            'user_inputs': {},
            'completed_steps': [],
            'step_data': {},  # Store data from each step
            'session_notes': [],
            'resume_point': None
        }
        
        # Save session file
        session_file = self.session_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        # Update active sessions index
        self._update_active_sessions(session_id, runbook_name, timestamp)
        
        print(f"📋 Created session {session_id} for '{runbook_name}'")
        return session_id
    
    def save_session_state(self, session_id: str, step_num: int, 
                          step_name: str, user_inputs: Dict[str, Any] = None,
                          step_data: Dict[str, Any] = None) -> None:
        """Save current session state"""
        session_data = self.load_session(session_id)
        if not session_data:
            return
        
        timestamp = datetime.now().isoformat()
        
        # Update session state
        session_data['current_step'] = step_num
        session_data['last_active'] = timestamp
        session_data['resume_point'] = step_name
        
        # Save step completion
        if step_num not in session_data['completed_steps']:
            session_data['completed_steps'].append(step_num)
        
        # Save user inputs for this step
        if user_inputs:
            session_data['user_inputs'][str(step_num)] = user_inputs
        
        # Save step-specific data
        if step_data:
            session_data['step_data'][str(step_num)] = step_data
        
        # Add to step history
        session_data['step_history'].append({
            'step_num': step_num,
            'step_name': step_name,
            'timestamp': timestamp,
            'inputs': user_inputs,
            'data': step_data
        })
        
        # Save to file
        session_file = self.session_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        print(f"💾 Saved session {session_id} at step {step_num}: {step_name}")
    
    def load_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Load session data"""
        session_file = self.session_dir / f"{session_id}.json"
        if not session_file.exists():
            return None
        
        try:
            with open(session_file, 'r') as f:
                return json.load(f)
        except Exception as e:
            print(f"❌ Error loading session {session_id}: {e}")
            return None
    
    def get_resume_info(self, session_id: str) -> Optional[Dict[str, Any]]:
        """Get information needed to resume a session"""
        session_data = self.load_session(session_id)
        if not session_data:
            return None
        
        resume_info = {
            'session_id': session_id,
            'runbook_name': session_data['runbook_name'],
            'persona': session_data.get('persona'),
            'current_step': session_data['current_step'],
            'resume_point': session_data.get('resume_point'),
            'completed_steps': session_data['completed_steps'],
            'user_inputs': session_data['user_inputs'],
            'step_data': session_data['step_data'],
            'last_active': session_data['last_active'],
            'progress_percentage': self._calculate_progress(session_data)
        }
        
        return resume_info
    
    def list_active_sessions(self) -> List[Dict[str, Any]]:
        """List all active sessions"""
        try:
            if not self.active_sessions_file.exists():
                return []
            
            with open(self.active_sessions_file, 'r') as f:
                sessions = json.load(f)
            
            # Filter out old sessions (older than 7 days)
            cutoff_date = datetime.now() - timedelta(days=7)
            active_sessions = []
            
            for session in sessions:
                last_active = datetime.fromisoformat(session['last_active'])
                if last_active > cutoff_date:
                    # Add progress info
                    session_data = self.load_session(session['session_id'])
                    if session_data:
                        session['progress'] = self._calculate_progress(session_data)
                        session['current_step'] = session_data['current_step']
                        session['resume_point'] = session_data.get('resume_point')
                        active_sessions.append(session)
            
            return active_sessions
        except Exception:
            return []
    
    def complete_session(self, session_id: str) -> None:
        """Mark session as completed"""
        session_data = self.load_session(session_id)
        if not session_data:
            return
        
        session_data['status'] = 'completed'
        session_data['completed_at'] = datetime.now().isoformat()
        
        # Save final state
        session_file = self.session_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        # Remove from active sessions
        self._remove_from_active_sessions(session_id)
        
        print(f"✅ Completed session {session_id}")
    
    def abandon_session(self, session_id: str) -> None:
        """Mark session as abandoned"""
        session_data = self.load_session(session_id)
        if not session_data:
            return
        
        session_data['status'] = 'abandoned'
        session_data['abandoned_at'] = datetime.now().isoformat()
        
        # Save final state
        session_file = self.session_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        # Remove from active sessions
        self._remove_from_active_sessions(session_id)
        
        print(f"🗑️ Abandoned session {session_id}")
    
    def add_session_note(self, session_id: str, note: str) -> None:
        """Add a note to the session"""
        session_data = self.load_session(session_id)
        if not session_data:
            return
        
        session_data['session_notes'].append({
            'timestamp': datetime.now().isoformat(),
            'note': note
        })
        
        session_file = self.session_dir / f"{session_id}.json"
        with open(session_file, 'w') as f:
            json.dump(session_data, f, indent=2, default=str)
        
        print(f"📝 Added note to session {session_id}")
    
    def get_session_summary(self, session_id: str) -> str:
        """Get a human-readable session summary"""
        session_data = self.load_session(session_id)
        if not session_data:
            return f"Session {session_id} not found"
        
        summary = []
        summary.append(f"📋 **Session {session_id}**")
        summary.append(f"   Runbook: {session_data['runbook_name']}")
        if session_data.get('persona'):
            summary.append(f"   Persona: {session_data['persona']}")
        
        progress = self._calculate_progress(session_data)
        summary.append(f"   Progress: {progress:.1f}%")
        summary.append(f"   Current Step: {session_data['current_step']}")
        if session_data.get('resume_point'):
            summary.append(f"   Resume Point: {session_data['resume_point']}")
        
        # Time info
        created = datetime.fromisoformat(session_data['created_at'])
        last_active = datetime.fromisoformat(session_data['last_active'])
        summary.append(f"   Created: {created.strftime('%Y-%m-%d %H:%M')}")
        summary.append(f"   Last Active: {last_active.strftime('%Y-%m-%d %H:%M')}")
        
        # Step history
        if session_data['step_history']:
            summary.append(f"   Steps Completed: {len(session_data['completed_steps'])}")
            summary.append("   Recent Steps:")
            for step in session_data['step_history'][-3:]:
                timestamp = datetime.fromisoformat(step['timestamp'])
                summary.append(f"     • {step['step_name']} ({timestamp.strftime('%H:%M')})")
        
        return "\n".join(summary)
    
    def cleanup_old_sessions(self, days: int = 30) -> int:
        """Clean up sessions older than specified days"""
        cutoff_date = datetime.now() - timedelta(days=days)
        cleaned_count = 0
        
        for session_file in self.session_dir.glob("*.json"):
            if session_file.name == "active_sessions.json":
                continue
            
            try:
                with open(session_file, 'r') as f:
                    session_data = json.load(f)
                
                last_active = datetime.fromisoformat(session_data['last_active'])
                if last_active < cutoff_date and session_data.get('status') != 'active':
                    session_file.unlink()
                    cleaned_count += 1
            except Exception:
                continue
        
        return cleaned_count
    
    def _calculate_progress(self, session_data: Dict[str, Any]) -> float:
        """Calculate session progress percentage"""
        if not session_data.get('total_steps'):
            # Estimate based on completed steps
            completed = len(session_data['completed_steps'])
            if completed == 0:
                return 0.0
            # Rough estimate assuming average runbook has 5-10 steps
            estimated_total = max(completed + 3, 8)
            return min(completed / estimated_total * 100, 95.0)  # Cap at 95% if estimating
        
        completed = len(session_data['completed_steps'])
        total = session_data['total_steps']
        return (completed / total * 100) if total > 0 else 0.0
    
    def _update_active_sessions(self, session_id: str, runbook_name: str, timestamp: str) -> None:
        """Update the active sessions index"""
        sessions = []
        if self.active_sessions_file.exists():
            try:
                with open(self.active_sessions_file, 'r') as f:
                    sessions = json.load(f)
            except Exception:
                sessions = []
        
        # Add or update session
        session_entry = {
            'session_id': session_id,
            'runbook_name': runbook_name,
            'last_active': timestamp
        }
        
        # Remove existing entry if present
        sessions = [s for s in sessions if s['session_id'] != session_id]
        sessions.append(session_entry)
        
        # Keep only recent sessions (last 20)
        sessions = sorted(sessions, key=lambda x: x['last_active'], reverse=True)[:20]
        
        with open(self.active_sessions_file, 'w') as f:
            json.dump(sessions, f, indent=2)
    
    def _remove_from_active_sessions(self, session_id: str) -> None:
        """Remove session from active sessions index"""
        if not self.active_sessions_file.exists():
            return
        
        try:
            with open(self.active_sessions_file, 'r') as f:
                sessions = json.load(f)
            
            sessions = [s for s in sessions if s['session_id'] != session_id]
            
            with open(self.active_sessions_file, 'w') as f:
                json.dump(sessions, f, indent=2)
        except Exception:
            pass

def create_session(runbook_name: str, persona: str = None, context: Dict[str, Any] = None) -> str:
    """Convenience function to create a session"""
    manager = RunbookSession()
    return manager.create_session(runbook_name, persona, context)

def save_progress(session_id: str, step_num: int, step_name: str, 
                 inputs: Dict[str, Any] = None, data: Dict[str, Any] = None) -> None:
    """Convenience function to save progress"""
    manager = RunbookSession()
    manager.save_session_state(session_id, step_num, step_name, inputs, data)

def list_sessions() -> List[Dict[str, Any]]:
    """Convenience function to list active sessions"""
    manager = RunbookSession()
    return manager.list_active_sessions()

def get_resume_info(session_id: str) -> Optional[Dict[str, Any]]:
    """Convenience function to get resume information"""
    manager = RunbookSession()
    return manager.get_resume_info(session_id)

if __name__ == '__main__':
    # Command line interface
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python runbook_sessions.py <command> [args...]")
        print("Commands: list, create, resume, complete, abandon, summary, cleanup")
        sys.exit(1)
    
    command = sys.argv[1]
    manager = RunbookSession()
    
    if command == 'list':
        sessions = manager.list_active_sessions()
        if not sessions:
            print("No active sessions found")
        else:
            print(f"Active Sessions ({len(sessions)}):")
            for session in sessions:
                print(f"  {session['session_id']}: {session['runbook_name']} "
                      f"({session['progress']:.1f}% complete)")
    
    elif command == 'create':
        if len(sys.argv) < 3:
            print("Usage: python runbook_sessions.py create <runbook_name> [persona]")
            sys.exit(1)
        
        runbook_name = sys.argv[2]
        persona = sys.argv[3] if len(sys.argv) > 3 else None
        session_id = manager.create_session(runbook_name, persona)
        print(f"Created session: {session_id}")
    
    elif command == 'resume':
        if len(sys.argv) < 3:
            print("Usage: python runbook_sessions.py resume <session_id>")
            sys.exit(1)
        
        session_id = sys.argv[2]
        resume_info = manager.get_resume_info(session_id)
        if resume_info:
            print(f"Resume info for {session_id}:")
            print(json.dumps(resume_info, indent=2, default=str))
        else:
            print(f"Session {session_id} not found")
    
    elif command == 'summary':
        if len(sys.argv) < 3:
            print("Usage: python runbook_sessions.py summary <session_id>")
            sys.exit(1)
        
        session_id = sys.argv[2]
        summary = manager.get_session_summary(session_id)
        print(summary)
    
    elif command == 'complete':
        if len(sys.argv) < 3:
            print("Usage: python runbook_sessions.py complete <session_id>")
            sys.exit(1)
        
        session_id = sys.argv[2]
        manager.complete_session(session_id)
    
    elif command == 'abandon':
        if len(sys.argv) < 3:
            print("Usage: python runbook_sessions.py abandon <session_id>")
            sys.exit(1)
        
        session_id = sys.argv[2]
        manager.abandon_session(session_id)
    
    elif command == 'cleanup':
        days = int(sys.argv[2]) if len(sys.argv) > 2 else 30
        cleaned = manager.cleanup_old_sessions(days)
        print(f"Cleaned up {cleaned} old sessions")
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)