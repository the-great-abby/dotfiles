#!/usr/bin/env python3
"""
GTD MCP Server - Model Context Protocol server for GTD Unified System

This server provides MCP tools for:
- Quick task suggestions (Gemma 1b - fast)
- Background analysis (GPT-OSS 20b - deep)
- Task management
- Zettel/project management
- Intelligent suggestions with banter
"""

import asyncio
import json
import os
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional
from datetime import datetime, timedelta, timezone
import uuid
import urllib.request

try:
    from mcp.server import Server
    from mcp.server.models import InitializationOptions
    from mcp.server.stdio import stdio_server
    from mcp.types import (
        Resource,
        Tool,
        TextContent,
        ImageContent,
        EmbeddedResource,
    )
except ImportError:
    print("Error: mcp package not installed. Install with: pip install mcp")
    sys.exit(1)

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from zsh.functions.gtd_persona_helper import read_config, call_persona

# GTD Configuration
GTD_CONFIG_FILE = Path.home() / ".gtd_config"
if (Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config").exists():
    GTD_CONFIG_FILE = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"

# Load GTD config
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
GTD_INBOX_DIR = "0-inbox"
GTD_PROJECTS_DIR = "1-projects"
GTD_TASKS_DIR = "tasks"
GTD_SUGGESTIONS_DIR = "suggestions"
GTD_ARCHIVE_DIR = "6-archive"

# Load Discord webhook URL from config
GTD_DISCORD_WEBHOOK_URL = os.getenv("GTD_DISCORD_WEBHOOK_URL", "")

if GTD_CONFIG_FILE.exists():
    with open(GTD_CONFIG_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'")
                if key == "GTD_BASE_DIR":
                    GTD_BASE_DIR = Path(value.replace("$HOME", str(Path.home())))
                elif key == "GTD_INBOX_DIR":
                    GTD_INBOX_DIR = value
                elif key == "GTD_PROJECTS_DIR":
                    GTD_PROJECTS_DIR = value
                elif key == "GTD_DISCORD_WEBHOOK_URL":
                    GTD_DISCORD_WEBHOOK_URL = value

# Ensure directories exist
GTD_BASE_DIR.mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_INBOX_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_PROJECTS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_TASKS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_SUGGESTIONS_DIR).mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_ARCHIVE_DIR).mkdir(parents=True, exist_ok=True)

# LM Studio config - both models via LM Studio
LM_CONFIG = read_config()
FAST_MODEL_URL = LM_CONFIG.get("url", "http://localhost:1234/v1/chat/completions")
FAST_MODEL_NAME = LM_CONFIG.get("chat_model", "google/gemma-3-1b")

# Deep model also via LM Studio (can be same URL, different model name)
DEEP_MODEL_URL = os.getenv("GTD_DEEP_MODEL_URL", LM_CONFIG.get("url", "http://localhost:1234/v1/chat/completions"))
DEEP_MODEL_NAME = os.getenv("GTD_DEEP_MODEL_NAME", os.getenv("GTD_DEEP_MODEL", "gpt-oss-20b"))

# RabbitMQ config for background processing
RABBITMQ_URL = os.getenv("GTD_RABBITMQ_URL", "amqp://localhost:5672")
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_QUEUE", "gtd_deep_analysis")

# Initialize MCP server
server = Server("gtd-unified-system")


def load_suggestion(suggestion_id: str) -> Optional[Dict[str, Any]]:
    """Load a suggestion from disk."""
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion_id}.json"
    if suggestion_file.exists():
        with open(suggestion_file) as f:
            return json.load(f)
    return None


def send_discord_notification(title: str, message: str) -> bool:
    """Send a notification to Discord webhook if configured."""
    if not GTD_DISCORD_WEBHOOK_URL:
        return False
    
    try:
        # Build Discord embed payload
        payload = {
            "embeds": [{
                "title": title,
                "description": message,
                "color": 15158332,  # Red color for GTD notifications
                "timestamp": datetime.now(timezone.utc).isoformat()
            }]
        }
        
        # Send to Discord
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            GTD_DISCORD_WEBHOOK_URL,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        with urllib.request.urlopen(req, timeout=5) as response:
            return response.status == 204
    except Exception:
        # Silently fail - don't break suggestion saving if Discord fails
        return False


def save_suggestion(suggestion: Dict[str, Any]) -> str:
    """Save a suggestion to disk and return its ID."""
    if "id" not in suggestion:
        suggestion["id"] = str(uuid.uuid4())
    suggestion["created"] = datetime.now().isoformat()
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion['id']}.json"
    with open(suggestion_file, 'w') as f:
        json.dump(suggestion, f, indent=2)
    
    # Send Discord notification for new suggestions
    if suggestion.get("status") == "pending":
        title = suggestion.get("title", "New AI Suggestion")
        reason = suggestion.get("reason", "No reason provided")
        confidence = suggestion.get("confidence", 0.0)
        confidence_pct = f"{confidence * 100:.0f}%" if isinstance(confidence, (int, float)) else "N/A"
        
        # Build message with file access info
        message = f"**{title}**\n\n"
        message += f"**Reason:** {reason}\n"
        message += f"**Confidence:** {confidence_pct}\n\n"
        message += f"📁 **File:** `{suggestion_file}`\n"
        message += f"💡 **Review:** Run `gtd-checkin` and select 'Review pending suggestions'\n"
        message += f"🔗 **Direct access:** `open {suggestion_file}` or `cat {suggestion_file}`"
        
        # Send notification in background (non-blocking)
        try:
            send_discord_notification("💡 New AI Suggestion", message)
        except Exception:
            pass  # Don't fail if Discord notification fails
    
    return suggestion["id"]


def get_pending_suggestions() -> List[Dict[str, Any]]:
    """Get all pending suggestions."""
    suggestions = []
    suggestions_dir = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR
    for suggestion_file in suggestions_dir.glob("*.json"):
        with open(suggestion_file) as f:
            suggestion = json.load(f)
            if suggestion.get("status") == "pending":
                suggestions.append(suggestion)
    return sorted(suggestions, key=lambda x: x.get("created", ""), reverse=True)


def scan_analysis_results_for_suggestions(days: int = 7, analysis_types: List[str] = None) -> Dict[str, Any]:
    """Scan recent deep analysis results and extract actionable suggestions."""
    if analysis_types is None:
        analysis_types = []
    
    results_dir = GTD_BASE_DIR / "deep_analysis_results"
    if not results_dir.exists():
        return {
            "success": False,
            "message": "No analysis results directory found",
            "suggestions_created": 0
        }
    
    # Find recent result files
    cutoff_date = datetime.now() - timedelta(days=days)
    result_files = []
    
    for result_file in results_dir.glob("*.json"):
        if result_file.stat().st_mtime >= cutoff_date.timestamp():
            # Check if it's one of the requested types (or all if empty)
            file_type = result_file.stem.split("_")[0]  # e.g., "connections" from "connections_20251205_..."
            if not analysis_types or file_type in analysis_types:
                result_files.append(result_file)
    
    if not result_files:
        return {
            "success": True,
            "message": f"No analysis results found in the last {days} days",
            "suggestions_created": 0,
            "files_scanned": 0
        }
    
    # Sort by modification time (newest first)
    result_files.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    
    created_suggestions = []
    processed_files = []
    
    for result_file in result_files:
        try:
            with open(result_file) as f:
                result_data = json.load(f)
            
            analysis_type = result_data.get("type", "unknown")
            analysis_content = result_data.get("analysis") or result_data.get("insights", "")
            
            if not analysis_content or "error" in result_data:
                continue
            
            # Extract actionable suggestions using AI
            suggestions = extract_suggestions_from_analysis(analysis_type, analysis_content, result_file)
            
            for suggestion_data in suggestions:
                suggestion_id = save_suggestion(suggestion_data)
                created_suggestions.append({
                    "id": suggestion_id,
                    "title": suggestion_data.get("title", ""),
                    "reason": suggestion_data.get("reason", "")  # Full reason, no truncation
                })
            
            processed_files.append(str(result_file.name))
            
        except Exception as e:
            continue  # Skip files that can't be processed
    
    return {
        "success": True,
        "message": f"Scanned {len(processed_files)} analysis result(s), created {len(created_suggestions)} suggestion(s)",
        "suggestions_created": len(created_suggestions),
        "files_scanned": len(processed_files),
        "suggestions": created_suggestions,
        "files": processed_files
    }


def extract_suggestions_from_analysis(analysis_type: str, analysis_content: str, source_file: Path) -> List[Dict[str, Any]]:
    """Extract actionable suggestions from analysis content using AI."""
    # Read the full analysis content (up to 8000 chars to avoid token limits but get more context)
    content_preview = analysis_content[:8000]
    if len(analysis_content) > 8000:
        content_preview += "\n\n[... analysis truncated ...]"
    
    # Use fast model to extract suggestions with better prompting
    # Adjust prompt based on analysis type for better extraction
    if analysis_type == "weekly_review":
        extraction_guidance = """
Look especially for:
- Action items from "Next Week Priorities" sections
- Specific recommendations from "Suggestions" sections
- Improvement ideas from "Challenges & Blockers" sections
- Priority tasks mentioned in numbered lists (e.g., "1. Task Prioritization - Immediately!")
- Concrete actions from "Actionable Suggestions" sections
- Any bold or numbered action items

Even if the analysis is strategic/advice-oriented, extract the concrete actions mentioned."""
    else:
        extraction_guidance = """
Look for:
- Specific tasks mentioned (e.g., "Document cluster setup process", "Set up Kubernetes cluster")
- Project ideas (e.g., "Create a Kubernetes Development project", "Group related tasks into a project")
- Zettel/note ideas (e.g., "Create a note about Kubernetes architecture patterns", "Document the connection between tasks")
- MOC ideas (e.g., "Create a MOC for Kubernetes learning", "Organize notes into a Kubernetes MOC")
- Organizational improvements"""
    
    prompt = f"""You are analyzing a {analysis_type} analysis that was generated for a GTD (Getting Things Done) system.

Analysis Content:
{content_preview}

Your task: Extract SPECIFIC, ACTIONABLE suggestions that can become tasks, projects, zettels (atomic notes), or MOCs (Maps of Content).

{extraction_guidance}

For each suggestion, determine:
1. Item type: "task", "project", "zettel", or "moc"
2. A clear, actionable title (be specific - not "review findings")
3. A reason that references specific parts of the analysis
4. Suggested project/area/MOC (if applicable - e.g., "Kubernetes Development", "Career Development", "Kubernetes Learning MOC")
5. A confidence score (0.0-1.0)

IMPORTANT: 
- Extract actual actionable items from the analysis, even from strategic/advice sections
- Convert recommendations into actionable tasks (e.g., "Dedicate 30-60 minutes to prioritize" becomes "Prioritize next 3-5 tasks in GTD system")
- Reference specific findings, patterns, or recommendations from the analysis
- Make titles specific and actionable (e.g., "Create Kubernetes Development project" not "Review Kubernetes tasks")
- CRITICAL: Keep titles COMPLETE - DO NOT truncate titles even if they are long. Include the full actionable phrase.
- Example: "Start with a simple tool like Todoist or Asana to capture tasks" NOT "Start with a simple tool like Todoist or Asana to capt"
- Remove any markdown formatting from titles (no **, *, `, #, etc.) but keep the full meaning
- Each title should be a complete, actionable task or project idea - include the full thought, not a fragment
- For weekly reviews: Look for numbered lists, bold action items, and "Next Week Priorities" sections

Return ONLY a JSON array in this exact format:
[
  {{
    "type": "task|project|zettel|moc",
    "title": "Specific actionable title",
    "reason": "Specific reason referencing the analysis findings",
    "suggested_project": "Project name or empty string",
    "suggested_area": "Area name or empty string",
    "suggested_moc": "MOC name or empty string",
    "confidence": 0.8
  }}
]

Determine the type based on:
- "task": Single actionable item that can be done
- "project": Multiple related tasks that should be grouped together
- "zettel": Atomic note/idea to capture knowledge
- "moc": Map of Content to organize multiple related notes

Return ONLY the JSON array, no other text."""

    try:
        # Call fast model to extract suggestions
        response_tuple = call_persona(
            read_config(),
            "david",  # Use David Allen persona for GTD-focused suggestions
            prompt,
            f"extracting_suggestions_from_{analysis_type}"
        )
        
        # call_persona returns (response, exit_code) tuple
        if isinstance(response_tuple, tuple):
            response, exit_code = response_tuple
            if exit_code != 0:
                # Error occurred, try pattern-based extraction as fallback
                pattern_suggestions = extract_suggestions_from_patterns(analysis_type, analysis_content, source_file)
                if pattern_suggestions:
                    return pattern_suggestions
                return []
        else:
            # Legacy behavior (shouldn't happen, but handle it)
            response = response_tuple
        
        # Clean up response - remove markdown code blocks if present
        import re
        response_clean = response.strip()
        
        # Remove markdown code blocks
        if response_clean.startswith("```"):
            response_clean = re.sub(r'^```(?:json)?\s*\n', '', response_clean)
            response_clean = re.sub(r'\n```\s*$', '', response_clean)
        
        # Try to find JSON array in response
        json_match = re.search(r'\[[\s\S]*\]', response_clean)
        if json_match:
            try:
                suggestions_data = json.loads(json_match.group())
            except json.JSONDecodeError:
                # Try to fix common JSON issues
                json_str = json_match.group()
                # Remove trailing commas
                json_str = re.sub(r',\s*}', '}', json_str)
                json_str = re.sub(r',\s*]', ']', json_str)
                suggestions_data = json.loads(json_str)
        else:
            # Try to parse the whole response as JSON
            suggestions_data = json.loads(response_clean)
        
        # Convert to suggestion format
        suggestions = []
        for item in suggestions_data:
            if isinstance(item, dict) and "title" in item:
                title = clean_suggestion_title(item["title"])
                reason = clean_suggestion_reason(item.get("reason", f"Extracted from {analysis_type} analysis"))
                
                # Validate the suggestion
                if not is_valid_ai_suggestion(title, reason):
                    continue
                
                # Determine item type (default to task if not specified)
                item_type = item.get("type", "task").lower()
                if item_type not in ["task", "project", "zettel", "moc"]:
                    item_type = "task"
                
                suggestion = {
                    "title": title,
                    "reason": reason,
                    "item_type": item_type,
                    "suggested_project": item.get("suggested_project", "").strip(),
                    "suggested_area": item.get("suggested_area", "").strip(),
                    "suggested_moc": item.get("suggested_moc", "").strip(),
                    "confidence": float(item.get("confidence", 0.7)),
                    "status": "pending",
                    "source": f"analysis_{analysis_type}",
                    "source_file": str(source_file.name),
                    "analysis_type": analysis_type
                }
                suggestions.append(suggestion)
        
        # If we got good suggestions, return them
        if suggestions:
            return suggestions
        
        # If no good suggestions, try a different approach - look for specific patterns in the analysis
        pattern_suggestions = extract_suggestions_from_patterns(analysis_type, analysis_content, source_file)
        if pattern_suggestions:
            return pattern_suggestions
        
        # Last resort: return empty list rather than generic suggestions
        return []
        
    except Exception as e:
        # Log error for debugging (but don't expose to user unless verbose)
        import sys
        if os.getenv("GTD_DEBUG"):
            print(f"DEBUG: Error extracting suggestions: {e}", file=sys.stderr)
        
        # Try pattern-based extraction as fallback
        pattern_suggestions = extract_suggestions_from_patterns(analysis_type, analysis_content, source_file)
        if pattern_suggestions:
            return pattern_suggestions
        
        # Return empty if we can't extract anything useful
        return []


def extract_suggestions_from_patterns(analysis_type: str, analysis_content: str, source_file: Path) -> List[Dict[str, Any]]:
    """Extract suggestions by looking for common patterns in analysis text - improved to get complete thoughts."""
    import re
    suggestions = []
    
    # Split into sentences first for better context
    sentences = re.split(r'[.!?]\s+', analysis_content)
    
    seen_titles = set()
    
    # Look for actionable patterns in complete sentences
    # Note: Removed 80-char limit - capture full actionable phrases
    # For weekly reviews, also look for numbered lists and action items
    action_patterns = [
        (r'(?:Create|Set up|Organize|Group|Document|Implement|Establish|Build|Develop|Start|Begin|Plan|Schedule|Set aside|Dedicate|Focus on|Prioritize)\s+([A-Z][^.!?]{10,})', 0.9),
        (r'(?:should|could|consider|suggest|recommend|need to|must)\s+(?:creating|setting up|organizing|grouping|documenting|implementing|establishing|building|developing|doing|completing|reviewing)\s+([^.!?]{10,})', 0.8),
        (r'(?:Create|Set up|Organize|Group|Document|Implement|Establish|Build|Develop)\s+a\s+([^.!?]{10,})', 0.85),
        # For numbered lists like "1. Task Prioritization - Immediately!"
        (r'^\d+\.\s+\*\*([^*]+?)\*\*[:\-]?\s*([^.!?\n]{15,})', 0.9),
        # For bold action items
        (r'\*\*([^*]+?)\*\*\s*[-–—]\s*([^.!?\n]{15,})', 0.85),
    ]
    
    # Also look for bullet points and numbered lists
    # Note: Removed 100-char limit - capture full actionable phrases
    bullet_pattern = r'^[\*\-\•]\s+\*\*(?:Create|Set up|Organize|Group|Document|Implement|Establish|Build|Develop|Plan|Start|Task|Prioritize|Schedule|Focus|Dedicate)\s+([^*]+?)\*\*[:\-]?\s*([^.!?\n]{10,})'
    
    # Check bullet points first (usually more actionable)
    for line in analysis_content.split('\n'):
        match = re.search(bullet_pattern, line, re.IGNORECASE | re.MULTILINE)
        if match:
            suggestion_text = match.group(1).strip()
            if is_valid_suggestion(suggestion_text, seen_titles):
                title = format_suggestion_title(suggestion_text)
                suggestions.append(create_suggestion(title, suggestion_text, 0.9, analysis_type, source_file))
                seen_titles.add(title.lower())
                if len(suggestions) >= 5:
                    break
    
    # Then check sentences for action patterns
    for sentence in sentences:
        if len(suggestions) >= 5:
            break
            
        for pattern, confidence in action_patterns:
            match = re.search(pattern, sentence, re.IGNORECASE)
            if match:
                suggestion_text = match.group(1).strip()
                # Get more context - include words before if it's a fragment
                if len(suggestion_text.split()) < 3:
                    # Try to get the full phrase
                    start_idx = sentence.lower().find(suggestion_text.lower())
                    if start_idx > 0:
                        # Get 5-10 words before
                        words_before = sentence[:start_idx].split()[-5:]
                        suggestion_text = ' '.join(words_before + [suggestion_text])
                
                if is_valid_suggestion(suggestion_text, seen_titles):
                    title = format_suggestion_title(suggestion_text)
                    suggestions.append(create_suggestion(title, suggestion_text, confidence, analysis_type, source_file))
                    seen_titles.add(title.lower())
                    break  # Only one suggestion per sentence
    
    return suggestions[:5]  # Limit to 5 best suggestions


def is_valid_suggestion(text: str, seen_titles: set) -> bool:
    """Check if a suggestion text is valid and not a duplicate."""
    text_lower = text.lower().strip()
    
    # Must be long enough to be meaningful
    if len(text) < 15 or len(text) > 120:
        return False
    
    # Must have at least 3 words
    if len(text.split()) < 3:
        return False
    
    # Skip if it's a duplicate
    if text_lower in seen_titles:
        return False
    
    # Skip generic phrases
    generic_phrases = ['you tell me', 'what are', 'could you', 'can you', 'would you', 'should you']
    if any(phrase in text_lower for phrase in generic_phrases):
        return False
    
    # Skip incomplete fragments (ending with prepositions or articles)
    if text_lower.endswith((' a ', ' an ', ' the ', ' of ', ' in ', ' on ', ' at ', ' to ', ' for ', ' with ')):
        return False
    
    # Must start with a capital letter or action word
    if not (text[0].isupper() or text.lower().startswith(('create', 'set', 'organize', 'group', 'document', 'implement', 'establish', 'build', 'develop', 'plan', 'start'))):
        return False
    
    return True


def format_suggestion_title(text: str) -> str:
    """Format a suggestion text into a proper title."""
    # Capitalize first letter
    title = text[0].upper() + text[1:] if text else ""
    
    # Remove trailing punctuation
    title = title.rstrip('.,;:')
    
    # Ensure it ends properly
    if not title.endswith(('.', '!', '?')):
        title = title.rstrip(',')
    
    return title.strip()


def clean_suggestion_title(title: str) -> str:
    """Clean up a suggestion title - remove markdown, truncate properly, etc."""
    import re
    if not title:
        return ""
    
    # Remove markdown formatting (more aggressive)
    title = re.sub(r'\*\*([^*]*)\*\*', r'\1', title)  # Bold (including empty)
    title = re.sub(r'\*\*', '', title)  # Any remaining **
    title = re.sub(r'\*([^*]*)\*', r'\1', title)  # Italic
    title = re.sub(r'(?<!\*)\*(?!\*)', '', title)  # Single * not part of **
    title = re.sub(r'`([^`]*)`', r'\1', title)  # Code
    title = re.sub(r'#+\s*', '', title)  # Headers
    title = re.sub(r'^\*\s*', '', title)  # Bullet points
    title = re.sub(r'^-\s*', '', title)  # Dashes
    title = re.sub(r'^\d+\.\s*', '', title)  # Numbered lists
    
    # Remove trailing colons and formatting
    title = title.rstrip(':*')
    
    # Don't truncate titles - store the full title
    # Titles can be any length, they'll be displayed fully in the review interface
    
    return title.strip()


def clean_suggestion_reason(reason: str) -> str:
    """Clean up a suggestion reason."""
    import re
    if not reason:
        return ""
    
    # Remove markdown formatting
    reason = re.sub(r'\*\*([^*]+)\*\*', r'\1', reason)  # Bold
    reason = re.sub(r'\*([^*]+)\*', r'\1', reason)  # Italic
    reason = re.sub(r'`([^`]+)`', r'\1', reason)  # Code
    
    # Don't truncate reasons - store the full text
    # They'll be displayed properly in the review interface
    
    return reason.strip()


def is_valid_ai_suggestion(title: str, reason: str) -> bool:
    """Validate that an AI-extracted suggestion is good."""
    if not title or not reason:
        return False
    
    # Title must be reasonable length (no upper limit for storage, but validate minimum)
    if len(title) < 10:
        return False
    
    # Title must have at least 3 words
    if len(title.split()) < 3:
        return False
    
    # Skip generic "review" suggestions
    if "review" in title.lower() and len(title.split()) < 6:
        return False
    
    # Skip if title looks like it was cut off mid-word
    if title.endswith((' capt', ' syst', ' manag', ' proj', ' task', ' item')):
        return False
    
    # Skip if it contains markdown that wasn't cleaned
    if '**' in title or '`' in title or title.startswith('#'):
        return False
    
    # Reason must be meaningful
    if len(reason) < 20:
        return False
    
    return True


def create_suggestion(title: str, reason_text: str, confidence: float, analysis_type: str, source_file: Path) -> Dict[str, Any]:
    """Create a suggestion dictionary."""
    return {
        "title": clean_suggestion_title(title),  # Clean markdown but keep full title
        "reason": f"Extracted from {analysis_type} analysis: {clean_suggestion_reason(reason_text)}",  # Full reason, no truncation
        "confidence": confidence,
        "status": "pending",
        "source": f"analysis_{analysis_type}",
        "source_file": str(source_file.name),
        "analysis_type": analysis_type
    }


# Helper functions for reading GTD data
def extract_frontmatter(file_path: Path) -> Dict[str, Any]:
    """Extract frontmatter from a markdown file."""
    if not file_path.exists():
        return {}
    
    frontmatter = {}
    in_frontmatter = False
    frontmatter_lines = []
    
    with open(file_path, 'r') as f:
        for line in f:
            if line.strip() == "---":
                if in_frontmatter:
                    break
                in_frontmatter = True
                continue
            if in_frontmatter:
                frontmatter_lines.append(line.rstrip())
    
    for line in frontmatter_lines:
        if ':' in line:
            key, value = line.split(':', 1)
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            frontmatter[key] = value
    
    return frontmatter


def read_task_file(task_path: Path) -> Dict[str, Any]:
    """Read a task file and return structured data."""
    if not task_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(task_path)
    
    # Read content (everything after frontmatter)
    content = ""
    in_frontmatter = False
    frontmatter_end = False
    with open(task_path, 'r') as f:
        for line in f:
            if line.strip() == "---":
                if not in_frontmatter:
                    in_frontmatter = True
                else:
                    frontmatter_end = True
                continue
            if frontmatter_end:
                content += line
    
    # Extract title (first # heading)
    title = ""
    for line in content.split('\n'):
        if line.startswith('# '):
            title = line[2:].strip()
            break
    
    task_data = {
        "id": task_path.stem,
        "path": str(task_path),
        "title": title,
        "type": frontmatter.get("type", "task"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
        "context": frontmatter.get("context", ""),
        "energy": frontmatter.get("energy", ""),
        "priority": frontmatter.get("priority", ""),
        "project": frontmatter.get("project", ""),
        "repository": frontmatter.get("repository", ""),
        "recurring": frontmatter.get("recurring", "false"),
        "frequency": frontmatter.get("frequency", ""),
        "content": content
    }
    
    return task_data


def find_all_task_files() -> List[Path]:
    """Find all task files (in tasks directory and project directories)."""
    tasks = []
    tasks_dir = GTD_BASE_DIR / GTD_TASKS_DIR
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    if tasks_dir.exists():
        tasks.extend(tasks_dir.glob("*.md"))
    
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if project_dir.is_dir():
                tasks.extend(project_dir.glob("*.md"))
    
    return tasks


def read_project_file(project_path: Path) -> Dict[str, Any]:
    """Read a project README file and return structured data."""
    readme_path = project_path / "README.md"
    if not readme_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(readme_path)
    
    # Count tasks
    task_count = len([f for f in project_path.glob("*.md") if f.name != "README.md"])
    
    project_data = {
        "name": project_path.name,
        "path": str(project_path),
        "type": frontmatter.get("type", "project"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
        "repository": frontmatter.get("repository", ""),
        "task_count": task_count
    }
    
    return project_data


def read_area_file(area_path: Path) -> Dict[str, Any]:
    """Read an area file and return structured data."""
    if not area_path.exists():
        return {}
    
    frontmatter = extract_frontmatter(area_path)
    
    area_data = {
        "name": area_path.stem,
        "path": str(area_path),
        "type": frontmatter.get("type", "area"),
        "status": frontmatter.get("status", "active"),
        "created": frontmatter.get("created", ""),
    }
    
    return area_data


def read_daily_log_file(date: Optional[str] = None) -> str:
    """Read a daily log file."""
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")
    
    log_dir = Path.home() / "Documents" / "daily_logs"
    log_file = log_dir / f"{date}.txt"
    
    if log_file.exists():
        with open(log_file, 'r') as f:
            return f.read()
    return ""


def find_task_file_by_id(task_id: str) -> Optional[Path]:
    """Find a task file by ID (searches tasks dir and projects)."""
    tasks_dir = GTD_BASE_DIR / GTD_TASKS_DIR
    projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
    
    # Try in tasks directory
    task_file = tasks_dir / f"{task_id}.md"
    if task_file.exists():
        return task_file
    
    # Try in project directories
    if projects_dir.exists():
        for project_dir in projects_dir.iterdir():
            if project_dir.is_dir():
                task_file = project_dir / f"{task_id}.md"
                if task_file.exists():
                    return task_file
                # Also try partial match
                for tf in project_dir.glob(f"{task_id}*.md"):
                    if tf.name != "README.md":
                        return tf
    
    return None


def queue_deep_analysis(analysis_type: str, context: Dict[str, Any]) -> str:
    """Queue a deep analysis task for background processing.
    
    Tries RabbitMQ first if available, falls back to file queue.
    Always ensures file queue exists as fallback.
    """
    message = {
        "type": analysis_type,
        "context": context,
        "timestamp": datetime.now().isoformat(),
        "model": DEEP_MODEL_NAME,
        "model_url": DEEP_MODEL_URL,
    }
    
    # Ensure file queue directory exists (always available as fallback)
    queue_file = GTD_BASE_DIR / "deep_analysis_queue.jsonl"
    GTD_BASE_DIR.mkdir(parents=True, exist_ok=True)
    
    # Try RabbitMQ first if pika is available
    try:
        import pika
        # Try to connect with a short timeout to avoid hanging
        try:
            connection = pika.BlockingConnection(
                pika.URLParameters(RABBITMQ_URL),
                blocked_connection_timeout=2  # 2 second timeout
            )
            channel = connection.channel()
            channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
            
            channel.basic_publish(
                exchange='',
                routing_key=RABBITMQ_QUEUE,
                body=json.dumps(message),
                properties=pika.BasicProperties(
                    delivery_mode=2,  # Make message persistent
                )
            )
            connection.close()
            return "queued_to_rabbitmq"
        except (pika.exceptions.AMQPConnectionError, 
                pika.exceptions.AMQPChannelError,
                ConnectionRefusedError,
                TimeoutError,
                OSError) as e:
            # RabbitMQ not available, fall back to file queue
            # This is expected if RabbitMQ isn't running
            pass
        except Exception as e:
            # Other RabbitMQ errors, fall back to file queue
            pass
    except ImportError:
        # pika not installed, use file queue
        pass
    
    # Fallback to file queue (always available)
    try:
        with open(queue_file, 'a') as f:
            f.write(json.dumps(message) + '\n')
        return "queued_to_file"
    except Exception as e:
        # Even file queue failed - this is a real problem
        return f"queue_failed: {e}"


def call_fast_ai(prompt: str, system_prompt: str = None) -> str:
    """Call the fast AI model (Gemma 1b) for quick responses."""
    import urllib.request
    
    if system_prompt is None:
        system_prompt = "You are a helpful GTD assistant. Provide concise, actionable suggestions."
    
    payload = {
        "model": FAST_MODEL_NAME,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.7,
        "max_tokens": LM_CONFIG.get("max_tokens", 500),
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        FAST_MODEL_URL,
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    timeout = LM_CONFIG.get("timeout", 30)  # Faster timeout for quick responses
    try:
        with urllib.request.urlopen(req, timeout=timeout) as response:
            result = json.loads(response.read().decode('utf-8'))
            if 'error' in result:
                return f"Error: {result['error'].get('message', 'Unknown error')}"
            if 'choices' in result and len(result['choices']) > 0:
                return result['choices'][0]['message']['content']
            return "No response from AI"
    except Exception as e:
        return f"Error calling AI: {e}"


@server.list_tools()
async def handle_list_tools() -> List[Tool]:
    """List all available MCP tools."""
    return [
        Tool(
            name="suggest_tasks_from_text",
            description="Analyze text and suggest tasks using fast AI. Returns task suggestions with reasons and confidence scores. High-confidence suggestions may be auto-created.",
            inputSchema={
                "type": "object",
                "properties": {
                    "text": {
                        "type": "string",
                        "description": "The text to analyze for task suggestions"
                    },
                    "context": {
                        "type": "string",
                        "description": "Optional context about where this text came from (e.g., 'daily_log', 'meeting', 'email')"
                    },
                    "mode": {
                        "type": "string",
                        "description": "Mode: 'immediate' (auto-create high confidence) or 'review' (save for review). Default: 'immediate'",
                        "enum": ["immediate", "review"]
                    }
                },
                "required": ["text"]
            }
        ),
        Tool(
            name="create_tasks_from_suggestion",
            description="Create a task from a pending suggestion. Use the suggestion_id from get_pending_suggestions.",
            inputSchema={
                "type": "object",
                "properties": {
                    "suggestion_id": {
                        "type": "string",
                        "description": "The ID of the suggestion to create a task from"
                    }
                },
                "required": ["suggestion_id"]
            }
        ),
        Tool(
            name="get_pending_suggestions",
            description="Get all pending task suggestions that haven't been acted on yet.",
            inputSchema={
                "type": "object",
                "properties": {
                    "confidence_filter": {
                        "type": "string",
                        "description": "Filter by confidence level: 'high', 'medium', 'low', or 'all'. Default: 'all'",
                        "enum": ["high", "medium", "low", "all"]
                    }
                }
            }
        ),
        Tool(
            name="get_immediate_suggestions",
            description="Get high-confidence suggestions that should be shown immediately (for auto-creation or quick review).",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="get_review_mode_suggestions",
            description="Get medium-confidence suggestions for review mode (requires user decision).",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="create_task_from_suggestion_quick",
            description="Create a task from a suggestion with one keystroke (quick creation, no prompts).",
            inputSchema={
                "type": "object",
                "properties": {
                    "suggestion_id": {
                        "type": "string",
                        "description": "The ID of the suggestion to create a task from"
                    }
                },
                "required": ["suggestion_id"]
            }
        ),
        Tool(
            name="dismiss_suggestion",
            description="Dismiss a suggestion (marks as dismissed and tracks for learning).",
            inputSchema={
                "type": "object",
                "properties": {
                    "suggestion_id": {
                        "type": "string",
                        "description": "The ID of the suggestion to dismiss"
                    }
                },
                "required": ["suggestion_id"]
            }
        ),
        Tool(
            name="get_suggestion_statistics",
            description="Get acceptance statistics and confidence thresholds for the learning system.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="create_task",
            description="Create a new task directly. Can specify title, project, context, priority, and notes.",
            inputSchema={
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Task title/description"
                    },
                    "project": {
                        "type": "string",
                        "description": "Optional project name to assign task to"
                    },
                    "context": {
                        "type": "string",
                        "description": "Optional context (home, office, computer, phone, errands)"
                    },
                    "priority": {
                        "type": "string",
                        "description": "Optional priority (urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important)"
                    },
                    "notes": {
                        "type": "string",
                        "description": "Optional notes or additional details"
                    }
                },
                "required": ["title"]
            }
        ),
        Tool(
            name="suggest_task",
            description="Suggest a task (adds to pending suggestions). Provides reason and confidence.",
            inputSchema={
                "type": "object",
                "properties": {
                    "title": {
                        "type": "string",
                        "description": "Suggested task title"
                    },
                    "reason": {
                        "type": "string",
                        "description": "Reason why this task is suggested"
                    },
                    "confidence": {
                        "type": "number",
                        "description": "Confidence score (0.0 to 1.0)"
                    }
                },
                "required": ["title", "reason"]
            }
        ),
        Tool(
            name="complete_task",
            description="Mark a task as complete by its ID.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to complete (from task filename)"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="defer_task",
            description="Defer a task until a specific date/time.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to defer"
                    },
                    "until": {
                        "type": "string",
                        "description": "ISO datetime string or date string (e.g., '2025-01-15' or '2025-01-15T10:00:00')"
                    }
                },
                "required": ["task_id", "until"]
            }
        ),
        Tool(
            name="weekly_review",
            description="Trigger a deep weekly review analysis. This queues work for the 20b model in the background.",
            inputSchema={
                "type": "object",
                "properties": {
                    "week_start": {
                        "type": "string",
                        "description": "Optional start date for the week (ISO format). Defaults to current week."
                    }
                }
            }
        ),
        Tool(
            name="analyze_energy",
            description="Analyze energy patterns from daily logs. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "number",
                        "description": "Number of days to analyze (default: 7)"
                    }
                }
            }
        ),
        Tool(
            name="find_connections",
            description="Find connections between tasks, projects, and zettels. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "scope": {
                        "type": "string",
                        "description": "Scope of search: 'tasks', 'projects', 'zettels', or 'all' (default: 'all')"
                    }
                }
            }
        ),
        Tool(
            name="generate_insights",
            description="Generate insights from recent activity. Queued for deep analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "focus": {
                        "type": "string",
                        "description": "Focus area: 'productivity', 'habits', 'projects', or 'general' (default: 'general')"
                    }
                }
            }
        ),
        Tool(
            name="get_worker_status",
            description="Check background worker status - whether it's running, queue status, and recent activity.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="list_tasks",
            description="List tasks with optional filters. Returns structured task data.",
            inputSchema={
                "type": "object",
                "properties": {
                    "context": {
                        "type": "string",
                        "description": "Filter by context (home, office, computer, phone, errands)"
                    },
                    "energy": {
                        "type": "string",
                        "description": "Filter by energy level (low, medium, high, creative, administrative)"
                    },
                    "priority": {
                        "type": "string",
                        "description": "Filter by priority (urgent_important, not_urgent_important, etc.)"
                    },
                    "project": {
                        "type": "string",
                        "description": "Filter by project name"
                    },
                    "status": {
                        "type": "string",
                        "description": "Filter by status (active, on-hold, done). Default: active"
                    },
                    "limit": {
                        "type": "number",
                        "description": "Maximum number of tasks to return (default: 50)"
                    }
                }
            }
        ),
        Tool(
            name="get_task_details",
            description="Get detailed information about a specific task by ID.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID (from task filename)"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="update_task",
            description="Update task properties (title, context, energy, priority, status, etc.).",
            inputSchema={
                "type": "object",
                "properties": {
                    "task_id": {
                        "type": "string",
                        "description": "The task ID to update"
                    },
                    "title": {
                        "type": "string",
                        "description": "New task title"
                    },
                    "context": {
                        "type": "string",
                        "description": "New context"
                    },
                    "energy": {
                        "type": "string",
                        "description": "New energy level"
                    },
                    "priority": {
                        "type": "string",
                        "description": "New priority"
                    },
                    "status": {
                        "type": "string",
                        "description": "New status (active, on-hold, done)"
                    },
                    "project": {
                        "type": "string",
                        "description": "Project to assign task to"
                    }
                },
                "required": ["task_id"]
            }
        ),
        Tool(
            name="list_projects",
            description="List all projects with their details and status.",
            inputSchema={
                "type": "object",
                "properties": {
                    "status": {
                        "type": "string",
                        "description": "Filter by status (active, on-hold, done, all). Default: active"
                    }
                }
            }
        ),
        Tool(
            name="create_project",
            description="Create a new project with optional repository link.",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {
                        "type": "string",
                        "description": "Project name"
                    },
                    "description": {
                        "type": "string",
                        "description": "Optional project description"
                    },
                    "repository": {
                        "type": "string",
                        "description": "Optional repository URL (GitHub/GitLab)"
                    }
                },
                "required": ["name"]
            }
        ),
        Tool(
            name="get_project_details",
            description="Get detailed information about a specific project.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Project name"
                    }
                },
                "required": ["project_name"]
            }
        ),
        Tool(
            name="get_project_status",
            description="Get project status including tasks, progress, and next actions.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_name": {
                        "type": "string",
                        "description": "Project name"
                    }
                },
                "required": ["project_name"]
            }
        ),
        Tool(
            name="list_areas",
            description="List all areas of responsibility.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="get_context_tasks",
            description="Get tasks available in a specific context and optional energy level.",
            inputSchema={
                "type": "object",
                "properties": {
                    "context": {
                        "type": "string",
                        "description": "Context (home, office, computer, phone, errands)"
                    },
                    "energy": {
                        "type": "string",
                        "description": "Optional energy level filter"
                    },
                    "limit": {
                        "type": "number",
                        "description": "Maximum number of tasks (default: 10)"
                    }
                },
                "required": ["context"]
            }
        ),
        Tool(
            name="get_inbox_count",
            description="Get the count of unprocessed items in the inbox.",
            inputSchema={
                "type": "object",
                "properties": {}
            }
        ),
        Tool(
            name="read_daily_log",
            description="Read daily log entries for a specific date or today.",
            inputSchema={
                "type": "object",
                "properties": {
                    "date": {
                        "type": "string",
                        "description": "Date in YYYY-MM-DD format (default: today)"
                    }
                }
            }
        ),
        Tool(
            name="read_recent_logs",
            description="Read daily log entries from the past N days.",
            inputSchema={
                "type": "object",
                "properties": {
                    "days": {
                        "type": "number",
                        "description": "Number of days to read (default: 7)"
                    }
                }
            }
        ),
        Tool(
            name="restructure_with_natural_language",
            description="Restructure tasks, projects, areas, or goals based on natural language instructions. Understands semantic intent like 'make more prominent', 'archive but keep searchable', 'focus on this week', etc.",
            inputSchema={
                "type": "object",
                "properties": {
                    "item_type": {
                        "type": "string",
                        "description": "Type of item: 'task', 'project', 'area', or 'goal'",
                        "enum": ["task", "project", "area", "goal"]
                    },
                    "item_id": {
                        "type": "string",
                        "description": "The ID or name of the item to restructure"
                    },
                    "command": {
                        "type": "string",
                        "description": "Natural language command describing what to do (e.g., 'Make this more prominent', 'Archive but keep searchable', 'Focus on this week')"
                    }
                },
                "required": ["item_type", "item_id", "command"]
            }
        ),
    ]


@server.call_tool()
async def handle_call_tool(name: str, arguments: Dict[str, Any]) -> List[TextContent]:
    """Handle tool calls."""
    
    if name == "suggest_tasks_from_text":
        text = arguments.get("text", "")
        context = arguments.get("context", "")
        mode = arguments.get("mode", "immediate")  # "immediate" or "review"
        
        prompt = f"""Analyze the following text and suggest actionable tasks.

Text: {text}
Context: {context if context else 'general'}

For each task you identify, provide:
1. A clear, actionable task title
2. A brief reason why this task is important
3. A confidence score (0.0 to 1.0)
4. Suggested context (home, office, computer, phone, errands)
5. Suggested priority (urgent_important, not_urgent_important, urgent_not_important, not_urgent_not_important)

Format your response as JSON array of objects with keys: title, reason, confidence, context, priority.

Only suggest tasks that are clearly actionable. If no tasks are found, return an empty array."""

        response = call_fast_ai(prompt, "You are a GTD task extraction expert. Return only valid JSON.")
        
        try:
            # Try to extract JSON from response
            import re
            json_match = re.search(r'\[.*\]', response, re.DOTALL)
            if json_match:
                suggestions = json.loads(json_match.group())
            else:
                suggestions = []
        except:
            suggestions = []
        
        # Import smart suggestions module
        try:
            from gtd_smart_suggestions import (
                save_suggestion as save_smart_suggestion,
                should_auto_create,
                categorize_suggestion,
                create_task_from_suggestion,
                get_confidence_thresholds
            )
            use_smart_suggestions = True
        except ImportError:
            use_smart_suggestions = False
        
        # Save suggestions and handle immediate/auto-creation
        saved_suggestions = []
        auto_created = []
        
        thresholds = get_confidence_thresholds() if use_smart_suggestions else {}
        
        for suggestion in suggestions:
            suggestion["status"] = "pending"
            suggestion["source_text"] = text
            suggestion["source_context"] = context
            confidence = suggestion.get("confidence", 0.5)
            
            # Use smart suggestions if available (save to disk)
            if use_smart_suggestions:
                # Save suggestion using the smart suggestions module (which also tracks metadata)
                suggestion_id = save_smart_suggestion(suggestion)
                
                # Auto-create if confidence is very high
                if mode == "immediate" and should_auto_create(confidence):
                    success, message = create_task_from_suggestion(suggestion)
                    if success:
                        auto_created.append({
                            "id": suggestion_id,
                            "title": suggestion.get("title", ""),
                            "message": message
                        })
                        continue  # Skip adding to saved_suggestions since it's already created
                
                category = categorize_suggestion(confidence)
                suggestion["category"] = category
            else:
                suggestion_id = save_suggestion(suggestion)
            
            saved_suggestions.append({
                "id": suggestion_id,
                "title": suggestion.get("title", ""),
                "reason": suggestion.get("reason", ""),
                "confidence": confidence,
                "category": suggestion.get("category", "medium")
            })
        
        result = {
            "suggestions": saved_suggestions,
            "count": len(saved_suggestions),
            "auto_created": auto_created,
            "auto_created_count": len(auto_created),
            "raw_response": response
        }
        
        return [TextContent(type="text", text=json.dumps(result, indent=2))]
    
    elif name == "create_tasks_from_suggestion":
        suggestion_id = arguments.get("suggestion_id", "")
        suggestion = load_suggestion(suggestion_id)
        
        if not suggestion:
            return [TextContent(type="text", text=json.dumps({"error": f"Suggestion {suggestion_id} not found"}))]
        
        # Create task using gtd-task command
        import subprocess
        task_title = suggestion.get("title", "")
        context = suggestion.get("context", "computer")
        priority = suggestion.get("priority", "not_urgent_important")
        project = suggestion.get("project", "")
        notes = suggestion.get("reason", "")
        
        cmd = [
            "gtd-task", "add",
            "--context", context,
            "--priority", priority,
            "--non-interactive",
            task_title
        ]
        
        if project:
            cmd.extend(["--project", project])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(GTD_BASE_DIR.parent))
            if result.returncode == 0:
                # Mark suggestion as used
                suggestion["status"] = "accepted"
                suggestion["accepted_at"] = datetime.now().isoformat()
                save_suggestion(suggestion)
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": f"Task created from suggestion {suggestion_id}",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to create task: {result.stderr}",
                    "output": result.stdout
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "get_pending_suggestions":
        confidence_filter = arguments.get("confidence_filter", "all")
        
        # Try to use smart suggestions module
        try:
            from gtd_smart_suggestions import (
                get_immediate_suggestions,
                get_review_mode_suggestions,
                categorize_suggestion,
                get_confidence_thresholds
            )
            use_smart = True
            thresholds = get_confidence_thresholds()
        except ImportError:
            use_smart = False
            suggestions = get_pending_suggestions()
        
        if use_smart:
            if confidence_filter == "high":
                suggestions = get_immediate_suggestions()
            elif confidence_filter == "medium":
                suggestions = get_review_mode_suggestions()
            elif confidence_filter == "low":
                all_suggestions = get_pending_suggestions()
                thresholds = get_confidence_thresholds()
                suggestions = [
                    s for s in all_suggestions
                    if s.get("confidence", 0.0) < thresholds["medium"]
                ]
            else:
                suggestions = get_pending_suggestions()
                
            # Add category to each suggestion
            for suggestion in suggestions:
                if "category" not in suggestion:
                    suggestion["category"] = categorize_suggestion(
                        suggestion.get("confidence", 0.5)
                    )
        else:
            # Filter manually if smart suggestions not available
            if confidence_filter != "all":
                filtered = []
                for suggestion in suggestions:
                    confidence = suggestion.get("confidence", 0.5)
                    if confidence_filter == "high" and confidence >= 0.80:
                        filtered.append(suggestion)
                    elif confidence_filter == "medium" and 0.60 <= confidence < 0.80:
                        filtered.append(suggestion)
                    elif confidence_filter == "low" and confidence < 0.60:
                        filtered.append(suggestion)
                suggestions = filtered
        
        return [TextContent(type="text", text=json.dumps({
            "suggestions": suggestions,
            "count": len(suggestions),
            "filter": confidence_filter,
            "thresholds": thresholds if use_smart else None
        }, indent=2, default=str))]
    
    elif name == "get_immediate_suggestions":
        try:
            from gtd_smart_suggestions import get_immediate_suggestions, get_confidence_thresholds
            suggestions = get_immediate_suggestions()
            thresholds = get_confidence_thresholds()
            return [TextContent(type="text", text=json.dumps({
                "suggestions": suggestions,
                "count": len(suggestions),
                "threshold": thresholds["high"],
                "auto_create_threshold": thresholds["auto_create"]
            }, indent=2, default=str))]
        except ImportError:
            return [TextContent(type="text", text=json.dumps({
                "error": "Smart suggestions module not available",
                "suggestions": [],
                "count": 0
            }))]
    
    elif name == "get_review_mode_suggestions":
        try:
            from gtd_smart_suggestions import get_review_mode_suggestions, get_confidence_thresholds
            suggestions = get_review_mode_suggestions()
            thresholds = get_confidence_thresholds()
            return [TextContent(type="text", text=json.dumps({
                "suggestions": suggestions,
                "count": len(suggestions),
                "threshold_low": thresholds["medium"],
                "threshold_high": thresholds["high"]
            }, indent=2, default=str))]
        except ImportError:
            return [TextContent(type="text", text=json.dumps({
                "error": "Smart suggestions module not available",
                "suggestions": [],
                "count": 0
            }))]
    
    elif name == "create_task_from_suggestion_quick":
        suggestion_id = arguments.get("suggestion_id", "")
        try:
            from gtd_smart_suggestions import (
                load_suggestion,
                create_task_from_suggestion
            )
            
            suggestion = load_suggestion(suggestion_id)
            if not suggestion:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Suggestion {suggestion_id} not found"
                }))]
            
            success, message = create_task_from_suggestion(suggestion)
            return [TextContent(type="text", text=json.dumps({
                "success": success,
                "message": message
            }))]
        except ImportError:
            # Fallback to old method
            return handle_call_tool("create_tasks_from_suggestion", {"suggestion_id": suggestion_id})
    
    elif name == "dismiss_suggestion":
        suggestion_id = arguments.get("suggestion_id", "")
        try:
            from gtd_smart_suggestions import dismiss_suggestion
            success = dismiss_suggestion(suggestion_id)
            return [TextContent(type="text", text=json.dumps({
                "success": success,
                "message": f"Suggestion {suggestion_id} dismissed" if success else f"Suggestion {suggestion_id} not found"
            }))]
        except ImportError:
            # Fallback: manually mark as dismissed
            suggestion = load_suggestion(suggestion_id)
            if suggestion:
                suggestion["status"] = "dismissed"
                suggestion["dismissed_at"] = datetime.now().isoformat()
                save_suggestion(suggestion)
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": f"Suggestion {suggestion_id} dismissed"
                }))]
            return [TextContent(type="text", text=json.dumps({
                "error": f"Suggestion {suggestion_id} not found"
            }))]
    
    elif name == "get_suggestion_statistics":
        try:
            from gtd_smart_suggestions import get_acceptance_statistics
            stats = get_acceptance_statistics()
            return [TextContent(type="text", text=json.dumps(stats, indent=2, default=str))]
        except ImportError:
            return [TextContent(type="text", text=json.dumps({
                "error": "Smart suggestions module not available"
            }))]
    
    elif name == "create_task":
        title = arguments.get("title", "")
        project = arguments.get("project", "")
        context = arguments.get("context", "computer")
        priority = arguments.get("priority", "not_urgent_important")
        notes = arguments.get("notes", "")
        
        import subprocess
        cmd = [
            "gtd-task", "add",
            "--context", context,
            "--priority", priority,
            "--non-interactive",
            title
        ]
        
        if project:
            cmd.extend(["--project", project])
        
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(GTD_BASE_DIR.parent))
            if result.returncode == 0:
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": "Task created successfully",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to create task: {result.stderr}"
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "suggest_task":
        title = arguments.get("title", "")
        reason = arguments.get("reason", "")
        confidence = arguments.get("confidence", 0.5)
        
        suggestion = {
            "title": title,
            "reason": reason,
            "confidence": confidence,
            "status": "pending"
        }
        
        suggestion_id = save_suggestion(suggestion)
        
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "suggestion_id": suggestion_id,
            "message": "Suggestion saved"
        }))]
    
    elif name == "scan_analysis_results":
        days = arguments.get("days", 7)
        analysis_types = arguments.get("analysis_types", [])
        
        result = scan_analysis_results_for_suggestions(days, analysis_types)
        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]
    
    elif name == "complete_task":
        task_id = arguments.get("task_id", "")
        import subprocess
        try:
            result = subprocess.run(
                ["gtd-task", "complete", task_id],
                capture_output=True,
                text=True,
                cwd=str(GTD_BASE_DIR.parent)
            )
            if result.returncode == 0:
                return [TextContent(type="text", text=json.dumps({
                    "success": True,
                    "message": f"Task {task_id} completed",
                    "output": result.stdout
                }))]
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": f"Failed to complete task: {result.stderr}"
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({"error": str(e)}))]
    
    elif name == "defer_task":
        task_id = arguments.get("task_id", "")
        until = arguments.get("until", "")
        # TODO: Implement defer logic (update task file with defer_until field)
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "message": f"Task {task_id} deferred until {until}",
            "note": "Defer functionality to be implemented"
        }))]
    
    elif name == "weekly_review":
        week_start = arguments.get("week_start", "")
        status = queue_deep_analysis("weekly_review", {"week_start": week_start})
        queue_method = "RabbitMQ" if "rabbitmq" in status else "file queue"
        queue_file = str(GTD_BASE_DIR / "deep_analysis_queue.jsonl") if "file" in status else None
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "queue_method": queue_method,
            "queue_file": queue_file,
            "message": f"Weekly review analysis queued for background processing ({queue_method})"
        }))]
    
    elif name == "analyze_energy":
        days = arguments.get("days", 7)
        status = queue_deep_analysis("analyze_energy", {"days": days})
        queue_method = "RabbitMQ" if "rabbitmq" in status else "file queue"
        queue_file = str(GTD_BASE_DIR / "deep_analysis_queue.jsonl") if "file" in status else None
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "queue_method": queue_method,
            "queue_file": queue_file,
            "message": f"Energy analysis for {days} days queued for background processing ({queue_method})"
        }))]
    
    elif name == "find_connections":
        scope = arguments.get("scope", "all")
        status = queue_deep_analysis("find_connections", {"scope": scope})
        queue_method = "RabbitMQ" if "rabbitmq" in status else "file queue"
        queue_file = str(GTD_BASE_DIR / "deep_analysis_queue.jsonl") if "file" in status else None
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "queue_method": queue_method,
            "queue_file": queue_file,
            "message": f"Connection analysis for {scope} queued for background processing ({queue_method})"
        }))]
    
    elif name == "generate_insights":
        focus = arguments.get("focus", "general")
        status = queue_deep_analysis("generate_insights", {"focus": focus})
        queue_method = "RabbitMQ" if "rabbitmq" in status else "file queue"
        queue_file = str(GTD_BASE_DIR / "deep_analysis_queue.jsonl") if "file" in status else None
        return [TextContent(type="text", text=json.dumps({
            "success": True,
            "status": status,
            "queue_method": queue_method,
            "queue_file": queue_file,
            "message": f"Insight generation for {focus} queued for background processing ({queue_method})"
        }))]
    
    elif name == "get_worker_status":
        import subprocess
        
        status_info = {
            "worker_running": False,
            "worker_pid": None,
            "queue_count": 0,
            "queue_file": str(GTD_BASE_DIR / "deep_analysis_queue.jsonl"),
            "recent_activity": None,
            "rabbitmq_available": False
        }
        
        # Check if worker process is running
        try:
            # Try using psutil for detailed info
            try:
                import psutil
                for proc in psutil.process_iter(['pid', 'name', 'cmdline', 'cpu_percent', 'memory_percent']):
                    try:
                        cmdline = proc.info.get('cmdline', [])
                        if cmdline and any('gtd_deep_analysis_worker.py' in str(arg) for arg in cmdline):
                            status_info["worker_running"] = True
                            status_info["worker_pid"] = proc.info['pid']
                            status_info["worker_cpu"] = proc.info.get('cpu_percent', 0)
                            status_info["worker_memory"] = proc.info.get('memory_percent', 0)
                            break
                    except (psutil.NoSuchProcess, psutil.AccessDenied):
                        pass
            except ImportError:
                # psutil not available, use pgrep
                result = subprocess.run(
                    ["pgrep", "-f", "gtd_deep_analysis_worker.py"],
                    capture_output=True,
                    text=True
                )
                if result.returncode == 0:
                    status_info["worker_running"] = True
                    pids = result.stdout.strip().split('\n')
                    status_info["worker_pid"] = pids[0] if pids else None
        except Exception:
            pass
        
        # Check queue file
        queue_file = GTD_BASE_DIR / "deep_analysis_queue.jsonl"
        if queue_file.exists():
            try:
                with open(queue_file) as f:
                    status_info["queue_count"] = sum(1 for _ in f)
            except Exception:
                pass
        
        # Check recent results
        results_dir = GTD_BASE_DIR / "deep_analysis_results"
        if results_dir.exists():
            result_files = sorted(results_dir.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)
            if result_files:
                latest = result_files[0]
                status_info["recent_activity"] = {
                    "latest_result": latest.name,
                    "timestamp": datetime.fromtimestamp(latest.stat().st_mtime).isoformat()
                }
        
        # Check RabbitMQ
        try:
            import pika
            status_info["rabbitmq_available"] = True
            try:
                connection = pika.BlockingConnection(pika.URLParameters(RABBITMQ_URL))
                channel = connection.channel()
                method = channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True, passive=True)
                status_info["rabbitmq_queue_messages"] = method.method.message_count
                connection.close()
            except Exception:
                status_info["rabbitmq_available"] = False
        except ImportError:
            pass
        
        return [TextContent(type="text", text=json.dumps(status_info, default=str))]
    
    elif name == "list_tasks":
        context_filter = arguments.get("context")
        energy_filter = arguments.get("energy")
        priority_filter = arguments.get("priority")
        project_filter = arguments.get("project")
        status_filter = arguments.get("status", "active")
        limit = arguments.get("limit", 50)
        
        tasks = []
        task_files = find_all_task_files()
        
        for task_file in task_files:
            task_data = read_task_file(task_file)
            
            # Apply filters
            if task_data.get("status") != status_filter:
                continue
            if context_filter and task_data.get("context") != context_filter:
                continue
            if energy_filter and task_data.get("energy") != energy_filter:
                continue
            if priority_filter and task_data.get("priority") != priority_filter:
                continue
            if project_filter:
                task_project = task_data.get("project", "")
                if not task_project or task_project != project_filter:
                    continue
            
            # Remove content for list view (keep it small)
            task_list_item = {k: v for k, v in task_data.items() if k != "content"}
            tasks.append(task_list_item)
            
            if len(tasks) >= limit:
                break
        
        return [TextContent(type="text", text=json.dumps({
            "tasks": tasks,
            "count": len(tasks),
            "filters": {
                "context": context_filter,
                "energy": energy_filter,
                "priority": priority_filter,
                "project": project_filter,
                "status": status_filter
            }
        }, default=str))]
    
    elif name == "get_task_details":
        task_id = arguments.get("task_id", "")
        task_file = find_task_file_by_id(task_id)
        
        if not task_file or not task_file.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Task {task_id} not found"
            }))]
        
        task_data = read_task_file(task_file)
        return [TextContent(type="text", text=json.dumps(task_data, default=str))]
    
    elif name == "update_task":
        task_id = arguments.get("task_id", "")
        task_file = find_task_file_by_id(task_id)
        
        if not task_file or not task_file.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Task {task_id} not found"
            }))]
        
        # Use gtd-task update command via subprocess
        import subprocess
        
        # For now, use the existing gtd-task command
        # We could implement direct file updates later
        result = subprocess.run(
            ["gtd-task", "update", task_id],
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE_DIR.parent)
        )
        
        if result.returncode == 0:
            return [TextContent(type="text", text=json.dumps({
                "success": True,
                "message": f"Task {task_id} updated",
                "output": result.stdout
            }))]
        else:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Failed to update task: {result.stderr}"
            }))]
    
    elif name == "list_projects":
        status_filter = arguments.get("status", "active")
        
        projects = []
        projects_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR
        
        if projects_dir.exists():
            for project_dir in projects_dir.iterdir():
                if project_dir.is_dir():
                    project_data = read_project_file(project_dir)
                    if project_data:
                        if status_filter == "all" or project_data.get("status") == status_filter:
                            projects.append(project_data)
        
        return [TextContent(type="text", text=json.dumps({
            "projects": projects,
            "count": len(projects),
            "status_filter": status_filter
        }, default=str))]
    
    elif name == "create_project":
        project_name = arguments.get("name", "")
        description = arguments.get("description", "")
        repository = arguments.get("repository", "")
        
        import subprocess
        
        cmd = ["gtd-project", "create", project_name]
        if repository:
            cmd.extend(["--repository", repository])
        
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE_DIR.parent),
            input=description if description else None
        )
        
        if result.returncode == 0:
            return [TextContent(type="text", text=json.dumps({
                "success": True,
                "message": f"Project '{project_name}' created",
                "output": result.stdout
            }))]
        else:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Failed to create project: {result.stderr}"
            }))]
    
    elif name == "get_project_details":
        project_name = arguments.get("project_name", "")
        project_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR / project_name.lower().replace(" ", "-")
        
        if not project_dir.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Project '{project_name}' not found"
            }))]
        
        project_data = read_project_file(project_dir)
        
        # Get tasks in project
        tasks = []
        for task_file in project_dir.glob("*.md"):
            if task_file.name != "README.md":
                task_data = read_task_file(task_file)
                if task_data:
                    tasks.append({k: v for k, v in task_data.items() if k != "content"})
        
        project_data["tasks"] = tasks
        
        return [TextContent(type="text", text=json.dumps(project_data, default=str))]
    
    elif name == "get_project_status":
        project_name = arguments.get("project_name", "")
        project_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR / project_name.lower().replace(" ", "-")
        
        if not project_dir.exists():
            return [TextContent(type="text", text=json.dumps({
                "error": f"Project '{project_name}' not found"
            }))]
        
        project_data = read_project_file(project_dir)
        
        # Count tasks by status
        tasks_by_status = {"active": 0, "on-hold": 0, "done": 0}
        active_tasks = []
        
        for task_file in project_dir.glob("*.md"):
            if task_file.name != "README.md":
                task_data = read_task_file(task_file)
                if task_data:
                    status = task_data.get("status", "active")
                    tasks_by_status[status] = tasks_by_status.get(status, 0) + 1
                    if status == "active":
                        active_tasks.append({
                            "id": task_data.get("id"),
                            "title": task_data.get("title"),
                            "context": task_data.get("context"),
                            "priority": task_data.get("priority")
                        })
        
        status_info = {
            "project": project_data,
            "tasks_by_status": tasks_by_status,
            "total_tasks": sum(tasks_by_status.values()),
            "active_tasks": active_tasks[:10]  # Top 10 active tasks
        }
        
        return [TextContent(type="text", text=json.dumps(status_info, default=str))]
    
    elif name == "list_areas":
        areas = []
        areas_dir = GTD_BASE_DIR / "2-areas"
        
        if areas_dir.exists():
            for area_file in areas_dir.glob("*.md"):
                area_data = read_area_file(area_file)
                if area_data:
                    areas.append(area_data)
        
        return [TextContent(type="text", text=json.dumps({
            "areas": areas,
            "count": len(areas)
        }, default=str))]
    
    elif name == "get_context_tasks":
        context = arguments.get("context", "")
        energy = arguments.get("energy")
        limit = arguments.get("limit", 10)
        
        tasks = []
        task_files = find_all_task_files()
        
        for task_file in task_files:
            task_data = read_task_file(task_file)
            
            if task_data.get("status") != "active":
                continue
            if task_data.get("context") != context:
                continue
            if energy and task_data.get("energy") != energy:
                continue
            
            tasks.append({
                "id": task_data.get("id"),
                "title": task_data.get("title"),
                "context": task_data.get("context"),
                "energy": task_data.get("energy"),
                "priority": task_data.get("priority"),
                "project": task_data.get("project")
            })
            
            if len(tasks) >= limit:
                break
        
        return [TextContent(type="text", text=json.dumps({
            "tasks": tasks,
            "count": len(tasks),
            "context": context,
            "energy": energy
        }, default=str))]
    
    elif name == "get_inbox_count":
        inbox_dir = GTD_BASE_DIR / GTD_INBOX_DIR
        count = 0
        
        if inbox_dir.exists():
            count = len(list(inbox_dir.glob("*.md")))
        
        return [TextContent(type="text", text=json.dumps({
            "count": count,
            "inbox_path": str(inbox_dir)
        }))]
    
    elif name == "read_daily_log":
        date = arguments.get("date")
        log_content = read_daily_log_file(date)
        
        return [TextContent(type="text", text=json.dumps({
            "date": date or datetime.now().strftime("%Y-%m-%d"),
            "content": log_content,
            "entry_count": len([l for l in log_content.split('\n') if l.strip() and not l.strip().startswith('#')]) if log_content else 0
        }))]
    
    elif name == "read_recent_logs":
        days = arguments.get("days", 7)
        logs = []
        log_dir = Path.home() / "Documents" / "daily_logs"
        
        for i in range(days):
            date = (datetime.now() - timedelta(days=i)).strftime("%Y-%m-%d")
            log_file = log_dir / f"{date}.txt"
            
            if log_file.exists():
                with open(log_file, 'r') as f:
                    content = f.read()
                    logs.append({
                        "date": date,
                        "content": content,
                        "entry_count": len([l for l in content.split('\n') if l.strip() and not l.strip().startswith('#')])
                    })
        
        return [TextContent(type="text", text=json.dumps({
            "logs": logs,
            "count": len(logs),
            "days": days
        }, default=str))]
    
    elif name == "restructure_with_natural_language":
        item_type = arguments.get("item_type", "")
        item_id = arguments.get("item_id", "")
        command = arguments.get("command", "")
        
        # First, get the current item details
        item_data = None
        item_file = None
        
        try:
            if item_type == "task":
                item_file = find_task_file_by_id(item_id)
                if item_file and item_file.exists():
                    item_data = read_task_file(item_file)
            elif item_type == "project":
                project_dir = GTD_BASE_DIR / GTD_PROJECTS_DIR / item_id.lower().replace(" ", "-")
                if project_dir.exists():
                    item_data = read_project_file(project_dir)
                    item_file = project_dir / "README.md"
            elif item_type == "area":
                areas_dir = GTD_BASE_DIR / "2-areas"
                item_file = areas_dir / f"{item_id.lower().replace(' ', '-')}.md"
                if item_file.exists():
                    item_data = read_area_file(item_file)
            elif item_type == "goal":
                goals_dir = GTD_BASE_DIR / "goals"
                item_file = goals_dir / f"{item_id.lower().replace(' ', '-')}.md"
                if item_file and item_file.exists():
                    # Read goal file (similar structure to tasks)
                    item_data = read_task_file(item_file)
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Error reading {item_type}: {str(e)}"
            }))]
        
        if not item_data:
            return [TextContent(type="text", text=json.dumps({
                "error": f"{item_type.capitalize()} '{item_id}' not found"
            }))]
        
        # Use AI to understand the intent and generate actions
        prompt = f"""You are a GTD system assistant. The user wants to restructure a {item_type}.

Current {item_type} details:
{json.dumps(item_data, indent=2, default=str)}

User's natural language command: "{command}"

Analyze the user's intent and determine what changes should be made. Return ONLY a valid JSON object with the following structure:
{{
  "intent": "Brief description of what the user wants",
  "actions": [
    {{
      "type": "update_field|archive|delete|add_tag|set_priority|set_status|add_due_date|move",
      "field": "field_name (if update_field)",
      "value": "new_value",
      "reason": "why this action makes sense"
    }}
  ],
  "explanation": "Human-readable explanation of what will happen"
}}

For common intents:
- "make more prominent" → increase priority, set status to active, add tags, potentially add due date
- "archive but keep searchable" → move to archive, set status to archived, ensure metadata preserved
- "focus on this week" → set high priority, add due date for end of week, set status to active
- "I'm done with this" → set status to done, archive, keep searchable
- "defer this" → set status to on-hold, add note about deferral

Return ONLY the JSON object, no other text."""

        system_prompt = "You are a GTD system expert. You understand semantic intent and can translate natural language commands into specific system actions. Return only valid JSON."

        response = call_fast_ai(prompt, system_prompt)
        
        try:
            import re
            json_match = re.search(r'\{.*\}', response, re.DOTALL)
            if json_match:
                plan = json.loads(json_match.group())
            else:
                return [TextContent(type="text", text=json.dumps({
                    "error": "Could not parse AI response",
                    "raw_response": response
                }))]
        except Exception as e:
            return [TextContent(type="text", text=json.dumps({
                "error": f"Error parsing AI response: {str(e)}",
                "raw_response": response
            }))]
        
        # Execute the actions
        import subprocess
        actions_taken = []
        errors = []
        
        for action in plan.get("actions", []):
            action_type = action.get("type")
            field = action.get("field")
            value = action.get("value")
            
            try:
                if item_type == "task":
                    if action_type == "update_field":
                        # Use update_task tool or direct file modification
                        if field in ["priority", "status", "context", "energy"]:
                            result = subprocess.run(
                                ["gtd-task", "update", item_id, "--" + field, str(value)],
                                capture_output=True,
                                text=True,
                                cwd=str(GTD_BASE_DIR.parent)
                            )
                            if result.returncode == 0:
                                actions_taken.append(f"Updated {field} to {value}")
                            else:
                                errors.append(f"Failed to update {field}: {result.stderr}")
                        else:
                            # Direct file modification for other fields (tags, due_date, etc.)
                            if item_file and item_file.exists():
                                with open(item_file, 'r') as f:
                                    content = f.read()
                                import re
                                if re.search(f'^{field}:', content, re.MULTILINE):
                                    content = re.sub(f'^{field}:.*', f'{field}: {value}', content, flags=re.MULTILINE)
                                else:
                                    # Add field after status or type field
                                    if re.search(r'^status:', content, re.MULTILINE):
                                        content = re.sub(r'^(status:.*)', f'\\1\n{field}: {value}', content, flags=re.MULTILINE)
                                    elif re.search(r'^type:', content, re.MULTILINE):
                                        content = re.sub(r'^(type:.*)', f'\\1\n{field}: {value}', content, flags=re.MULTILINE)
                                    else:
                                        content = re.sub(r'^(---\n)', f'---\n{field}: {value}\n', content)
                                with open(item_file, 'w') as f:
                                    f.write(content)
                                actions_taken.append(f"Updated {field} to {value}")
                    elif action_type == "set_priority":
                        result = subprocess.run(
                            ["gtd-task", "update", item_id, "--priority", str(value)],
                            capture_output=True,
                            text=True,
                            cwd=str(GTD_BASE_DIR.parent)
                        )
                        if result.returncode == 0:
                            actions_taken.append(f"Set priority to {value}")
                        else:
                            errors.append(f"Failed to set priority: {result.stderr}")
                    elif action_type == "set_status":
                        result = subprocess.run(
                            ["gtd-task", "update", item_id, "--status", str(value)],
                            capture_output=True,
                            text=True,
                            cwd=str(GTD_BASE_DIR.parent)
                        )
                        if result.returncode == 0:
                            actions_taken.append(f"Set status to {value}")
                        else:
                            errors.append(f"Failed to set status: {result.stderr}")
                    elif action_type == "add_tag":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            # Check if tags field exists
                            if re.search(r'^tags:', content, re.MULTILINE):
                                # Add to existing tags
                                content = re.sub(r'^(tags:.*)', f'\\1, {value}', content, flags=re.MULTILINE)
                            else:
                                # Add new tags field
                                if re.search(r'^status:', content, re.MULTILINE):
                                    content = re.sub(r'^(status:.*)', f'\\1\ntags: {value}', content, flags=re.MULTILINE)
                                else:
                                    content = re.sub(r'^(---\n)', f'---\ntags: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Added tag: {value}")
                    elif action_type == "add_due_date":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^due_date:', content, re.MULTILINE):
                                content = re.sub(r'^due_date:.*', f'due_date: {value}', content, flags=re.MULTILINE)
                            else:
                                if re.search(r'^status:', content, re.MULTILINE):
                                    content = re.sub(r'^(status:.*)', f'\\1\ndue_date: {value}', content, flags=re.MULTILINE)
                                else:
                                    content = re.sub(r'^(---\n)', f'---\ndue_date: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Set due date to {value}")
                    elif action_type == "archive":
                        # Move to archive but keep searchable
                        archive_dir = GTD_BASE_DIR / GTD_ARCHIVE_DIR / "tasks"
                        archive_dir.mkdir(parents=True, exist_ok=True)
                        if item_file and item_file.exists():
                            import shutil
                            # Update status first
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^status:', content, re.MULTILINE):
                                content = re.sub(r'^status:.*', 'status: archived', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', '---\nstatus: archived\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            # Move to archive
                            shutil.move(str(item_file), str(archive_dir / item_file.name))
                            actions_taken.append("Archived task (kept searchable)")
                
                elif item_type == "project":
                    if action_type == "update_field":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(f'^{field}:', content, re.MULTILINE):
                                content = re.sub(f'^{field}:.*', f'{field}: {value}', content, flags=re.MULTILINE)
                            else:
                                if re.search(r'^status:', content, re.MULTILINE):
                                    content = re.sub(r'^(status:.*)', f'\\1\n{field}: {value}', content, flags=re.MULTILINE)
                                else:
                                    content = re.sub(r'^(---\n)', f'---\n{field}: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Updated {field} to {value}")
                    elif action_type == "set_status":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^status:', content, re.MULTILINE):
                                content = re.sub(r'^status:.*', f'status: {value}', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', f'---\nstatus: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Set status to {value}")
                    elif action_type == "add_tag":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^tags:', content, re.MULTILINE):
                                content = re.sub(r'^(tags:.*)', f'\\1, {value}', content, flags=re.MULTILINE)
                            else:
                                if re.search(r'^status:', content, re.MULTILINE):
                                    content = re.sub(r'^(status:.*)', f'\\1\ntags: {value}', content, flags=re.MULTILINE)
                                else:
                                    content = re.sub(r'^(---\n)', f'---\ntags: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Added tag: {value}")
                    elif action_type == "archive":
                        result = subprocess.run(
                            ["gtd-project", "archive", item_id],
                            capture_output=True,
                            text=True,
                            cwd=str(GTD_BASE_DIR.parent)
                        )
                        if result.returncode == 0:
                            actions_taken.append("Archived project (kept searchable)")
                        else:
                            errors.append(f"Failed to archive: {result.stderr}")
                
                elif item_type == "area":
                    if action_type == "update_field":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(f'^{field}:', content, re.MULTILINE):
                                content = re.sub(f'^{field}:.*', f'{field}: {value}', content, flags=re.MULTILINE)
                            else:
                                if re.search(r'^status:', content, re.MULTILINE):
                                    content = re.sub(r'^(status:.*)', f'\\1\n{field}: {value}', content, flags=re.MULTILINE)
                                else:
                                    content = re.sub(r'^(---\n)', f'---\n{field}: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Updated {field} to {value}")
                    elif action_type == "set_status":
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^status:', content, re.MULTILINE):
                                content = re.sub(r'^status:.*', f'status: {value}', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', f'---\nstatus: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Set status to {value}")
                    elif action_type == "archive":
                        result = subprocess.run(
                            ["gtd-area", "archive", item_id],
                            capture_output=True,
                            text=True,
                            cwd=str(GTD_BASE_DIR.parent)
                        )
                        if result.returncode == 0:
                            actions_taken.append("Archived area (kept searchable)")
                        else:
                            errors.append(f"Failed to archive: {result.stderr}")
                
                elif item_type == "goal":
                    if action_type == "archive":
                        # Goals are typically archived by setting status
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^status:', content, re.MULTILINE):
                                content = re.sub(r'^status:.*', 'status: archived', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', '---\nstatus: archived\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append("Archived goal (kept searchable)")
                    elif action_type == "set_status" or (action_type == "update_field" and field == "status"):
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(r'^status:', content, re.MULTILINE):
                                content = re.sub(r'^status:.*', f'status: {value}', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', f'---\nstatus: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Set status to {value}")
                    elif action_type == "update_field":
                        # Update other goal fields
                        if item_file and item_file.exists():
                            with open(item_file, 'r') as f:
                                content = f.read()
                            import re
                            if re.search(f'^{field}:', content, re.MULTILINE):
                                content = re.sub(f'^{field}:.*', f'{field}: {value}', content, flags=re.MULTILINE)
                            else:
                                content = re.sub(r'^(---\n)', f'---\n{field}: {value}\n', content)
                            with open(item_file, 'w') as f:
                                f.write(content)
                            actions_taken.append(f"Updated {field} to {value}")
                
            except Exception as e:
                errors.append(f"Error executing action {action_type}: {str(e)}")
        
        result = {
            "success": len(errors) == 0,
            "intent": plan.get("intent"),
            "explanation": plan.get("explanation"),
            "actions_taken": actions_taken,
            "errors": errors,
            "original_command": command
        }
        
        return [TextContent(type="text", text=json.dumps(result, indent=2, default=str))]
    
    else:
        return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]


async def main():
    """Run the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await server.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name="gtd-unified-system",
                server_version="1.0.0",
                capabilities=server.get_capabilities(
                    notification_options=None,
                    experimental_capabilities=None,
                ),
            ),
        )


if __name__ == "__main__":
    asyncio.run(main())

