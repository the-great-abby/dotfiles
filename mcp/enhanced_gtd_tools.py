#!/usr/bin/env python3
"""
Enhanced GTD Tools with Built-in Coordination

This module provides enhanced versions of GTD tools that include built-in
duplicate prevention and coordination between TUI and background workers.
"""

import sys
import json
from pathlib import Path
from typing import Optional, Dict, Any, List
from datetime import datetime

# Add coordination system to path
sys.path.insert(0, str(Path(__file__).parent))
from gtd_coordination import GTDCoordination, prevent_duplicate_processing, with_operation_lock

# Import original tool registry
sys.path.insert(0, str(Path.home() / "code" / "dotfiles" / "zsh" / "functions"))
from gtd_tool_registry import _gtd_create_task_handler as original_create_task

class EnhancedGTDTools:
    """Enhanced GTD tools with coordination and duplicate prevention."""
    
    def __init__(self, source: str = "unknown"):
        self.source = source
        self.coordination = GTDCoordination(source)
    
    def create_task_safe(self, title: str, project: Optional[str] = None, 
                        context: str = "computer", priority: str = "not_urgent_important",
                        notes: Optional[str] = None, source_reference: Optional[str] = None) -> Dict[str, Any]:
        """Create a task with duplicate prevention.
        
        Args:
            title: Task title
            project: Project name
            context: Task context
            priority: Task priority
            notes: Task notes
            source_reference: Reference to source (daily log entry, meeting, etc.)
            
        Returns:
            Dict with creation result and duplicate info
        """
        # Create a unique identifier for this task creation attempt
        task_signature = f"{title}|{project or 'none'}|{context}"
        
        # Check if we recently created a very similar task
        if self._is_duplicate_task(title, project, context):
            return {
                "status": "duplicate_detected",
                "message": f"Similar task already exists: {title}",
                "created": False
            }
        
        # Acquire lock for task creation in this context/project
        lock_resource = f"{project or 'inbox'}_{context}"
        
        if not self.coordination.acquire_operation_lock("task_creation", lock_resource, timeout=5.0):
            return {
                "status": "lock_timeout",
                "message": f"Could not acquire lock for task creation in {lock_resource}",
                "created": False
            }
        
        try:
            # Call original task creation
            result = original_create_task(title, project, context, priority, notes)
            
            # Track the created task
            self._track_created_task(title, project, context, source_reference)
            
            # Mark this specific task signature as processed
            self.coordination.mark_content_processed(
                task_signature, 
                "task_creation", 
                "task",
                {"title": title, "project": project, "context": context}
            )
            
            return {
                "status": "created",
                "message": result,
                "created": True,
                "source": self.source
            }
            
        finally:
            self.coordination.release_operation_lock("task_creation", lock_resource)
    
    def process_daily_log_safe(self, log_content: str, date: str) -> Dict[str, Any]:
        """Process daily log for task creation with duplicate prevention.
        
        Args:
            log_content: Content of the daily log
            date: Date of the log (YYYY-MM-DD format)
            
        Returns:
            Processing results with duplicate prevention info
        """
        # Check if this exact log content was already processed
        if self.coordination.is_content_processed(log_content, "auto_task_creation", "daily_log"):
            return {
                "status": "already_processed",
                "message": f"Daily log for {date} already processed for task creation",
                "tasks_created": 0
            }
        
        # Acquire lock for daily log processing
        if not self.coordination.acquire_operation_lock("log_processing", date):
            return {
                "status": "lock_timeout", 
                "message": f"Another process is already processing daily log for {date}",
                "tasks_created": 0
            }
        
        try:
            # Extract actionable items (simplified version)
            actionable_items = self._extract_actionable_items(log_content)
            created_tasks = []
            
            for item in actionable_items:
                # Check if we already created a task for this specific item
                item_signature = f"log_item_{date}_{hash(item['text'])}"
                
                if not self.coordination.is_content_processed(item_signature, "task_creation", "log_item"):
                    result = self.create_task_safe(
                        title=item['title'],
                        project=item.get('project'),
                        context=item.get('context', 'computer'),
                        priority=item.get('priority', 'not_urgent_important'),
                        notes=f"From daily log {date}: {item['text']}",
                        source_reference=f"daily_log_{date}"
                    )
                    
                    if result['created']:
                        created_tasks.append(result)
                        # Mark this log item as processed
                        self.coordination.mark_content_processed(
                            item_signature, "task_creation", "log_item"
                        )
            
            # Mark entire log as processed for task creation
            self.coordination.mark_content_processed(
                log_content, "auto_task_creation", "daily_log",
                {"date": date, "tasks_created": len(created_tasks)}
            )
            
            return {
                "status": "completed",
                "message": f"Processed daily log {date}",
                "tasks_created": len(created_tasks),
                "tasks": created_tasks
            }
            
        finally:
            self.coordination.release_operation_lock("log_processing", date)
    
    def process_meeting_notes_safe(self, meeting_content: str, meeting_id: str) -> Dict[str, Any]:
        """Process meeting notes for follow-up tasks with duplicate prevention."""
        
        if self.coordination.is_content_processed(meeting_content, "meeting_followup", "meeting_notes"):
            return {
                "status": "already_processed",
                "message": f"Meeting {meeting_id} already processed for follow-up tasks",
                "tasks_created": 0
            }
        
        if not self.coordination.acquire_operation_lock("meeting_processing", meeting_id):
            return {
                "status": "lock_timeout",
                "message": f"Another process is already processing meeting {meeting_id}",
                "tasks_created": 0
            }
        
        try:
            # Extract follow-up items from meeting notes
            followup_items = self._extract_meeting_followups(meeting_content)
            created_tasks = []
            
            for item in followup_items:
                result = self.create_task_safe(
                    title=item['title'],
                    project=item.get('project'),
                    context=item.get('context', 'calls'),
                    priority=item.get('priority', 'not_urgent_important'),
                    notes=f"From meeting {meeting_id}: {item['description']}",
                    source_reference=f"meeting_{meeting_id}"
                )
                
                if result['created']:
                    created_tasks.append(result)
            
            # Mark meeting as processed
            self.coordination.mark_content_processed(
                meeting_content, "meeting_followup", "meeting_notes",
                {"meeting_id": meeting_id, "tasks_created": len(created_tasks)}
            )
            
            return {
                "status": "completed",
                "message": f"Processed meeting {meeting_id}",
                "tasks_created": len(created_tasks),
                "tasks": created_tasks
            }
            
        finally:
            self.coordination.release_operation_lock("meeting_processing", meeting_id)
    
    def _is_duplicate_task(self, title: str, project: Optional[str], context: str) -> bool:
        """Check if a similar task already exists."""
        # This would integrate with your actual task storage system
        # For now, just check recent task creation tracking
        
        task_signature = f"{title}|{project or 'none'}|{context}"
        
        # Check if we created this exact task recently (within last hour)
        return self.coordination.is_content_processed(task_signature, "task_creation", "task")
    
    def _track_created_task(self, title: str, project: Optional[str], context: str, source_ref: Optional[str]):
        """Track a created task for duplicate detection."""
        # Store in coordination system's sources directory
        task_record = {
            "title": title,
            "project": project,
            "context": context,
            "source": self.source,
            "source_reference": source_ref,
            "created_at": datetime.now().isoformat()
        }
        
        # Save to sources directory for tracking
        sources_file = Path.home() / "Documents" / "gtd" / ".coordination" / "sources" / f"tasks_{datetime.now().strftime('%Y%m%d')}.jsonl"
        
        try:
            with open(sources_file, 'a') as f:
                f.write(json.dumps(task_record) + '\n')
        except Exception as e:
            print(f"⚠️  Error tracking created task: {e}")
    
    def _extract_actionable_items(self, log_content: str) -> List[Dict[str, Any]]:
        """Extract actionable items from daily log content."""
        # Simplified extraction logic - you'd want more sophisticated NLP here
        actionable_items = []
        
        lines = log_content.split('\n')
        for line in lines:
            line = line.strip()
            
            # Look for common action patterns
            action_patterns = [
                "need to ", "should ", "must ", "have to ",
                "follow up", "call ", "email ", "contact ",
                "research ", "look into ", "find out ",
                "schedule ", "book ", "arrange "
            ]
            
            for pattern in action_patterns:
                if pattern in line.lower():
                    # Extract potential task
                    title = self._extract_task_title(line, pattern)
                    if title:
                        actionable_items.append({
                            "title": title,
                            "text": line,
                            "context": self._infer_context(line),
                            "priority": self._infer_priority(line),
                            "project": self._infer_project(line)
                        })
                    break
        
        return actionable_items
    
    def _extract_meeting_followups(self, meeting_content: str) -> List[Dict[str, Any]]:
        """Extract follow-up items from meeting content."""
        # Simplified meeting followup extraction
        followups = []
        
        lines = meeting_content.split('\n')
        for line in lines:
            line = line.strip()
            
            if any(word in line.lower() for word in ["action:", "todo:", "follow up:", "next steps:"]):
                title = line.split(':', 1)[-1].strip() if ':' in line else line
                if title:
                    followups.append({
                        "title": title,
                        "description": line,
                        "context": "calls",
                        "priority": "urgent_important"
                    })
        
        return followups
    
    def _extract_task_title(self, line: str, pattern: str) -> Optional[str]:
        """Extract a clean task title from a line containing an action pattern."""
        # Find the action pattern and extract what follows
        lower_line = line.lower()
        pattern_pos = lower_line.find(pattern)
        if pattern_pos >= 0:
            title_start = pattern_pos + len(pattern)
            title = line[title_start:].strip()
            
            # Clean up the title
            if title.endswith('.'):
                title = title[:-1]
            
            # Limit length
            if len(title) > 100:
                title = title[:100] + "..."
            
            return title if title else None
        
        return None
    
    def _infer_context(self, line: str) -> str:
        """Infer appropriate GTD context from line content."""
        line_lower = line.lower()
        
        if any(word in line_lower for word in ["call", "phone", "ring", "dial"]):
            return "calls"
        elif any(word in line_lower for word in ["email", "send", "reply", "message"]):
            return "email" 
        elif any(word in line_lower for word in ["research", "google", "look up", "find out"]):
            return "research"
        elif any(word in line_lower for word in ["buy", "purchase", "shopping", "store"]):
            return "errands"
        else:
            return "computer"
    
    def _infer_priority(self, line: str) -> str:
        """Infer priority from line content."""
        line_lower = line.lower()
        
        if any(word in line_lower for word in ["urgent", "asap", "immediately", "critical"]):
            return "urgent_important"
        elif any(word in line_lower for word in ["important", "must", "need to"]):
            return "not_urgent_important" 
        else:
            return "not_urgent_not_important"
    
    def _infer_project(self, line: str) -> Optional[str]:
        """Infer project from line content."""
        # Simple project inference - you'd want more sophisticated logic
        line_lower = line.lower()
        
        # Look for common project indicators
        if "project" in line_lower:
            # Try to extract project name
            words = line.split()
            for i, word in enumerate(words):
                if word.lower() == "project" and i > 0:
                    return words[i-1].strip()
        
        return None


# Enhanced tool functions that can be used as drop-in replacements

def gtd_create_task_enhanced(title: str, project: Optional[str] = None,
                           context: str = "computer", priority: str = "not_urgent_important",
                           notes: Optional[str] = None, source: str = "unknown") -> str:
    """Enhanced task creation with duplicate prevention."""
    tools = EnhancedGTDTools(source)
    result = tools.create_task_safe(title, project, context, priority, notes)
    
    if result['created']:
        return result['message']
    else:
        return f"Task creation {result['status']}: {result['message']}"


def gtd_process_daily_log_enhanced(log_content: str, date: str, source: str = "unknown") -> str:
    """Enhanced daily log processing with duplicate prevention."""
    tools = EnhancedGTDTools(source)
    result = tools.process_daily_log_safe(log_content, date)
    
    return f"Daily log processing {result['status']}: {result['message']} ({result['tasks_created']} tasks)"


def gtd_process_meeting_notes_enhanced(meeting_content: str, meeting_id: str, 
                                     source: str = "unknown") -> str:
    """Enhanced meeting notes processing with duplicate prevention."""
    tools = EnhancedGTDTools(source)
    result = tools.process_meeting_notes_safe(meeting_content, meeting_id)
    
    return f"Meeting processing {result['status']}: {result['message']} ({result['tasks_created']} tasks)"


if __name__ == "__main__":
    # Test enhanced tools
    print("🧪 Testing Enhanced GTD Tools")
    
    tools = EnhancedGTDTools("test")
    
    # Test task creation
    result1 = tools.create_task_safe("Test task 1", context="computer")
    print(f"Task 1: {result1}")
    
    # Test duplicate detection
    result2 = tools.create_task_safe("Test task 1", context="computer")  
    print(f"Task 2 (should be duplicate): {result2}")
    
    # Test daily log processing
    log_content = "Today I need to call John about the meeting. Also should email Sarah the report."
    result3 = tools.process_daily_log_safe(log_content, "2025-01-24")
    print(f"Log processing: {result3}")
    
    print("✅ Enhanced tools test completed")