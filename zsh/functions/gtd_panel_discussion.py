#!/usr/bin/env python3
"""
Panel Discussion System - Collaborative AI personas engaging in discussion
Personas respond to each other's ideas across multiple rounds of discussion.
"""

import json
import sys
import os
from typing import List, Dict, Any, Tuple, Optional
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

try:
    from gtd_persona_helper import call_persona, read_config, PERSONAS
except ImportError as e:
    print(f"Error: Could not import gtd_persona_helper: {e}", file=sys.stderr)
    sys.exit(1)


class PersonaSelector:
    """
    Intelligent persona selector that chooses 3-4 personas based on question content.
    Uses hybrid algorithm: 70% keyword matching + 30% semantic similarity
    """

    # Expertise keywords mapped to persona specialties
    EXPERTISE_KEYWORDS = {
        "gtd_methodology": ["organize", "tasks", "gtd", "workflow", "inbox", "organize", "project",
                           "goal", "system", "capture", "clarity", "next action", "weekly review"],
        "deep_work": ["focus", "concentration", "distraction", "deep work", "attention", "flow",
                     "schedule", "block time", "focus time", "productive"],
        "habits": ["habit", "routine", "consistency", "streak", "daily", "practice", "build",
                  "behavior", "compound", "incremental"],
        "organization": ["clutter", "organize", "declutter", "tidy", "space", "order", "clean",
                        "organize space", "spark joy", "organize home"],
        "strategy": ["strategy", "priority", "prioritize", "long-term", "investment", "value",
                    "focus", "important"],
        "execution": ["execute", "leadership", "action", "done", "complete", "deliver",
                     "leadership", "lead"],
        "optimization": ["optimize", "system", "hack", "efficient", "streamline", "automation",
                        "unconventional", "experiment"],
        "creativity": ["creative", "creative thinking", "art", "painting", "design", "calm",
                      "process", "flow"],
        "emotional_support": ["stress", "anxiety", "overwhelmed", "kindness", "self-care",
                            "worth", "value", "support", "help"],
        "accountability": ["procrastinate", "stuck", "accountability", "track", "discipline",
                          "stick to it", "follow through"],
        "fitness": ["workout", "exercise", "training", "fitness", "gym", "strength", "cardio",
                   "run", "running", "marathon", "kettlebell", "dumbbell"],
        "mental_toughness": ["mental toughness", "push", "hard", "discipline", "persist",
                           "overcome", "strong mindset"],
        "relationships": ["partner", "relationship", "dating", "love", "connection", "intimacy",
                         "romance", "communication"],
        "problem_solving": ["problem", "solve", "creative solution", "approach", "idea",
                           "unconventional", "outside the box"],
        "simplicity": ["simple", "simplicity", "essential", "practical", "no-nonsense",
                      "straightforward", "clear"],
        "systems": ["system", "design", "mechanics", "rules", "framework", "structure"],
        "storytelling": ["story", "narrative", "character", "adventure", "journey", "arc"],
    }

    # Rule-based overrides for specific question types
    RULE_OVERRIDES = {
        "gtd": ["david"],  # Always include David Allen for GTD questions
        "focus": ["cal"],  # Include Cal Newport for focus questions
        "habit": ["james"],  # Include James Clear for habit questions
        "organize": ["marie"],  # Include Marie Kondo for organization questions
        "workout": ["goggins", "dean", "bioneer"],  # Include fitness experts
        "relationship": ["esther", "gottman", "gary", "brene", "romance"],  # Include relationship experts
        "fitness": ["goggins", "dean", "bioneer", "kettlebell", "maxfit", "dumbbell"],
    }

    def __init__(self):
        """Initialize the persona selector."""
        self.personas = PERSONAS.copy()

    def score_keyword_match(self, question: str, expertise_keywords: Dict[str, List[str]]) -> Dict[str, float]:
        """
        Score personas based on keyword matching in the question.
        Returns normalized scores for each expertise area.

        Args:
            question: User's question text
            expertise_keywords: Dictionary of expertise -> keywords

        Returns:
            Dict mapping persona_key -> score (0.0-1.0)
        """
        question_lower = question.lower()
        scores = {}

        for persona_key, persona_info in self.personas.items():
            persona_score = 0.0
            expertise = persona_info.get("expertise", "")

            # If this persona has matching expertise keywords
            if expertise in expertise_keywords:
                keywords = expertise_keywords[expertise]
                matches = sum(1 for keyword in keywords if keyword in question_lower)
                # Score based on number of matches
                persona_score = min(matches / max(len(keywords) / 2, 1), 1.0)

            # Exact keyword match in question
            if expertise.replace("_", " ") in question_lower or expertise in question_lower:
                persona_score = min(persona_score + 0.5, 1.0)

            if persona_score > 0:
                scores[persona_key] = persona_score

        # Normalize scores to 0-1 range
        if scores:
            max_score = max(scores.values())
            if max_score > 0:
                scores = {k: v / max_score for k, v in scores.items()}

        return scores

    def apply_rule_overrides(self, scores: Dict[str, float], question: str) -> Dict[str, float]:
        """
        Apply rule-based overrides to boost certain personas for specific question types.

        Args:
            scores: Current persona scores
            question: User's question

        Returns:
            Updated scores with overrides applied
        """
        question_lower = question.lower()

        for rule_keyword, override_personas in self.RULE_OVERRIDES.items():
            if rule_keyword in question_lower:
                for persona_key in override_personas:
                    if persona_key in self.personas:
                        # Boost score significantly for rule match
                        current_score = scores.get(persona_key, 0.0)
                        scores[persona_key] = min(current_score + 0.8, 1.0)

        return scores

    def enforce_diversity(self, persona_keys: List[str], num_personas: int = 4) -> List[str]:
        """
        Enforce diversity constraint: avoid multiple personas from same expertise area.

        Args:
            persona_keys: List of persona keys to consider
            num_personas: Number of personas to select

        Returns:
            Diverse list of persona keys
        """
        selected = []
        expertise_used = set()

        for persona_key in persona_keys[:num_personas * 2]:  # Look at top candidates
            persona_info = self.personas.get(persona_key, {})
            expertise = persona_info.get("expertise", "")

            if expertise not in expertise_used or len(selected) < num_personas:
                selected.append(persona_key)
                expertise_used.add(expertise)

                if len(selected) >= num_personas:
                    break

        # If we don't have enough personas with diversity, just return top scorers
        return selected[:num_personas]

    def select_personas(self, question: str, panel_size: int = 4) -> List[str]:
        """
        Auto-select best personas for the question using hybrid algorithm.

        Args:
            question: User's question
            panel_size: Desired number of personas (3-5)

        Returns:
            List of selected persona keys
        """
        # Phase 1: Keyword matching (70% weight)
        keyword_scores = self.score_keyword_match(question, self.EXPERTISE_KEYWORDS)

        # Phase 2: Apply rule-based overrides (30% weight effectively)
        combined_scores = self.apply_rule_overrides(keyword_scores, question)

        # Sort by score
        sorted_personas = sorted(combined_scores.items(), key=lambda x: x[1], reverse=True)
        top_personas = [p[0] for p in sorted_personas]

        # Phase 3: Apply diversity constraint
        selected = self.enforce_diversity(top_personas, panel_size)

        # Fallback: if we somehow don't have enough, add high-value default personas
        if len(selected) < panel_size:
            defaults = ["david", "cal", "james", "marie", "warren"]
            for persona_key in defaults:
                if persona_key not in selected and persona_key in self.personas:
                    selected.append(persona_key)
                    if len(selected) >= panel_size:
                        break

        return selected[:panel_size]


class PanelDiscussion:
    """
    Orchestrates multi-round panel discussion between selected personas.
    Each round personas see previous responses and can build/debate/synthesize.
    """

    def __init__(self, config: Dict[str, Any], panel_size: int = 4):
        """
        Initialize panel discussion.

        Args:
            config: GTD configuration dictionary
            panel_size: Number of personas to include
        """
        self.config = config
        self.panel_size = panel_size
        self.selector = PersonaSelector()
        self.responses = {}  # persona_key -> {round_1: str, round_2: str, etc}

    def format_panel_header(self, question: str, personas: List[str]) -> str:
        """Format the panel header with question and personas."""
        persona_names = []
        for key in personas:
            if key in PERSONAS:
                persona_names.append(PERSONAS[key].get("name", key.title()))

        header = "\n" + "━" * 80 + "\n"
        header += "🎭 PANEL DISCUSSION\n"
        header += "━" * 80 + "\n\n"
        header += f"❓ Question: {question}\n"
        header += f"👥 Panel: {', '.join(persona_names)}\n\n"

        return header

    def run_round_1(self, question: str, personas: List[str]) -> Dict[str, str]:
        """
        Round 1: Each persona responds independently to the original question.

        Args:
            question: User's question
            personas: List of persona keys

        Returns:
            Dictionary mapping persona_key -> response
        """
        print("\n" + "━" * 80)
        print("🎭 ROUND 1: Initial Perspectives")
        print("━" * 80 + "\n")

        round1_responses = {}

        for i, persona_key in enumerate(personas, 1):
            if persona_key not in PERSONAS:
                continue

            persona_name = PERSONAS[persona_key].get("name", persona_key.title())

            # Show progress
            print(f"[{i}/{len(personas)}] {persona_name} is thinking...", file=sys.stderr)

            # Call persona with the question
            response, exit_code = call_persona(
                config=self.config,
                persona_key=persona_key,
                content=question,
                skip_gtd_context=True,
                use_instruct=False,
                is_background=False
            )

            if exit_code == 0:
                round1_responses[persona_key] = response
            else:
                round1_responses[persona_key] = f"[Error getting response from {persona_name}]"

        # Store responses
        self.responses = {pk: {"round_1": resp} for pk, resp in round1_responses.items()}

        # Display Round 1 responses
        for persona_key, response in round1_responses.items():
            persona_name = PERSONAS[persona_key].get("name", persona_key.title())
            print(f"\n💬 {persona_name}:")
            print(response)

        return round1_responses

    def run_round_2(self, question: str, personas: List[str], round1_responses: Dict[str, str]) -> Dict[str, str]:
        """
        Round 2: Each persona sees all Round 1 responses, builds on them.

        Args:
            question: Original question
            personas: List of persona keys
            round1_responses: Dict of Round 1 responses

        Returns:
            Dictionary mapping persona_key -> Round 2 response
        """
        print("\n" + "━" * 80)
        print("🎭 ROUND 2: Building on Perspectives")
        print("━" * 80 + "\n")

        round2_responses = {}

        for i, persona_key in enumerate(personas, 1):
            if persona_key not in PERSONAS:
                continue

            persona_name = PERSONAS[persona_key].get("name", persona_key.title())

            # Build context with other personas' responses
            other_responses = []
            for other_key, other_response in round1_responses.items():
                if other_key != persona_key:
                    other_name = PERSONAS[other_key].get("name", other_key.title())
                    other_responses.append(f"{other_name} said:\n{other_response}")

            # Create Round 2 prompt
            context = "\n\n---\n\n".join(other_responses)
            round2_prompt = f"""Original question: {question}

Other panelists' perspectives:

{context}

Now, having read what your fellow panelists said, please respond. You can:
- Build on their ideas if you agree
- Respectfully debate if you disagree
- Add new perspectives they missed
- Synthesize what they've said
- Challenge assumptions

Stay true to your character and expertise."""

            # Show progress
            print(f"[{i}/{len(personas)}] {persona_name} is responding...", file=sys.stderr)

            # Call persona with enhanced prompt
            response, exit_code = call_persona(
                config=self.config,
                persona_key=persona_key,
                content=round2_prompt,
                skip_gtd_context=True,
                use_instruct=False,
                is_background=False
            )

            if exit_code == 0:
                round2_responses[persona_key] = response
                # Store in responses dict
                if persona_key in self.responses:
                    self.responses[persona_key]["round_2"] = response
            else:
                round2_responses[persona_key] = f"[Error getting response from {persona_name}]"

        # Display Round 2 responses
        for persona_key, response in round2_responses.items():
            persona_name = PERSONAS[persona_key].get("name", persona_key.title())
            print(f"\n💬 {persona_name}:")
            print(response)

        return round2_responses

    def run_synthesis(self, question: str, personas: List[str], all_responses: Dict[str, Dict[str, str]]) -> str:
        """
        Synthesis: David Allen (or another persona) synthesizes the discussion.

        Args:
            question: Original question
            personas: List of personas in discussion
            all_responses: All responses from all rounds

        Returns:
            Synthesis response
        """
        print("\n" + "━" * 80)
        print("📋 Panel Synthesis")
        print("━" * 80 + "\n")

        # Use David Allen for synthesis if available, otherwise use first persona
        synthesis_persona = "david" if "david" in personas else personas[0]

        # Build summary of all discussion
        discussion_summary = f"Question: {question}\n\nPanel Discussion Summary:\n\n"

        for persona_key in personas:
            if persona_key not in PERSONAS:
                continue

            persona_name = PERSONAS[persona_key].get("name", persona_key.title())
            discussion_summary += f"{persona_name}'s perspective:\n"

            if persona_key in all_responses:
                if "round_2" in all_responses[persona_key]:
                    discussion_summary += f"{all_responses[persona_key]['round_2']}\n\n"
                elif "round_1" in all_responses[persona_key]:
                    discussion_summary += f"{all_responses[persona_key]['round_1']}\n\n"

        # Create synthesis prompt
        synthesis_prompt = f"""{discussion_summary}

Please synthesize this discussion by identifying:

1. **Key Themes**: What are the 2-3 main themes that emerged from the discussion?
2. **Points of Agreement**: Where did the panelists agree?
3. **Points of Disagreement**: Where did they disagree?
4. **Actionable Takeaways**: What are the top 3-5 concrete actions the person should take?

Format your synthesis clearly with these sections."""

        print("Generating synthesis...", file=sys.stderr)

        response, exit_code = call_persona(
            config=self.config,
            persona_key=synthesis_persona,
            content=synthesis_prompt,
            skip_gtd_context=True,
            use_instruct=False,
            is_background=False
        )

        if exit_code == 0:
            return response
        else:
            return "[Error generating synthesis]"

    def run_discussion(self, question: str, personas: Optional[List[str]] = None) -> str:
        """
        Run the full panel discussion (Round 1 + Round 2 + Synthesis).

        Args:
            question: User's question
            personas: Optional list of persona keys (auto-selected if None)

        Returns:
            Formatted discussion output
        """
        # Auto-select personas if not provided
        if personas is None:
            personas = self.selector.select_personas(question, self.panel_size)

        # Format header
        output = self.format_panel_header(question, personas)

        # Run Round 1
        round1_responses = self.run_round_1(question, personas)

        # Run Round 2
        round2_responses = self.run_round_2(question, personas, round1_responses)

        # Run Synthesis
        synthesis = self.run_synthesis(question, personas, self.responses)

        # Build final output
        output += "\n" + "━" * 80 + "\n"
        output += synthesis
        output += "\n" + "━" * 80 + "\n"

        return output


def run_panel_discussion_cli(content: str, panel_size: int = 4, manual_personas: Optional[str] = None):
    """
    CLI entry point for panel discussion.

    Args:
        content: User's question or content
        panel_size: Number of personas for panel
        manual_personas: Comma-separated persona keys (overrides auto-selection)
    """
    # Load config
    config = read_config()

    # Create panel discussion
    panel = PanelDiscussion(config, panel_size)

    # Determine personas
    if manual_personas:
        personas = [p.strip() for p in manual_personas.split(",")]
    else:
        personas = panel.selector.select_personas(content, panel_size)

    # Run discussion
    output = panel.run_discussion(content, personas)

    # Print output
    print(output)


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] in ["--help", "-h"]:
        print("Usage: gtd_panel_discussion.py <question> [--size N] [--personas p1,p2,p3,p4]")
        print("")
        print("Options:")
        print("  <question>         The question for the panel to discuss")
        print("  --size N           Number of personas (default: 4)")
        print("  --personas p1,p2   Comma-separated persona keys (auto-selects if not provided)")
        print("")
        print("Examples:")
        print("  gtd_panel_discussion.py \"How do I focus better?\"")
        print("  gtd_panel_discussion.py \"My question\" --size 5")
        print("  gtd_panel_discussion.py \"Question\" --personas david,cal,james,marie")
        sys.exit(0)

    question = sys.argv[1]
    panel_size = 4
    manual_personas = None

    # Parse options
    i = 2
    while i < len(sys.argv):
        if sys.argv[i] == "--size" and i + 1 < len(sys.argv):
            try:
                panel_size = int(sys.argv[i + 1])
                i += 2
            except (ValueError, IndexError):
                i += 1
        elif sys.argv[i] == "--personas" and i + 1 < len(sys.argv):
            manual_personas = sys.argv[i + 1]
            i += 2
        else:
            i += 1

    run_panel_discussion_cli(question, panel_size, manual_personas)
