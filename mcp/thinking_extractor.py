#!/usr/bin/env python3
"""
Thinking Content Extractor

Extracts thinking/reasoning content from AI model responses, typically
found in <think>...</think> tags from thinking models.
"""

import re
from typing import Tuple, Optional


def extract_thinking(content: str) -> Tuple[str, Optional[str]]:
    """
    Extract thinking content from response and return cleaned content + thinking.
    
    Args:
        content: The raw response content that may contain <think>...</think> tags
    
    Returns:
        Tuple of (cleaned_content, thinking_content):
        - cleaned_content: Content with thinking tags removed
        - thinking_content: Extracted thinking content (None if not found)
    """
    if not content:
        return content, None
    
    # Extract thinking blocks (multiline, case-insensitive)
    thinking_pattern = r'<think>(.*?)</think>'
    thinking_matches = re.findall(thinking_pattern, content, flags=re.DOTALL | re.IGNORECASE)
    
    if not thinking_matches:
        # No thinking content found
        return content, None
    
    # Combine all thinking blocks
    thinking_content = '\n\n'.join(thinking_matches).strip()
    
    # Remove thinking tags from content
    cleaned_content = re.sub(thinking_pattern, '', content, flags=re.DOTALL | re.IGNORECASE)
    
    # Clean up extra whitespace/newlines that might be left behind
    cleaned_content = re.sub(r'\n\n\n+', '\n\n', cleaned_content).strip()
    
    return cleaned_content, thinking_content if thinking_content else None
