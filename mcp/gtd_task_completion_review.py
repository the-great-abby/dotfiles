#!/usr/bin/env python3
"""
GTD Task Completion Review - Finds tasks mentioned as completed in logs
and presents them for review before closing.

This script REUSES existing scanner functions from gtd_progress_analyzer.py:
- analyze_completions_for_tasks() - Does all the log analysis and task matching
- No code duplication - leverages the existing progress analyzer infrastructure
- Extends functionality with review interface and task completion
"""

import json
import sys
import subprocess
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any

# Import progress analyzer functions (reuse existing scanner!)
sys.path.insert(0, str(Path(__file__).parent))
from gtd_progress_analyzer import (
    analyze_completions_for_tasks,  # Main function that does all the work!
    read_recent_logs,
    extract_completion_indicators,
    get_all_active_tasks,
    find_matching_tasks,
    similarity_score
)


def display_review_interface(analysis: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Display review interface and return selected completions."""
    potential = analysis.get("potential_completions", [])
    unmatched = analysis.get("unmatched_completions", [])
    
    if not potential and not unmatched:
        print("\n✓ No completed work found in recent logs that matches existing tasks.")
        return []
    
    print("\n" + "="*80)
    print("📋 TASK COMPLETION REVIEW")
    print("="*80)
    print(f"\nAnalyzed {analysis.get('days_analyzed', 7)} days of logs")
    print(f"Found {len(potential)} potential task completions")
    if unmatched:
        print(f"Found {len(unmatched)} completed items that don't match any tasks")
    print()
    
    selected = []
    index = 1
    
    # Show potential completions
    for item in potential:
        completion = item["completion"]
        matches = item["matches"]
        log_date = item["log_date"]
        
        print(f"\n[{index}] COMPLETION FOUND IN LOG ({log_date})")
        print("-" * 80)
        print(f"Description: {completion.get('description', 'Unknown')}")
        print(f"Confidence: {completion.get('confidence', 0.7):.0%}")
        if completion.get('context'):
            print(f"Context: {completion.get('context')}")
        print()
        
        # Show matched tasks
        print("Matched Tasks:")
        for i, match_info in enumerate(matches, 1):
            task = match_info["task"]
            similarity = match_info["similarity"]
            confidence = match_info["confidence"]
            
            print(f"  {i}. {task.get('title', 'Unknown')}")
            print(f"     ID: {task.get('id', 'N/A')}")
            if task.get('project'):
                print(f"     Project: {task.get('project')}")
            print(f"     Similarity: {similarity:.0%} | Combined Confidence: {confidence:.0%}")
            print()
        
        # Ask for approval
        print("Options:")
        print("  [y] Yes, close the best match (first task)")
        print("  [n] No, skip this")
        if len(matches) > 1:
            print(f"  [1-{len(matches)}] Close a specific match")
        print("  [s] Skip all remaining")
        print()
        
        while True:
            choice = input("Your choice: ").strip().lower()
            
            if choice == 's':
                return selected  # Return what we have so far
            
            if choice == 'y':
                # Close the best match
                selected.append({
                    "completion": completion,
                    "task": matches[0]["task"],
                    "confidence": matches[0]["confidence"],
                    "log_date": log_date
                })
                print("✓ Marked for completion")
                break
            
            if choice == 'n':
                print("⊘ Skipped")
                break
            
            if choice.isdigit():
                match_num = int(choice)
                if 1 <= match_num <= len(matches):
                    selected.append({
                        "completion": completion,
                        "task": matches[match_num - 1]["task"],
                        "confidence": matches[match_num - 1]["confidence"],
                        "log_date": log_date
                    })
                    print("✓ Marked for completion")
                    break
                else:
                    print(f"Invalid number. Please enter 1-{len(matches)}")
            else:
                print("Invalid choice. Please enter y, n, a number, or s")
        
        index += 1
    
    # Show unmatched completions (informational)
    if unmatched:
        print("\n" + "="*80)
        print("ℹ️  UNMATCHED COMPLETIONS")
        print("="*80)
        print("\nThese items were mentioned as completed but don't match any active tasks:")
        for item in unmatched[:5]:  # Show first 5
            completion = item["completion"]
            print(f"  • {completion.get('description', 'Unknown')} ({item['log_date']})")
        if len(unmatched) > 5:
            print(f"  ... and {len(unmatched) - 5} more")
        print("\n(These won't be closed - they may not be tracked as tasks)")
    
    return selected


def complete_tasks(selected: List[Dict[str, Any]], dry_run: bool = False) -> Dict[str, Any]:
    """Complete the selected tasks."""
    results = {
        "completed": [],
        "failed": [],
        "skipped": []
    }
    
    if not selected:
        return results
    
    print("\n" + "="*80)
    if dry_run:
        print("🔍 DRY RUN - No tasks will be closed")
    else:
        print("✅ COMPLETING TASKS")
    print("="*80)
    print()
    
    for item in selected:
        task = item["task"]
        task_id = task.get("id")
        task_title = task.get("title", "Unknown")
        confidence = item.get("confidence", 0.7)
        
        if not task_id:
            results["failed"].append({
                "task": task,
                "error": "No task ID found"
            })
            continue
        
        if dry_run:
            print(f"[DRY RUN] Would complete: {task_title} (ID: {task_id}, Confidence: {confidence:.0%})")
            results["completed"].append({
                "task": task,
                "dry_run": True
            })
        else:
            try:
                # Use gtd-task complete command
                result = subprocess.run(
                    ["gtd-task", "complete", task_id],
                    capture_output=True,
                    text=True,
                    timeout=10
                )
                
                if result.returncode == 0:
                    print(f"✓ Completed: {task_title}")
                    results["completed"].append({
                        "task": task,
                        "confidence": confidence
                    })
                else:
                    print(f"✗ Failed: {task_title} - {result.stderr.strip()}")
                    results["failed"].append({
                        "task": task,
                        "error": result.stderr.strip()
                    })
            except Exception as e:
                print(f"✗ Error completing {task_title}: {e}")
                results["failed"].append({
                    "task": task,
                    "error": str(e)
                })
    
    return results


def main():
    """Main CLI interface."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Review and close tasks mentioned as completed in logs"
    )
    parser.add_argument(
        "--days",
        type=int,
        default=7,
        help="Number of days to analyze (default: 7)"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without actually closing tasks"
    )
    parser.add_argument(
        "--auto",
        action="store_true",
        help="Auto-approve high-confidence matches (85%% or higher confidence)"
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Output results as JSON (non-interactive)"
    )
    
    args = parser.parse_args()
    
    # Analyze
    print("Analyzing recent logs for completed tasks...")
    analysis = analyze_completions_for_tasks(days=args.days)
    
    if args.json:
        # JSON output mode (for automation)
        print(json.dumps(analysis, indent=2, default=str))
        return
    
    # Interactive review
    if args.auto:
        # Auto-approve high confidence
        selected = []
        for item in analysis.get("potential_completions", []):
            best_match = item["matches"][0]
            if best_match["confidence"] >= 0.85:
                selected.append({
                    "completion": item["completion"],
                    "task": best_match["task"],
                    "confidence": best_match["confidence"],
                    "log_date": item["log_date"]
                })
    else:
        # Manual review
        selected = display_review_interface(analysis)
    
    if not selected:
        print("\nNo tasks selected for completion.")
        return
    
    # Complete tasks
    results = complete_tasks(selected, dry_run=args.dry_run)
    
    # Summary
    print("\n" + "="*80)
    print("📊 SUMMARY")
    print("="*80)
    print(f"Completed: {len(results['completed'])}")
    print(f"Failed: {len(results['failed'])}")
    
    if results["failed"]:
        print("\nFailed tasks:")
        for fail in results["failed"]:
            print(f"  • {fail['task'].get('title', 'Unknown')}: {fail.get('error', 'Unknown error')}")


if __name__ == "__main__":
    main()

