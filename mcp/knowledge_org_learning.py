#!/usr/bin/env python3
"""
Knowledge Organization Learning System

Tracks which MoC/Area suggestions are accepted/rejected
and adjusts future suggestions based on user preferences.
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional
from collections import defaultdict

try:
    from gtd_mcp_server import GTD_BASE_DIR
except ImportError:
    GTD_BASE_DIR = Path.home() / "Documents" / "gtd"

LEARNING_FILE = GTD_BASE_DIR / "knowledge_org_learning.json"

# Default thresholds
DEFAULT_THRESHOLDS = {
    "area_assignment": 0.70,  # Min confidence for area assignments
    "moc_creation": 0.75,     # Min confidence for MoC suggestions
    "area_creation": 0.75,    # Min confidence for new area suggestions
}


def load_learning_data() -> Dict[str, Any]:
    """Load learning data from file."""
    if not LEARNING_FILE.exists():
        return {
            "version": "1.0",
            "thresholds": DEFAULT_THRESHOLDS.copy(),
            "decisions": [],
            "stats": {
                "area_assignment": {"accepted": 0, "rejected": 0},
                "moc_creation": {"accepted": 0, "rejected": 0},
                "area_creation": {"accepted": 0, "rejected": 0},
            },
            "patterns": {
                "accepted_areas": defaultdict(int),
                "rejected_areas": defaultdict(int),
                "accepted_moc_topics": defaultdict(int),
                "rejected_moc_topics": defaultdict(int),
            },
            "created": datetime.now().isoformat(),
            "last_updated": datetime.now().isoformat(),
        }
    
    try:
        with open(LEARNING_FILE, 'r') as f:
            data = json.load(f)
        
        # Ensure all fields exist
        if "thresholds" not in data:
            data["thresholds"] = DEFAULT_THRESHOLDS.copy()
        if "decisions" not in data:
            data["decisions"] = []
        if "stats" not in data:
            data["stats"] = {
                "area_assignment": {"accepted": 0, "rejected": 0},
                "moc_creation": {"accepted": 0, "rejected": 0},
                "area_creation": {"accepted": 0, "rejected": 0},
            }
        if "patterns" not in data:
            data["patterns"] = {
                "accepted_areas": {},
                "rejected_areas": {},
                "accepted_moc_topics": {},
                "rejected_moc_topics": {},
            }
        
        return data
    except Exception as e:
        print(f"Error loading learning data: {e}")
        return load_learning_data()  # Return defaults


def save_learning_data(data: Dict[str, Any]) -> bool:
    """Save learning data to file."""
    try:
        data["last_updated"] = datetime.now().isoformat()
        
        # Ensure directory exists
        LEARNING_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        with open(LEARNING_FILE, 'w') as f:
            json.dump(data, f, indent=2)
        
        return True
    except Exception as e:
        print(f"Error saving learning data: {e}")
        return False


def record_decision(
    suggestion_type: str,
    suggestion: Dict[str, Any],
    decision: str,  # "accepted", "rejected", "skipped"
    confidence: float
) -> bool:
    """Record a user decision about a suggestion.
    
    Args:
        suggestion_type: Type of suggestion (area_assignment, moc_creation, area_creation)
        suggestion: The suggestion dict
        decision: User decision (accepted, rejected, skipped)
        confidence: Confidence score of the suggestion
    
    Returns:
        True if recorded successfully
    """
    data = load_learning_data()
    
    # Record decision
    decision_record = {
        "timestamp": datetime.now().isoformat(),
        "type": suggestion_type,
        "decision": decision,
        "confidence": confidence,
        "suggestion": suggestion,
    }
    
    data["decisions"].append(decision_record)
    
    # Update stats
    if decision in ["accepted", "rejected"]:
        data["stats"][suggestion_type][decision] += 1
    
    # Update patterns
    if suggestion_type == "area_assignment":
        area_name = suggestion.get("suggested_area", "")
        if decision == "accepted":
            data["patterns"]["accepted_areas"][area_name] = \
                data["patterns"]["accepted_areas"].get(area_name, 0) + 1
        elif decision == "rejected":
            data["patterns"]["rejected_areas"][area_name] = \
                data["patterns"]["rejected_areas"].get(area_name, 0) + 1
    
    elif suggestion_type == "moc_creation":
        moc_name = suggestion.get("moc_name", "")
        if decision == "accepted":
            data["patterns"]["accepted_moc_topics"][moc_name] = \
                data["patterns"]["accepted_moc_topics"].get(moc_name, 0) + 1
        elif decision == "rejected":
            data["patterns"]["rejected_moc_topics"][moc_name] = \
                data["patterns"]["rejected_moc_topics"].get(moc_name, 0) + 1
    
    elif suggestion_type == "area_creation":
        area_name = suggestion.get("area_name", "")
        if decision == "accepted":
            data["patterns"]["accepted_areas"][area_name] = \
                data["patterns"]["accepted_areas"].get(area_name, 0) + 1
        elif decision == "rejected":
            data["patterns"]["rejected_areas"][area_name] = \
                data["patterns"]["rejected_areas"].get(area_name, 0) + 1
    
    # Adjust thresholds based on decisions
    adjust_thresholds(data)
    
    # Keep only last 1000 decisions
    if len(data["decisions"]) > 1000:
        data["decisions"] = data["decisions"][-1000:]
    
    return save_learning_data(data)


def adjust_thresholds(data: Dict[str, Any]) -> None:
    """Adjust confidence thresholds based on acceptance patterns.
    
    Logic:
    - If acceptance rate > 90%, lower threshold (more suggestions)
    - If acceptance rate < 50%, raise threshold (fewer, better suggestions)
    """
    for suggestion_type in ["area_assignment", "moc_creation", "area_creation"]:
        stats = data["stats"][suggestion_type]
        total = stats["accepted"] + stats["rejected"]
        
        if total < 10:  # Need at least 10 decisions to adjust
            continue
        
        acceptance_rate = stats["accepted"] / total if total > 0 else 0.5
        current_threshold = data["thresholds"][suggestion_type]
        
        # Adjust threshold
        if acceptance_rate > 0.90:
            # User accepts almost everything - lower threshold by 5%
            new_threshold = max(0.50, current_threshold - 0.05)
        elif acceptance_rate < 0.50:
            # User rejects more than half - raise threshold by 5%
            new_threshold = min(0.95, current_threshold + 0.05)
        else:
            # Acceptance rate is good - keep threshold
            new_threshold = current_threshold
        
        data["thresholds"][suggestion_type] = round(new_threshold, 2)


def get_acceptance_rate(suggestion_type: str) -> float:
    """Get acceptance rate for a suggestion type."""
    data = load_learning_data()
    stats = data["stats"][suggestion_type]
    total = stats["accepted"] + stats["rejected"]
    
    if total == 0:
        return 0.0
    
    return stats["accepted"] / total


def get_stats_summary() -> Dict[str, Any]:
    """Get a summary of learning statistics."""
    data = load_learning_data()
    
    summary = {
        "thresholds": data["thresholds"],
        "total_decisions": len(data["decisions"]),
        "stats": data["stats"],
        "acceptance_rates": {},
        "top_accepted_areas": [],
        "top_rejected_areas": [],
        "top_accepted_moc_topics": [],
        "top_rejected_moc_topics": [],
    }
    
    # Calculate acceptance rates
    for suggestion_type in ["area_assignment", "moc_creation", "area_creation"]:
        summary["acceptance_rates"][suggestion_type] = get_acceptance_rate(suggestion_type)
    
    # Top patterns
    accepted_areas = data["patterns"].get("accepted_areas", {})
    rejected_areas = data["patterns"].get("rejected_areas", {})
    accepted_mocs = data["patterns"].get("accepted_moc_topics", {})
    rejected_mocs = data["patterns"].get("rejected_moc_topics", {})
    
    summary["top_accepted_areas"] = sorted(
        accepted_areas.items(), key=lambda x: x[1], reverse=True
    )[:5]
    
    summary["top_rejected_areas"] = sorted(
        rejected_areas.items(), key=lambda x: x[1], reverse=True
    )[:5]
    
    summary["top_accepted_moc_topics"] = sorted(
        accepted_mocs.items(), key=lambda x: x[1], reverse=True
    )[:5]
    
    summary["top_rejected_moc_topics"] = sorted(
        rejected_mocs.items(), key=lambda x: x[1], reverse=True
    )[:5]
    
    return summary


def should_show_suggestion(suggestion_type: str, confidence: float) -> bool:
    """Check if a suggestion should be shown based on learned thresholds.
    
    Args:
        suggestion_type: Type of suggestion
        confidence: Confidence score
    
    Returns:
        True if suggestion should be shown
    """
    data = load_learning_data()
    threshold = data["thresholds"].get(suggestion_type, DEFAULT_THRESHOLDS[suggestion_type])
    return confidence >= threshold


def filter_suggestions(suggestions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """Filter suggestions based on learned thresholds.
    
    Args:
        suggestions: List of suggestions with 'type' and 'confidence' fields
    
    Returns:
        Filtered list of suggestions
    """
    filtered = []
    
    for suggestion in suggestions:
        suggestion_type = suggestion.get("type")
        confidence = suggestion.get("confidence", 0.0)
        
        if should_show_suggestion(suggestion_type, confidence):
            filtered.append(suggestion)
    
    return filtered


def boost_confidence_for_patterns(suggestion: Dict[str, Any]) -> float:
    """Boost confidence score based on learned patterns.
    
    If user has accepted similar suggestions before, boost confidence.
    If user has rejected similar suggestions before, reduce confidence.
    
    Args:
        suggestion: Suggestion dict
    
    Returns:
        Adjusted confidence score
    """
    data = load_learning_data()
    confidence = suggestion.get("confidence", 0.0)
    suggestion_type = suggestion.get("type")
    
    # Area assignment boost
    if suggestion_type == "area_assignment":
        area_name = suggestion.get("suggested_area", "")
        accepted_count = data["patterns"]["accepted_areas"].get(area_name, 0)
        rejected_count = data["patterns"]["rejected_areas"].get(area_name, 0)
        
        if accepted_count > rejected_count:
            # User likes this area - boost confidence
            boost = min(0.10, accepted_count * 0.02)
            confidence = min(1.0, confidence + boost)
        elif rejected_count > accepted_count:
            # User doesn't like this area - reduce confidence
            penalty = min(0.10, rejected_count * 0.02)
            confidence = max(0.0, confidence - penalty)
    
    # MoC creation boost
    elif suggestion_type == "moc_creation":
        moc_name = suggestion.get("moc_name", "")
        # Extract topic from MoC name (simple keyword matching)
        topics = moc_name.lower().split()
        
        for topic in topics:
            for accepted_moc, count in data["patterns"]["accepted_moc_topics"].items():
                if topic in accepted_moc.lower():
                    boost = min(0.05, count * 0.01)
                    confidence = min(1.0, confidence + boost)
                    break
    
    return round(confidence, 2)


def reset_learning() -> bool:
    """Reset learning data to defaults."""
    if LEARNING_FILE.exists():
        # Backup old file
        backup_file = LEARNING_FILE.parent / f"knowledge_org_learning_backup_{datetime.now().strftime('%Y%m%d%H%M%S')}.json"
        LEARNING_FILE.rename(backup_file)
    
    # Create fresh learning data
    data = load_learning_data()
    return save_learning_data(data)


def main():
    """CLI for learning system."""
    import argparse
    
    parser = argparse.ArgumentParser(description="Knowledge Organization Learning System")
    parser.add_argument('command', choices=['stats', 'reset'], help='Command to run')
    args = parser.parse_args()
    
    if args.command == 'stats':
        summary = get_stats_summary()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 Knowledge Organization Learning Stats")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        
        print("Confidence Thresholds:")
        for stype, threshold in summary["thresholds"].items():
            print(f"  {stype}: {threshold:.0%}")
        print()
        
        print("Total Decisions:", summary["total_decisions"])
        print()
        
        print("Statistics by Type:")
        for stype, stats in summary["stats"].items():
            total = stats["accepted"] + stats["rejected"]
            rate = summary["acceptance_rates"][stype]
            print(f"  {stype}:")
            print(f"    Accepted: {stats['accepted']}")
            print(f"    Rejected: {stats['rejected']}")
            print(f"    Acceptance Rate: {rate:.0%}")
        print()
        
        if summary["top_accepted_areas"]:
            print("Top Accepted Areas:")
            for area, count in summary["top_accepted_areas"]:
                print(f"  • {area}: {count}x")
            print()
        
        if summary["top_accepted_moc_topics"]:
            print("Top Accepted MoC Topics:")
            for topic, count in summary["top_accepted_moc_topics"]:
                print(f"  • {topic}: {count}x")
            print()
    
    elif args.command == 'reset':
        print("Resetting learning data...")
        if reset_learning():
            print("✓ Learning data reset to defaults")
        else:
            print("❌ Failed to reset learning data")


if __name__ == "__main__":
    main()

