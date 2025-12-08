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
    if medium_acceptance_buckets:
        new_thresholds["medium"] = min(c for c, rate in medium_acceptance_buckets)
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


def create_task_from_suggestion(suggestion: Dict[str, Any]) -> Tuple[bool, str]:
    """
    Create a task from a suggestion.
    
    Returns:
        (success, message)
    """
    import subprocess
    
    title = suggestion.get("title", "")
    context = suggestion.get("context", "computer")
    priority = suggestion.get("priority", "not_urgent_important")
    project = suggestion.get("suggested_project", "")
    
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
            
            return True, f"Task created: {title}"
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
