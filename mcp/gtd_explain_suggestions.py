#!/usr/bin/env python3
"""
Suggestion Explainability Helper

Provides human-readable explanations for why suggestions were made
and how confidence scores were calculated.
"""

from typing import Dict, Any, List
from gtd_unified_learning import boost_confidence_for_patterns, load_learning_data


def explain_suggestion(
    suggestion_type: str,
    confidence: float,
    context: str = None,
    tags: List[str] = None
) -> str:
    """Generate human-readable explanation for a suggestion.
    
    Args:
        suggestion_type: Type of suggestion
        confidence: Original confidence score
        context: Optional context
        tags: Optional tags
    
    Returns:
        Formatted explanation string
    """
    # Get adjusted confidence with explanation
    adjusted_confidence, explanation = boost_confidence_for_patterns(
        suggestion_type=suggestion_type,
        confidence=confidence,
        context=context,
        tags=tags,
        explain=True
    )
    
    if not explanation:
        return f"Confidence: {confidence:.0%}"
    
    lines = []
    lines.append(f"📊 Confidence Analysis:")
    lines.append(f"  Original: {explanation['original_confidence']:.0%}")
    
    if explanation['adjustments']:
        lines.append(f"  Adjustments:")
        for adj in explanation['adjustments']:
            lines.append(f"    {adj['value']} - {adj['reason']}")
    
    lines.append(f"  Final: {explanation['final_confidence']:.0%}")
    
    if explanation['reasoning']:
        lines.append(f"")
        lines.append(f"💡 Why this suggestion:")
        for reason in explanation['reasoning']:
            lines.append(f"  • {reason}")
    
    return "\n".join(lines)


def explain_threshold(suggestion_type: str) -> str:
    """Explain current threshold for a suggestion type.
    
    Args:
        suggestion_type: Type of suggestion
    
    Returns:
        Formatted explanation
    """
    from gtd_unified_learning import SUGGESTION_TYPES, get_acceptance_rate
    
    data = load_learning_data()
    threshold = data["thresholds"].get(suggestion_type, 0.70)
    default = SUGGESTION_TYPES[suggestion_type]["default_threshold"]
    acceptance_rate = get_acceptance_rate(suggestion_type)
    stats = data["stats"].get(suggestion_type, {})
    
    lines = []
    lines.append(f"🎚️  Threshold for {SUGGESTION_TYPES[suggestion_type]['name']}:")
    lines.append(f"  Current: {threshold:.0%}")
    lines.append(f"  Default: {default:.0%}")
    
    if threshold != default:
        if threshold < default:
            lines.append(f"  Status: Lowered (showing more suggestions)")
            lines.append(f"  Reason: High acceptance rate ({acceptance_rate:.0%})")
        else:
            lines.append(f"  Status: Raised (showing fewer, better suggestions)")
            lines.append(f"  Reason: Low acceptance rate ({acceptance_rate:.0%})")
    else:
        lines.append(f"  Status: Default (not yet adjusted)")
    
    lines.append(f"")
    lines.append(f"  Stats: {stats.get('accepted', 0)} accepted, {stats.get('rejected', 0)} rejected")
    lines.append(f"  Acceptance rate: {acceptance_rate:.0%}")
    
    return "\n".join(lines)


def explain_decision_impact(
    suggestion_type: str,
    decision: str,
    context: str = None
) -> str:
    """Explain how a decision will impact future suggestions.
    
    Args:
        suggestion_type: Type of suggestion
        decision: Decision made (accepted/rejected/rated)
        context: Optional context
    
    Returns:
        Formatted explanation
    """
    from gtd_unified_learning import SUGGESTION_TYPES
    
    lines = []
    lines.append(f"🔮 Impact of this decision:")
    
    if decision == "accepted":
        lines.append(f"  ✓ Similar suggestions will get +confidence boost")
        if context:
            lines.append(f"  ✓ Future '{context}' suggestions prioritized")
        lines.append(f"  ✓ If you accept >90%, threshold will lower (more suggestions)")
    
    elif decision == "rejected":
        lines.append(f"  ✗ Similar suggestions will get -confidence penalty")
        if context:
            lines.append(f"  ✗ Future '{context}' suggestions deprioritized")
        lines.append(f"  ✗ If you reject >50%, threshold will raise (fewer suggestions)")
    
    elif decision.startswith("rated"):
        lines.append(f"  ⭐ Rating recorded for nuanced learning")
        lines.append(f"  ⭐ High ratings (4-5) boost similar suggestions")
        lines.append(f"  ⭐ Low ratings (1-2) reduce similar suggestions")
        lines.append(f"  ⭐ Mid ratings (3) provide feedback without strong signal")
    
    return "\n".join(lines)


def format_suggestion_with_explanation(
    suggestion: Dict[str, Any],
    show_full_explanation: bool = False
) -> str:
    """Format a suggestion with its explanation.
    
    Args:
        suggestion: Suggestion dict
        show_full_explanation: If True, show detailed explanation
    
    Returns:
        Formatted string
    """
    lines = []
    
    # Main suggestion
    suggestion_type = suggestion.get("type", "unknown")
    confidence = suggestion.get("confidence", 0.0)
    original_confidence = suggestion.get("original_confidence", confidence)
    
    # Format based on type
    if suggestion_type == "area_assignment":
        project_name = suggestion.get("project_name", "Unknown")
        area = suggestion.get("suggested_area", "Unknown")
        lines.append(f"📁 Assign '{project_name}' to '{area}'")
    
    elif suggestion_type == "moc_creation":
        moc_name = suggestion.get("moc_name", "Unknown")
        lines.append(f"🗺️  Create MoC: '{moc_name}'")
    
    elif suggestion_type == "area_creation":
        area_name = suggestion.get("area_name", "Unknown")
        lines.append(f"📂 Create Area: '{area_name}'")
    
    elif suggestion_type == "project_suggestion":
        project_name = suggestion.get("project_name", "Unknown")
        lines.append(f"📋 Create Project: '{project_name}'")
    
    elif suggestion_type == "insight":
        insight_text = suggestion.get("insight", "Unknown")
        lines.append(f"💡 Insight: {insight_text}")
    
    else:
        lines.append(f"Suggestion: {suggestion.get('summary', 'Unknown')}")
    
    # Confidence display
    if original_confidence != confidence:
        lines.append(f"  Confidence: {original_confidence:.0%} → {confidence:.0%}")
    else:
        lines.append(f"  Confidence: {confidence:.0%}")
    
    # Full explanation if requested
    if show_full_explanation:
        context = suggestion.get("context")
        tags = suggestion.get("tags", [])
        
        explanation_text = explain_suggestion(
            suggestion_type=suggestion_type,
            confidence=original_confidence,
            context=context,
            tags=tags
        )
        lines.append("")
        lines.append(explanation_text)
    
    return "\n".join(lines)


def main():
    """CLI for testing explanations."""
    import sys
    
    if len(sys.argv) < 3:
        print("Usage: python3 gtd_explain_suggestions.py <suggestion_type> <confidence> [context] [tags...]")
        sys.exit(1)
    
    suggestion_type = sys.argv[1]
    confidence = float(sys.argv[2])
    context = sys.argv[3] if len(sys.argv) > 3 else None
    tags = sys.argv[4:] if len(sys.argv) > 4 else []
    
    explanation = explain_suggestion(suggestion_type, confidence, context, tags)
    print(explanation)
    print()
    
    threshold_explanation = explain_threshold(suggestion_type)
    print(threshold_explanation)


if __name__ == "__main__":
    main()

