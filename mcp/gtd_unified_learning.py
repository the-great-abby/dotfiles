#!/usr/bin/env python3
"""
GTD Unified Learning System

A single learning system that tracks decisions across ALL suggestion types:
- Task suggestions from daily logs
- Area assignments from projects
- MoC creation from notes
- Area creation from themes
- Project suggestions from tasks
- Insights from deep analysis

Features:
- Unified decision tracking
- Per-type confidence thresholds
- Pattern recognition across domains
- Cross-domain insights
- Single stats dashboard
"""

import json
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional, Tuple
from collections import defaultdict

# Don't import from gtd_mcp_server to avoid mcp package dependency
GTD_BASE_DIR = Path.home() / "Documents" / "gtd"

# Try to read GTD_BASE_DIR from config if available
gtd_config_file = Path.home() / "code" / "dotfiles" / "zsh" / ".gtd_config"
if gtd_config_file.exists():
    try:
        with open(gtd_config_file) as f:
            for line in f:
                if line.strip().startswith("GTD_BASE_DIR="):
                    value = line.split("=", 1)[1].strip().strip('"').strip("'")
                    GTD_BASE_DIR = Path(value.replace("$HOME", str(Path.home())))
                    break
    except Exception:
        pass

LEARNING_FILE = GTD_BASE_DIR / "unified_learning.json"

# Suggestion types
SUGGESTION_TYPES = {
    "task_from_log": {
        "name": "Task from Log",
        "default_threshold": 0.60,
        "description": "Tasks suggested from daily log entries"
    },
    "task_from_log_high": {
        "name": "Task from Log (High Confidence)",
        "default_threshold": 0.85,
        "description": "High-confidence tasks (auto-create)"
    },
    "task_from_log_auto": {
        "name": "Task from Log (Auto-Create)",
        "default_threshold": 0.90,
        "description": "Very high confidence tasks (immediate creation)"
    },
    "area_assignment": {
        "name": "Area Assignment",
        "default_threshold": 0.70,
        "description": "Assigning projects to areas"
    },
    "moc_creation": {
        "name": "MoC Creation",
        "default_threshold": 0.75,
        "description": "Creating Maps of Content"
    },
    "area_creation": {
        "name": "Area Creation",
        "default_threshold": 0.75,
        "description": "Creating new areas of responsibility"
    },
    "project_suggestion": {
        "name": "Project Suggestion",
        "default_threshold": 0.70,
        "description": "Suggesting projects from related tasks"
    },
    "insight": {
        "name": "Insight",
        "default_threshold": 0.65,
        "description": "Insights from deep analysis"
    },
}

# Threshold adjustment settings
MIN_DECISIONS_FOR_ADJUSTMENT = 10
THRESHOLD_ADJUSTMENT_STEP = 0.05
MIN_THRESHOLD = 0.50
MAX_THRESHOLD = 0.95
CONFIDENCE_BOOST_MAX = 0.10
CONFIDENCE_PENALTY_MAX = 0.10

# Decision history limit
MAX_DECISIONS_STORED = 2000


def get_default_learning_data() -> Dict[str, Any]:
    """Get default learning data structure."""
    return {
        "version": "2.0",  # Unified version
        "created": datetime.now().isoformat(),
        "last_updated": datetime.now().isoformat(),
        "thresholds": {
            stype: info["default_threshold"]
            for stype, info in SUGGESTION_TYPES.items()
        },
        "decisions": [],
        "stats": {
            stype: {"accepted": 0, "rejected": 0, "skipped": 0}
            for stype in SUGGESTION_TYPES.keys()
        },
        "patterns": {
            "accepted_by_context": defaultdict(int),
            "rejected_by_context": defaultdict(int),
            "accepted_by_tag": defaultdict(int),
            "rejected_by_tag": defaultdict(int),
        },
        "metadata": {
            "suggestion_types": SUGGESTION_TYPES
        }
    }


def load_learning_data() -> Dict[str, Any]:
    """Load unified learning data from file."""
    if not LEARNING_FILE.exists():
        return get_default_learning_data()
    
    try:
        with open(LEARNING_FILE, 'r') as f:
            data = json.load(f)
        
        # Ensure all suggestion types exist
        if "thresholds" not in data:
            data["thresholds"] = {}
        
        for stype, info in SUGGESTION_TYPES.items():
            if stype not in data["thresholds"]:
                data["thresholds"][stype] = info["default_threshold"]
        
        # Ensure stats exist
        if "stats" not in data:
            data["stats"] = {}
        
        for stype in SUGGESTION_TYPES.keys():
            if stype not in data["stats"]:
                data["stats"][stype] = {"accepted": 0, "rejected": 0, "skipped": 0}
        
        # Ensure patterns exist
        if "patterns" not in data:
            data["patterns"] = {
                "accepted_by_context": {},
                "rejected_by_context": {},
                "accepted_by_tag": {},
                "rejected_by_tag": {},
            }
        
        # Ensure decisions list exists
        if "decisions" not in data:
            data["decisions"] = []
        
        return data
    except Exception as e:
        print(f"Error loading learning data: {e}")
        return get_default_learning_data()


def save_learning_data(data: Dict[str, Any]) -> bool:
    """Save unified learning data to file."""
    try:
        data["last_updated"] = datetime.now().isoformat()
        
        # Convert defaultdicts to regular dicts for JSON serialization
        if "patterns" in data:
            for key in data["patterns"]:
                if isinstance(data["patterns"][key], defaultdict):
                    data["patterns"][key] = dict(data["patterns"][key])
        
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
    decision: str,
    confidence: float,
    context: Optional[str] = None,
    tags: Optional[List[str]] = None,
    rating: Optional[int] = None,
    feedback_reason: Optional[str] = None
) -> bool:
    """Record a user decision about a suggestion.
    
    Args:
        suggestion_type: Type of suggestion (from SUGGESTION_TYPES)
        suggestion: The suggestion dict
        decision: User decision (accepted, rejected, skipped, rated)
        confidence: Confidence score (0.0-1.0)
        context: Optional context (e.g., area name, project slug)
        tags: Optional list of tags
        rating: Optional rating (1-5 stars) for nuanced feedback
        feedback_reason: Optional reason for rejection/rating
    
    Returns:
        True if recorded successfully
    """
    if suggestion_type not in SUGGESTION_TYPES:
        print(f"Warning: Unknown suggestion type: {suggestion_type}")
        return False
    
    data = load_learning_data()
    
    # Record decision
    decision_record = {
        "id": suggestion.get("id", f"decision-{len(data['decisions'])}"),
        "timestamp": datetime.now().isoformat(),
        "type": suggestion_type,
        "decision": decision,
        "confidence": confidence,
        "context": context,
        "tags": tags or [],
        "rating": rating,
        "feedback_reason": feedback_reason,
        "suggestion": suggestion,
    }
    
    data["decisions"].append(decision_record)
    
    # Update stats
    if decision in ["accepted", "rejected", "skipped"]:
        data["stats"][suggestion_type][decision] += 1
    elif decision == "rated" and rating:
        # Treat high ratings (4-5) as accepted, low (1-2) as rejected
        if rating >= 4:
            data["stats"][suggestion_type]["accepted"] += 1
        elif rating <= 2:
            data["stats"][suggestion_type]["rejected"] += 1
        # Rating 3 is neutral, don't count either way
    
    # Update patterns
    if context:
        if decision == "accepted":
            data["patterns"]["accepted_by_context"][context] = \
                data["patterns"]["accepted_by_context"].get(context, 0) + 1
        elif decision == "rejected":
            data["patterns"]["rejected_by_context"][context] = \
                data["patterns"]["rejected_by_context"].get(context, 0) + 1
    
    if tags:
        for tag in tags:
            if decision == "accepted":
                data["patterns"]["accepted_by_tag"][tag] = \
                    data["patterns"]["accepted_by_tag"].get(tag, 0) + 1
            elif decision == "rejected":
                data["patterns"]["rejected_by_tag"][tag] = \
                    data["patterns"]["rejected_by_tag"].get(tag, 0) + 1
    
    # Adjust thresholds
    adjust_thresholds(data)
    
    # Limit decision history
    if len(data["decisions"]) > MAX_DECISIONS_STORED:
        data["decisions"] = data["decisions"][-MAX_DECISIONS_STORED:]
    
    return save_learning_data(data)


def adjust_thresholds(data: Dict[str, Any]) -> None:
    """Adjust confidence thresholds based on acceptance patterns."""
    for suggestion_type in SUGGESTION_TYPES.keys():
        stats = data["stats"][suggestion_type]
        total = stats["accepted"] + stats["rejected"]
        
        if total < MIN_DECISIONS_FOR_ADJUSTMENT:
            continue
        
        acceptance_rate = stats["accepted"] / total if total > 0 else 0.5
        current_threshold = data["thresholds"][suggestion_type]
        
        # Adjust threshold based on acceptance rate
        if acceptance_rate > 0.90:
            # User accepts almost everything - lower threshold
            new_threshold = max(MIN_THRESHOLD, current_threshold - THRESHOLD_ADJUSTMENT_STEP)
        elif acceptance_rate < 0.50:
            # User rejects more than half - raise threshold
            new_threshold = min(MAX_THRESHOLD, current_threshold + THRESHOLD_ADJUSTMENT_STEP)
        else:
            # Good acceptance rate - keep threshold
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


def should_show_suggestion(suggestion_type: str, confidence: float) -> bool:
    """Check if a suggestion should be shown based on learned threshold."""
    if suggestion_type not in SUGGESTION_TYPES:
        return True  # Unknown types always shown
    
    data = load_learning_data()
    threshold = data["thresholds"].get(
        suggestion_type,
        SUGGESTION_TYPES[suggestion_type]["default_threshold"]
    )
    return confidence >= threshold


def boost_confidence_for_patterns(
    suggestion_type: str,
    confidence: float,
    context: Optional[str] = None,
    tags: Optional[List[str]] = None,
    explain: bool = False
) -> Tuple[float, Optional[Dict[str, Any]]]:
    """Boost confidence score based on learned patterns.
    
    Args:
        suggestion_type: Type of suggestion
        confidence: Original confidence score
        context: Optional context (area, project, etc.)
        tags: Optional tags
        explain: If True, return explanation dict
    
    Returns:
        Tuple of (adjusted confidence, explanation dict if explain=True)
    """
    data = load_learning_data()
    adjusted_confidence = confidence
    
    # Build explanation if requested
    explanation = {
        "original_confidence": confidence,
        "adjustments": [],
        "final_confidence": confidence,
        "reasoning": []
    } if explain else None
    
    # Boost/penalty for context
    context_boost = 0.0
    if context:
        accepted_count = data["patterns"]["accepted_by_context"].get(context, 0)
        rejected_count = data["patterns"]["rejected_by_context"].get(context, 0)
        
        if accepted_count > rejected_count:
            boost = min(CONFIDENCE_BOOST_MAX, accepted_count * 0.02)
            context_boost = boost
            adjusted_confidence = min(1.0, adjusted_confidence + boost)
            if explain:
                explanation["adjustments"].append({
                    "type": "context_boost",
                    "value": f"+{boost:.0%}",
                    "reason": f"You've accepted '{context}' {accepted_count}x before"
                })
                explanation["reasoning"].append(f"Pattern match: '{context}' frequently accepted")
        elif rejected_count > accepted_count:
            penalty = min(CONFIDENCE_PENALTY_MAX, rejected_count * 0.02)
            context_boost = -penalty
            adjusted_confidence = max(0.0, adjusted_confidence - penalty)
            if explain:
                explanation["adjustments"].append({
                    "type": "context_penalty",
                    "value": f"-{penalty:.0%}",
                    "reason": f"You've rejected '{context}' {rejected_count}x before"
                })
                explanation["reasoning"].append(f"Pattern match: '{context}' frequently rejected")
    
    # Boost/penalty for tags
    tag_boost = 0.0
    if tags:
        tag_adjustments = []
        for tag in tags:
            accepted_count = data["patterns"]["accepted_by_tag"].get(tag, 0)
            rejected_count = data["patterns"]["rejected_by_tag"].get(tag, 0)
            
            if accepted_count > rejected_count:
                tag_boost += 0.01 * accepted_count
                if explain:
                    tag_adjustments.append(f"#{tag}: +{0.01 * accepted_count:.0%} ({accepted_count}x accepted)")
            elif rejected_count > accepted_count:
                tag_boost -= 0.01 * rejected_count
                if explain:
                    tag_adjustments.append(f"#{tag}: -{0.01 * rejected_count:.0%} ({rejected_count}x rejected)")
        
        tag_boost = max(-CONFIDENCE_PENALTY_MAX, min(CONFIDENCE_BOOST_MAX, tag_boost))
        adjusted_confidence = max(0.0, min(1.0, adjusted_confidence + tag_boost))
        
        if explain and tag_adjustments:
            explanation["adjustments"].append({
                "type": "tag_boost" if tag_boost > 0 else "tag_penalty",
                "value": f"{tag_boost:+.0%}",
                "reason": ", ".join(tag_adjustments)
            })
            if tag_boost > 0:
                explanation["reasoning"].append("Tags match your interests")
            else:
                explanation["reasoning"].append("Tags don't match your interests")
    
    if explain:
        explanation["final_confidence"] = adjusted_confidence
        return round(adjusted_confidence, 2), explanation
    
    return round(adjusted_confidence, 2), None


def filter_suggestions(
    suggestions: List[Dict[str, Any]],
    suggestion_type: str
) -> List[Dict[str, Any]]:
    """Filter suggestions based on learned thresholds.
    
    Args:
        suggestions: List of suggestions with 'confidence' field
        suggestion_type: Type of suggestions
    
    Returns:
        Filtered list of suggestions
    """
    return [
        s for s in suggestions
        if should_show_suggestion(suggestion_type, s.get("confidence", 0.0))
    ]


def get_stats_summary(suggestion_type: Optional[str] = None) -> Dict[str, Any]:
    """Get learning statistics summary.
    
    Args:
        suggestion_type: Optional type to filter by, or None for all
    
    Returns:
        Stats summary dict
    """
    data = load_learning_data()
    
    # Calculate stats for requested type(s)
    types_to_show = [suggestion_type] if suggestion_type else list(SUGGESTION_TYPES.keys())
    
    summary = {
        "total_decisions": len(data["decisions"]),
        "types": {},
        "overall_acceptance_rate": 0.0,
        "top_accepted_contexts": [],
        "top_rejected_contexts": [],
        "top_accepted_tags": [],
        "top_rejected_tags": [],
    }
    
    # Per-type stats
    total_accepted = 0
    total_rejected = 0
    
    for stype in types_to_show:
        if stype not in data["stats"]:
            continue
        
        stats = data["stats"][stype]
        total = stats["accepted"] + stats["rejected"]
        rate = stats["accepted"] / total if total > 0 else 0.0
        
        total_accepted += stats["accepted"]
        total_rejected += stats["rejected"]
        
        summary["types"][stype] = {
            "name": SUGGESTION_TYPES[stype]["name"],
            "threshold": data["thresholds"].get(stype, 0.0),
            "accepted": stats["accepted"],
            "rejected": stats["rejected"],
            "skipped": stats["skipped"],
            "total": total,
            "acceptance_rate": rate,
        }
    
    # Overall acceptance rate
    total_overall = total_accepted + total_rejected
    summary["overall_acceptance_rate"] = total_accepted / total_overall if total_overall > 0 else 0.0
    
    # Top patterns
    accepted_contexts = data["patterns"].get("accepted_by_context", {})
    rejected_contexts = data["patterns"].get("rejected_by_context", {})
    accepted_tags = data["patterns"].get("accepted_by_tag", {})
    rejected_tags = data["patterns"].get("rejected_by_tag", {})
    
    summary["top_accepted_contexts"] = sorted(
        accepted_contexts.items(), key=lambda x: x[1], reverse=True
    )[:10]
    
    summary["top_rejected_contexts"] = sorted(
        rejected_contexts.items(), key=lambda x: x[1], reverse=True
    )[:10]
    
    summary["top_accepted_tags"] = sorted(
        accepted_tags.items(), key=lambda x: x[1], reverse=True
    )[:10]
    
    summary["top_rejected_tags"] = sorted(
        rejected_tags.items(), key=lambda x: x[1], reverse=True
    )[:10]
    
    return summary


def get_cross_domain_insights() -> List[str]:
    """Get insights that span multiple suggestion types."""
    data = load_learning_data()
    insights = []
    
    # Check for cross-domain patterns
    work_related = ["work-sre", "work", "sre", "kubernetes", "monitoring"]
    personal_related = ["health", "fitness", "home", "personal"]
    
    accepted_contexts = data["patterns"].get("accepted_by_context", {})
    
    # Work vs personal preference
    work_accepts = sum(accepted_contexts.get(ctx, 0) for ctx in work_related if ctx in accepted_contexts)
    personal_accepts = sum(accepted_contexts.get(ctx, 0) for ctx in personal_related if ctx in accepted_contexts)
    
    if work_accepts > personal_accepts * 2:
        insights.append(f"You focus heavily on work-related organization ({work_accepts} work vs {personal_accepts} personal accepts)")
    elif personal_accepts > work_accepts * 2:
        insights.append(f"You focus heavily on personal life organization ({personal_accepts} personal vs {work_accepts} work accepts)")
    
    # Overall engagement
    total_decisions = len(data["decisions"])
    if total_decisions > 100:
        insights.append(f"You're an active user with {total_decisions} decisions tracked")
    elif total_decisions > 50:
        insights.append(f"You're building good habits with {total_decisions} decisions tracked")
    
    # Acceptance patterns
    overall_rate = get_stats_summary()["overall_acceptance_rate"]
    if overall_rate > 0.85:
        insights.append(f"You accept most suggestions ({overall_rate:.0%}) - system is well-tuned to your needs")
    elif overall_rate < 0.50:
        insights.append(f"You reject many suggestions ({1-overall_rate:.0%}) - thresholds are being adjusted")
    
    return insights


def set_threshold(suggestion_type: str, threshold: float) -> bool:
    """Manually set threshold for a suggestion type.
    
    Args:
        suggestion_type: Type of suggestion
        threshold: New threshold (0.0-1.0)
    
    Returns:
        True if successful
    """
    if suggestion_type not in SUGGESTION_TYPES:
        print(f"Unknown suggestion type: {suggestion_type}")
        return False
    
    if not (0.0 <= threshold <= 1.0):
        print(f"Threshold must be between 0.0 and 1.0")
        return False
    
    data = load_learning_data()
    data["thresholds"][suggestion_type] = round(threshold, 2)
    
    return save_learning_data(data)


def adjust_threshold(suggestion_type: str, adjustment: str) -> bool:
    """Adjust threshold up or down.
    
    Args:
        suggestion_type: Type of suggestion
        adjustment: "more" (lower threshold) or "less" (raise threshold)
    
    Returns:
        True if successful
    """
    data = load_learning_data()
    current = data["thresholds"].get(suggestion_type, 0.70)
    
    if adjustment == "more":
        new_threshold = max(MIN_THRESHOLD, current - 0.05)
    elif adjustment == "less":
        new_threshold = min(MAX_THRESHOLD, current + 0.05)
    else:
        print(f"Invalid adjustment: {adjustment} (use 'more' or 'less')")
        return False
    
    data["thresholds"][suggestion_type] = round(new_threshold, 2)
    print(f"Adjusted {SUGGESTION_TYPES[suggestion_type]['name']} threshold: {current:.0%} → {new_threshold:.0%}")
    
    return save_learning_data(data)


def reset_learning(backup: bool = True) -> bool:
    """Reset learning data to defaults.
    
    Args:
        backup: Whether to backup old file
    
    Returns:
        True if reset successful
    """
    if LEARNING_FILE.exists() and backup:
        backup_file = LEARNING_FILE.parent / f"unified_learning_backup_{datetime.now().strftime('%Y%m%d%H%M%S')}.json"
        LEARNING_FILE.rename(backup_file)
        print(f"Backed up to: {backup_file}")
    
    data = get_default_learning_data()
    return save_learning_data(data)


def main():
    """CLI for unified learning system."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Unified Learning System")
    parser.add_argument('command', choices=['stats', 'insights', 'reset'], help='Command to run')
    parser.add_argument('--type', help='Filter by suggestion type')
    args = parser.parse_args()
    
    if args.command == 'stats':
        summary = get_stats_summary(args.type)
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📊 GTD Unified Learning Stats")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        
        print(f"Total Decisions: {summary['total_decisions']}")
        print(f"Overall Acceptance Rate: {summary['overall_acceptance_rate']:.0%}")
        print()
        
        print("By Suggestion Type:")
        for stype, stats in summary["types"].items():
            if stats["total"] == 0:
                continue
            print(f"\n  {stats['name']}:")
            print(f"    Threshold: {stats['threshold']:.0%}")
            print(f"    Accepted: {stats['accepted']}")
            print(f"    Rejected: {stats['rejected']}")
            print(f"    Acceptance Rate: {stats['acceptance_rate']:.0%}")
        print()
        
        if summary["top_accepted_contexts"]:
            print("Top Accepted Contexts:")
            for context, count in summary["top_accepted_contexts"][:5]:
                print(f"  • {context}: {count}x")
            print()
    
    elif args.command == 'insights':
        insights = get_cross_domain_insights()
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("💡 Cross-Domain Insights")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print()
        
        if insights:
            for insight in insights:
                print(f"  • {insight}")
        else:
            print("  Not enough data yet for insights")
        print()
    
    elif args.command == 'reset':
        print("Resetting unified learning data...")
        if reset_learning():
            print("✓ Learning data reset to defaults")
        else:
            print("❌ Failed to reset learning data")


if __name__ == "__main__":
    main()

