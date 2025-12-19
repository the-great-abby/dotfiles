#!/usr/bin/env python3
"""
Task Suggestions - Unified Learning Adapter

Adapter to make gtd_smart_suggestions.py use the unified learning system.
This provides backward compatibility while migrating to unified learning.
"""

from typing import Dict, Any
from gtd_unified_learning import (
    record_decision as unified_record,
    should_show_suggestion,
    boost_confidence_for_patterns,
    get_acceptance_rate,
)

def track_suggestion_decision(
    suggestion_id: str,
    confidence: float,
    decision: str,
    auto_created: bool = False
) -> bool:
    """Track a task suggestion decision using unified learning.
    
    Adapter for gtd_smart_suggestions compatibility.
    """
    # Determine suggestion type based on confidence and auto_created flag
    if auto_created or confidence >= 0.90:
        suggestion_type = "task_from_log_auto"
    elif confidence >= 0.85:
        suggestion_type = "task_from_log_high"
    else:
        suggestion_type = "task_from_log"
    
    # Record in unified system
    return unified_record(
        suggestion_type=suggestion_type,
        suggestion={"id": suggestion_id},
        decision=decision,
        confidence=confidence,
        context=None,  # Could extract from suggestion
        tags=[]  # Could extract from suggestion
    )


def calculate_optimal_thresholds() -> Dict[str, float]:
    """Calculate optimal thresholds - adapter for compatibility."""
    from gtd_unified_learning import load_learning_data
    
    data = load_learning_data()
    
    return {
        "high": data["thresholds"].get("task_from_log_high", 0.85),
        "medium": data["thresholds"].get("task_from_log", 0.60),
        "auto_create": data["thresholds"].get("task_from_log_auto", 0.90),
    }


def get_high_confidence_threshold() -> float:
    """Get high confidence threshold."""
    return calculate_optimal_thresholds()["high"]


def get_medium_confidence_threshold() -> float:
    """Get medium confidence threshold."""
    return calculate_optimal_thresholds()["medium"]


def get_auto_create_threshold() -> float:
    """Get auto-create threshold."""
    return calculate_optimal_thresholds()["auto_create"]

