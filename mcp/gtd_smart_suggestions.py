#!/usr/bin/env python3
"""
Smart Task Suggestions - Enhanced MCP Implementation

Features:
- Immediate high-confidence task suggestions (auto-create)
- Review mode with medium-confidence suggestions
- One-keystroke task creation from suggestions
- Acceptance tracking to tune confidence thresholds
- Learning system to adapt thresholds based on user behavior
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from datetime import datetime
import uuid

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from zsh.functions.gtd_persona_helper import read_config

# GTD Configuration
GTD_CONFIG_FILE = Path.home() / ".gtd_config"
if (Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config").exists():
    GTD_CONFIG_FILE = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"

GTD_BASE_DIR = Path.home() / "Documents" / "gtd"
GTD_SUGGESTIONS_DIR = "suggestions"
GTD_PREFERENCES_FILE = Path.home() / ".gtd_preferences.json"

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

# Ensure directories exist
GTD_BASE_DIR.mkdir(parents=True, exist_ok=True)
(GTD_BASE_DIR / GTD_SUGGESTIONS_DIR).mkdir(parents=True, exist_ok=True)

# Default confidence thresholds (will be learned/adjusted)
DEFAULT_HIGH_CONFIDENCE_THRESHOLD = 0.85
DEFAULT_MEDIUM_CONFIDENCE_THRESHOLD = 0.60
DEFAULT_AUTO_CREATE_THRESHOLD = 0.90

# Track acceptance patterns
ACCEPTANCE_TRACKING_FILE = GTD_BASE_DIR / "suggestion_acceptance_tracking.json"


def load_acceptance_tracking() -> Dict[str, Any]:
    """Load acceptance tracking data."""
    if ACCEPTANCE_TRACKING_FILE.exists():
        try:
            with open(ACCEPTANCE_TRACKING_FILE) as f:
                return json.load(f)
        except Exception:
            pass
    
    # Initialize default structure
    return {
        "acceptance_history": [],
        "confidence_thresholds": {
            "high": DEFAULT_HIGH_CONFIDENCE_THRESHOLD,
            "medium": DEFAULT_MEDIUM_CONFIDENCE_THRESHOLD,
            "auto_create": DEFAULT_AUTO_CREATE_THRESHOLD
        },
        "acceptance_rate_by_confidence": {},
        "total_accepted": 0,
        "total_dismissed": 0,
        "total_auto_created": 0,
        "last_updated": None
    }


def save_acceptance_tracking(data: Dict[str, Any]):
    """Save acceptance tracking data."""
    data["last_updated"] = datetime.now().isoformat()
    with open(ACCEPTANCE_TRACKING_FILE, 'w') as f:
        json.dump(data, f, indent=2)


def track_suggestion_decision(suggestion_id: str, confidence: float, decision: str, 
                               auto_created: bool = False):
    """
    Track a suggestion acceptance/rejection decision.
    
    Args:
        suggestion_id: ID of the suggestion
        confidence: Confidence score (0.0-1.0)
        decision: "accepted" or "dismissed"
        auto_created: Whether this was auto-created (high confidence)
    """
    tracking = load_acceptance_tracking()
    
    # Record the decision
    tracking["acceptance_history"].append({
        "suggestion_id": suggestion_id,
        "confidence": confidence,
        "decision": decision,
        "auto_created": auto_created,
        "timestamp": datetime.now().isoformat()
    })
    
    # Update counters
    if decision == "accepted":
        tracking["total_accepted"] += 1
        if auto_created:
            tracking["total_auto_created"] += 1
    elif decision == "dismissed":
        tracking["total_dismissed"] += 1
    
    # Track acceptance rate by confidence bucket
    confidence_bucket = round(confidence * 10) / 10  # Round to 0.1
    bucket_key = f"{confidence_bucket:.1f}"
    
    if bucket_key not in tracking["acceptance_rate_by_confidence"]:
        tracking["acceptance_rate_by_confidence"][bucket_key] = {
            "accepted": 0,
            "dismissed": 0,
            "total": 0
        }
    
    bucket = tracking["acceptance_rate_by_confidence"][bucket_key]
    bucket["total"] += 1
    if decision == "accepted":
        bucket["accepted"] += 1
    else:
        bucket["dismissed"] += 1
    
    # Keep only last 1000 entries to prevent file from growing too large
    if len(tracking["acceptance_history"]) > 1000:
        tracking["acceptance_history"] = tracking["acceptance_history"][-1000:]
    
    save_acceptance_tracking(tracking)
    
    # Also update preferences system if available
    try:
        if GTD_PREFERENCES_FILE.exists():
            with open(GTD_PREFERENCES_FILE) as f:
                prefs = json.load(f)
            
            if "feature_usage" not in prefs:
                prefs["feature_usage"] = {}
            if "suggestions" not in prefs["feature_usage"]:
                prefs["feature_usage"]["suggestions"] = {
                    "accepted": 0,
                    "dismissed": 0,
                    "accepted_types": {},
                    "dismissed_types": {}
                }
            
            suggestion_type = "task"  # Default, can be extracted from suggestion
            if decision == "accepted":
                prefs["feature_usage"]["suggestions"]["accepted"] += 1
                if suggestion_type not in prefs["feature_usage"]["suggestions"]["accepted_types"]:
                    prefs["feature_usage"]["suggestions"]["accepted_types"][suggestion_type] = 0
                prefs["feature_usage"]["suggestions"]["accepted_types"][suggestion_type] += 1
            else:
                prefs["feature_usage"]["suggestions"]["dismissed"] += 1
                if suggestion_type not in prefs["feature_usage"]["suggestions"]["dismissed_types"]:
                    prefs["feature_usage"]["suggestions"]["dismissed_types"][suggestion_type] = 0
                prefs["feature_usage"]["suggestions"]["dismissed_types"][suggestion_type] += 1
            
            prefs["last_updated"] = datetime.now().isoformat()
            with open(GTD_PREFERENCES_FILE, 'w') as f:
                json.dump(prefs, f, indent=2)
    except Exception:
        pass  # Don't fail if preferences update fails


def calculate_optimal_thresholds() -> Dict[str, float]:
    """
    Calculate optimal confidence thresholds based on acceptance patterns.
    
    Returns:
        Dictionary with 'high', 'medium', 'auto_create' thresholds
    """
    tracking = load_acceptance_tracking()
    
    # If we don't have enough data, use defaults
    if tracking["total_accepted"] + tracking["total_dismissed"] < 20:
        return tracking["confidence_thresholds"]
    
    # Analyze acceptance rate by confidence bucket
    acceptance_by_bucket = tracking["acceptance_rate_by_confidence"]
    
    if not acceptance_by_bucket:
        return tracking["confidence_thresholds"]
    
    # Find confidence levels with high acceptance rates
    high_acceptance_buckets = []
    medium_acceptance_buckets = []
    
    for bucket_key, bucket_data in sorted(acceptance_by_bucket.items()):
        if bucket_data["total"] < 3:  # Need at least 3 data points
            continue
        
        acceptance_rate = bucket_data["accepted"] / bucket_data["total"]
        confidence = float(bucket_key)
        
        if acceptance_rate >= 0.80:  # 80%+ acceptance
            high_acceptance_buckets.append((confidence, acceptance_rate))
        elif acceptance_rate >= 0.60:  # 60-80% acceptance
            medium_acceptance_buckets.append((confidence, acceptance_rate))
    
    # Calculate thresholds
    new_thresholds = tracking["confidence_thresholds"].copy()
    
    # Auto-create threshold: Use highest confidence with 90%+ acceptance
    auto_create_candidates = [c for c, rate in high_acceptance_buckets if rate >= 0.90]
    if auto_create_candidates:
        new_thresholds["auto_create"] = min(auto_create_candidates)
    else:
        # Default to 0.90 if we don't have enough data
        new_thresholds["auto_create"] = DEFAULT_AUTO_CREATE_THRESHOLD
    
    # High confidence threshold: Use lowest confidence with 80%+ acceptance
    if high_acceptance_buckets:
        new_thresholds["high"] = min(c for c, rate in high_acceptance_buckets)
    else:
        new_thresholds["high"] = DEFAULT_HIGH_CONFIDENCE_THRESHOLD
    
    # Medium confidence threshold: Use lowest confidence with 60%+ acceptance
    # MUST be lower than high threshold
    if medium_acceptance_buckets:
        medium_candidate = min(c for c, rate in medium_acceptance_buckets)
        # Ensure medium < high
        if medium_candidate >= new_thresholds["high"]:
            new_thresholds["medium"] = max(DEFAULT_MEDIUM_CONFIDENCE_THRESHOLD, new_thresholds["high"] - 0.05)
        else:
            new_thresholds["medium"] = medium_candidate
    else:
        new_thresholds["medium"] = DEFAULT_MEDIUM_CONFIDENCE_THRESHOLD
    
    # Update stored thresholds
    tracking["confidence_thresholds"] = new_thresholds
    save_acceptance_tracking(tracking)
    
    return new_thresholds


def get_confidence_thresholds() -> Dict[str, float]:
    """Get current confidence thresholds (with auto-calculation)."""
    tracking = load_acceptance_tracking()
    
    # Recalculate thresholds periodically (every 10 decisions)
    total_decisions = tracking["total_accepted"] + tracking["total_dismissed"]
    if total_decisions > 0 and total_decisions % 10 == 0:
        return calculate_optimal_thresholds()
    
    return tracking["confidence_thresholds"]


def categorize_suggestion(confidence: float) -> str:
    """
    Categorize a suggestion based on confidence level.
    
    Returns:
        "high", "medium", or "low"
    """
    thresholds = get_confidence_thresholds()
    
    if confidence >= thresholds["high"]:
        return "high"
    elif confidence >= thresholds["medium"]:
        return "medium"
    else:
        return "low"


def should_auto_create(confidence: float) -> bool:
    """Determine if a suggestion should be auto-created."""
    thresholds = get_confidence_thresholds()
    return confidence >= thresholds["auto_create"]


def load_suggestion(suggestion_id: str) -> Optional[Dict[str, Any]]:
    """Load a suggestion from disk."""
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion_id}.json"
    if suggestion_file.exists():
        with open(suggestion_file) as f:
            return json.load(f)
    return None


def save_suggestion(suggestion: Dict[str, Any]) -> str:
    """Save a suggestion to disk and return its ID."""
    if "id" not in suggestion:
        suggestion["id"] = str(uuid.uuid4())
    if "created" not in suggestion:
        suggestion["created"] = datetime.now().isoformat()
    suggestion_file = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR / f"{suggestion['id']}.json"
    with open(suggestion_file, 'w') as f:
        json.dump(suggestion, f, indent=2)
    return suggestion["id"]


def resolve_project_for_task(suggestion: Dict[str, Any]) -> Optional[str]:
    """
    Use AI to help resolve which project a task should belong to.
    Can suggest existing projects OR suggest creating a new project for tracking.
    
    Returns:
        Project name (slug format) or None if unclear
    """
    try:
        # Get list of existing projects
        projects_dir = GTD_BASE_DIR.parent / "1-projects"
        if not projects_dir.exists():
            projects_dir = GTD_BASE_DIR / "1-projects"
        
        projects = []
        if projects_dir.exists():
            for project_dir in projects_dir.iterdir():
                if project_dir.is_dir() and (project_dir / "README.md").exists():
                    projects.append(project_dir.name)
        
        # Use AI to suggest project (existing or new)
        try:
            from zsh.functions.gtd_persona_helper import call_persona
            
            projects_list = ", ".join(projects[:15]) if projects else "none"
            title = suggestion.get("title", "")
            reason = suggestion.get("reason", "")
            source_text = suggestion.get("source_text", "")
            
            prompt = f"""Task: {title}
Reason: {reason}
Source context: {source_text[:300] if source_text else "N/A"}

Existing projects: {projects_list}

Analyze this task and determine:
1. Does it fit an existing project? If yes, return that project name exactly.
2. If not, does this task suggest a NEW project should be created for tracking related work? 
   - If yes, suggest a project name (2-4 words, descriptive, lowercase with hyphens)
   - If no clear project needed, return "none"

Return ONLY:
- An existing project name (exact match) OR
- A new project name (format: "new:project-name") OR  
- "none"

Examples:
- "website-redesign" (existing project)
- "new:home-automation-setup" (suggest new project)
- "none" (standalone task)"""
            
            response = call_persona("david", prompt)
            suggested = response.strip().lower().replace(" ", "-")
            
            # Check if it's a new project suggestion
            if suggested.startswith("new:"):
                new_project_name = suggested.replace("new:", "").strip()
                if new_project_name and len(new_project_name) > 2:
                    # Generate outcome from task context
                    outcome = f"Complete {title}" if title else f"Complete {new_project_name.replace('-', ' ').title()}"
                    # Create the new project
                    return create_or_get_project(new_project_name, outcome)
            
            # Check if it matches an existing project
            for project in projects:
                if project.lower() == suggested or project.lower().startswith(suggested):
                    return project
                # Also check if suggested is contained in project name
                if suggested in project.lower() or project.lower() in suggested:
                    return project
            
            # If "none" or no match, return None
            if "none" in suggested or not suggested or len(suggested) < 2:
                return None
            
            # If we got a project-like name but it doesn't match, try creating it
            if "-" in suggested or len(suggested.split()) == 1:
                return create_or_get_project(suggested)
                
        except ImportError:
            # Fallback if persona helper not available
            pass
        
        return None
    except Exception:
        return None


def create_or_get_project(project_name: str, suggested_outcome: str = None) -> Optional[str]:
    """
    Create a new project or return existing one if it already exists.
    Creates project directly without interactive prompts.
    
    Args:
        project_name: Project name in slug format (e.g., "home-automation")
        suggested_outcome: Optional outcome description for the project
    
    Returns:
        Project name (slug format) or None if creation failed
    """
    # Normalize project name
    project_slug = project_name.lower().strip().replace(" ", "-")
    # Remove any invalid characters
    project_slug = "".join(c if c.isalnum() or c == "-" else "" for c in project_slug)
    project_slug = "-".join(filter(None, project_slug.split("-")))  # Remove multiple hyphens
    
    if not project_slug or len(project_slug) < 2:
        return None
    
    # Determine projects directory
    projects_dir = GTD_BASE_DIR.parent / "1-projects"
    if not projects_dir.exists():
        projects_dir = GTD_BASE_DIR / "1-projects"
    
    # Check if project already exists
    project_dir = projects_dir / project_slug
    if project_dir.exists() and (project_dir / "README.md").exists():
        return project_slug  # Already exists
    
    # Create project directory
    try:
        project_dir.mkdir(parents=True, exist_ok=True)
        
        # Create project README with frontmatter
        today = datetime.now().strftime("%Y-%m-%d")
        now = datetime.now().strftime("%H:%M")
        
        # Generate a default outcome if not provided
        if not suggested_outcome:
            # Convert project name to a readable outcome
            display_name = project_slug.replace("-", " ").title()
            suggested_outcome = f"Complete {display_name}"
        
        readme_content = f"""---
type: project
status: active
created: {today}T{now}
project: {project_slug}
tags: []
---

# {project_slug.replace("-", " ").title()}

## Outcome

{suggested_outcome}

## Description

## Goals

## Next Actions

## Tasks

"""
        
        readme_file = project_dir / "README.md"
        with open(readme_file, 'w') as f:
            f.write(readme_content)
        
        return project_slug
    except Exception as e:
        # If creation failed, return None (task will be created without project)
        return None


def create_task_from_suggestion(suggestion: Dict[str, Any], ask_for_project: bool = True) -> Tuple[bool, str]:
    """
    Create a task from a suggestion.
    
    Args:
        suggestion: The suggestion dictionary
        ask_for_project: If True, use AI to help resolve project assignment
    
    Returns:
        (success, message)
    """
    import subprocess
    
    title = suggestion.get("title", "")
    context = suggestion.get("context", "computer")
    priority = suggestion.get("priority", "not_urgent_important")
    project = suggestion.get("suggested_project", "")
    
    # If no project assigned and we should ask, try to resolve it
    if ask_for_project and not project:
        resolved_project = resolve_project_for_task(suggestion)
        if resolved_project:
            project = resolved_project
            suggestion["suggested_project"] = project
            suggestion["project_resolved"] = True
            save_suggestion(suggestion)  # Update suggestion with resolved project
    
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
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(GTD_BASE_DIR.parent),
            timeout=10
        )
        
        if result.returncode == 0:
            # Mark suggestion as accepted
            suggestion["status"] = "accepted"
            suggestion["accepted_at"] = datetime.now().isoformat()
            save_suggestion(suggestion)
            
            # Track the acceptance
            track_suggestion_decision(
                suggestion["id"],
                suggestion.get("confidence", 0.5),
                "accepted",
                auto_created=True
            )
            
            project_msg = f" (project: {project})" if project else ""
            return True, f"Task created: {title}{project_msg}"
        else:
            return False, f"Failed to create task: {result.stderr}"
    except Exception as e:
        return False, f"Error creating task: {str(e)}"


def get_immediate_suggestions(min_confidence: float = None) -> List[Dict[str, Any]]:
    """
    Get high-confidence suggestions that should be shown immediately or auto-created.
    
    Args:
        min_confidence: Optional minimum confidence (uses threshold if not provided)
    
    Returns:
        List of high-confidence suggestions
    """
    thresholds = get_confidence_thresholds()
    if min_confidence is None:
        min_confidence = thresholds["high"]
    
    suggestions = []
    suggestions_dir = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR
    
    for suggestion_file in suggestions_dir.glob("*.json"):
        try:
            with open(suggestion_file) as f:
                suggestion = json.load(f)
            
            if suggestion.get("status") != "pending":
                continue
            
            confidence = suggestion.get("confidence", 0.0)
            if confidence >= min_confidence:
                suggestions.append(suggestion)
        except Exception:
            continue
    
    # Sort by confidence (highest first)
    suggestions.sort(key=lambda x: x.get("confidence", 0.0), reverse=True)
    
    return suggestions


def get_review_mode_suggestions() -> List[Dict[str, Any]]:
    """
    Get medium-confidence suggestions for review mode.
    
    Returns:
        List of medium-confidence suggestions
    """
    thresholds = get_confidence_thresholds()
    
    suggestions = []
    suggestions_dir = GTD_BASE_DIR / GTD_SUGGESTIONS_DIR
    
    for suggestion_file in suggestions_dir.glob("*.json"):
        try:
            with open(suggestion_file) as f:
                suggestion = json.load(f)
            
            if suggestion.get("status") != "pending":
                continue
            
            confidence = suggestion.get("confidence", 0.0)
            # Medium confidence: between medium and high thresholds
            if thresholds["medium"] <= confidence < thresholds["high"]:
                suggestions.append(suggestion)
        except Exception:
            continue
    
    # Sort by confidence (highest first)
    suggestions.sort(key=lambda x: x.get("confidence", 0.0), reverse=True)
    
    return suggestions


def dismiss_suggestion(suggestion_id: str):
    """Mark a suggestion as dismissed and track the decision."""
    suggestion = load_suggestion(suggestion_id)
    if not suggestion:
        return False
    
    suggestion["status"] = "dismissed"
    suggestion["dismissed_at"] = datetime.now().isoformat()
    save_suggestion(suggestion)
    
    # Track the dismissal
    track_suggestion_decision(
        suggestion_id,
        suggestion.get("confidence", 0.5),
        "dismissed",
        auto_created=False
    )
    
    return True


def get_acceptance_statistics() -> Dict[str, Any]:
    """Get acceptance statistics for the learning system."""
    tracking = load_acceptance_tracking()
    thresholds = get_confidence_thresholds()
    
    total = tracking["total_accepted"] + tracking["total_dismissed"]
    acceptance_rate = (tracking["total_accepted"] / total * 100) if total > 0 else 0
    
    return {
        "total_accepted": tracking["total_accepted"],
        "total_dismissed": tracking["total_dismissed"],
        "total_auto_created": tracking["total_auto_created"],
        "acceptance_rate": acceptance_rate,
        "confidence_thresholds": thresholds,
        "acceptance_by_confidence": tracking["acceptance_rate_by_confidence"],
        "total_decisions": total
    }


if __name__ == "__main__":
    # CLI interface for testing
    if len(sys.argv) < 2:
        print("Usage: gtd_smart_suggestions [command] [args...]")
        print("Commands:")
        print("  get-immediate          - Get high-confidence suggestions")
        print("  get-review             - Get medium-confidence suggestions")
        print("  create <suggestion_id> - Create task from suggestion")
        print("  dismiss <suggestion_id> - Dismiss a suggestion")
        print("  stats                  - Show acceptance statistics")
        print("  thresholds             - Show current thresholds")
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == "get-immediate":
        suggestions = get_immediate_suggestions()
        print(json.dumps({"suggestions": suggestions, "count": len(suggestions)}, indent=2))
    
    elif command == "get-review":
        suggestions = get_review_mode_suggestions()
        print(json.dumps({"suggestions": suggestions, "count": len(suggestions)}, indent=2))
    
    elif command == "create" and len(sys.argv) >= 3:
        suggestion_id = sys.argv[2]
        suggestion = load_suggestion(suggestion_id)
        if suggestion:
            success, message = create_task_from_suggestion(suggestion)
            print(json.dumps({"success": success, "message": message}))
        else:
            print(json.dumps({"success": False, "message": "Suggestion not found"}))
    
    elif command == "dismiss" and len(sys.argv) >= 3:
        suggestion_id = sys.argv[2]
        success = dismiss_suggestion(suggestion_id)
        print(json.dumps({"success": success}))
    
    elif command == "stats":
        stats = get_acceptance_statistics()
        print(json.dumps(stats, indent=2))
    
    elif command == "thresholds":
        thresholds = get_confidence_thresholds()
        print(json.dumps(thresholds, indent=2))
    
    else:
        print(f"Unknown command: {command}")
        sys.exit(1)
