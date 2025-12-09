#!/usr/bin/env python3
"""
Cursor Rules Helper Script
Helps manage and query the cursor rules index system.
"""

import json
import sys
import re
from pathlib import Path
from typing import List, Dict, Any, Set
from fnmatch import fnmatch


def load_index() -> Dict[str, Any]:
    """Load the rules index."""
    index_path = Path(__file__).parent / "index.json"
    if not index_path.exists():
        print(f"Error: Index file not found: {index_path}", file=sys.stderr)
        sys.exit(1)
    
    with open(index_path, 'r') as f:
        return json.load(f)


def check_file_pattern(file_path: str, patterns: List[str]) -> bool:
    """Check if file path matches any pattern."""
    for pattern in patterns:
        if fnmatch(file_path, pattern):
            return True
    return False


def check_match_strings(file_path: Path, match_strings: List[str]) -> bool:
    """Check if file content contains any match string."""
    if not file_path.exists():
        return False
    
    try:
        content = file_path.read_text(encoding='utf-8', errors='ignore')
        for match_str in match_strings:
            if match_str in content:
                return True
    except Exception:
        pass
    
    return False


def get_applicable_rules(file_path: str, index: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Get all rules that apply to a file."""
    applicable = []
    file_path_obj = Path(file_path)
    
    # Resolve to absolute path if relative
    if not file_path_obj.is_absolute():
        # Try relative to current directory
        file_path_obj = Path.cwd() / file_path
        if not file_path_obj.exists():
            # Try relative to rules directory
            file_path_obj = Path(__file__).parent.parent.parent / file_path
    
    file_path_str = str(file_path_obj)
    
    for rule in index['rules']:
        applies = False
        reason = []
        
        # Check alwaysApply
        if rule.get('alwaysApply', False):
            applies = True
            reason.append("alwaysApply=true")
        
        # Check file patterns
        if not applies:
            if check_file_pattern(file_path_str, rule.get('filePatterns', [])):
                applies = True
                matching_patterns = [p for p in rule.get('filePatterns', []) 
                                   if fnmatch(file_path_str, p)]
                reason.append(f"filePattern: {', '.join(matching_patterns)}")
        
        # Check match strings
        if not applies and file_path_obj.exists():
            if check_match_strings(file_path_obj, rule.get('matchStrings', [])):
                applies = True
                # Find which strings matched
                try:
                    content = file_path_obj.read_text(encoding='utf-8', errors='ignore')
                    matching_strings = [s for s in rule.get('matchStrings', []) if s in content]
                    reason.append(f"matchString: {', '.join(matching_strings[:3])}")
                except Exception:
                    reason.append("matchString: (content check failed)")
        
        if applies:
            rule_copy = rule.copy()
            rule_copy['_reason'] = '; '.join(reason)
            applicable.append(rule_copy)
    
    # Sort by priority (higher first)
    applicable.sort(key=lambda x: x.get('priority', 0), reverse=True)
    
    return applicable


def list_rules(index: Dict[str, Any]):
    """List all rules in the index."""
    print("Available Cursor Rules:")
    print("=" * 80)
    print()
    
    for rule in sorted(index['rules'], key=lambda x: x.get('priority', 0), reverse=True):
        print(f"ID: {rule['id']}")
        print(f"  File: {rule['file']}")
        print(f"  Description: {rule.get('description', 'N/A')}")
        print(f"  Priority: {rule.get('priority', 0)}")
        print(f"  Always Apply: {rule.get('alwaysApply', False)}")
        print(f"  Categories: {', '.join(rule.get('categories', []))}")
        print(f"  File Patterns: {', '.join(rule.get('filePatterns', []))}")
        print(f"  Match Strings: {', '.join(rule.get('matchStrings', [])[:5])}")
        if len(rule.get('matchStrings', [])) > 5:
            print(f"    ... and {len(rule.get('matchStrings', [])) - 5} more")
        print()


def validate_index(index: Dict[str, Any]) -> bool:
    """Validate the rules index."""
    errors = []
    warnings = []
    
    # Check structure
    required_keys = ['version', 'rules']
    for key in required_keys:
        if key not in index:
            errors.append(f"Missing required key: {key}")
    
    # Check rules
    rule_ids = set()
    for i, rule in enumerate(index.get('rules', [])):
        rule_num = i + 1
        
        # Check required fields
        required_rule_keys = ['id', 'file', 'description']
        for key in required_rule_keys:
            if key not in rule:
                errors.append(f"Rule {rule_num}: Missing required field: {key}")
        
        # Check for duplicate IDs
        rule_id = rule.get('id')
        if rule_id:
            if rule_id in rule_ids:
                errors.append(f"Rule {rule_num}: Duplicate ID: {rule_id}")
            rule_ids.add(rule_id)
        
        # Check file exists
        rule_file = rule.get('file')
        if rule_file:
            rule_path = Path(__file__).parent / rule_file
            if not rule_path.exists():
                errors.append(f"Rule {rule_num} ({rule_id}): File not found: {rule_file}")
        
        # Check for empty patterns/strings
        if not rule.get('filePatterns') and not rule.get('matchStrings') and not rule.get('alwaysApply'):
            warnings.append(f"Rule {rule_num} ({rule_id}): No filePatterns, matchStrings, or alwaysApply")
    
    # Print results
    if errors:
        print("Validation Errors:")
        for error in errors:
            print(f"  ❌ {error}")
        print()
    
    if warnings:
        print("Validation Warnings:")
        for warning in warnings:
            print(f"  ⚠️  {warning}")
        print()
    
    if not errors and not warnings:
        print("✅ Index validation passed!")
        return True
    
    return len(errors) == 0


def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: rule_helper.py <command> [args...]")
        print()
        print("Commands:")
        print("  check <file_path>  - Check which rules apply to a file")
        print("  list               - List all rules")
        print("  validate           - Validate the index")
        sys.exit(1)
    
    command = sys.argv[1]
    index = load_index()
    
    if command == "check":
        if len(sys.argv) < 3:
            print("Usage: rule_helper.py check <file_path>", file=sys.stderr)
            sys.exit(1)
        
        file_path = sys.argv[2]
        applicable = get_applicable_rules(file_path, index)
        
        print(f"Rules applicable to: {file_path}")
        print("=" * 80)
        print()
        
        if not applicable:
            print("No rules apply to this file.")
        else:
            for rule in applicable:
                print(f"✓ {rule['id']} (priority: {rule.get('priority', 0)})")
                print(f"  {rule.get('description', 'N/A')}")
                print(f"  Reason: {rule.get('_reason', 'N/A')}")
                print()
    
    elif command == "list":
        list_rules(index)
    
    elif command == "validate":
        valid = validate_index(index)
        sys.exit(0 if valid else 1)
    
    else:
        print(f"Unknown command: {command}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
