#!/usr/bin/env python3
"""
Migration Script: Unified Learning System

Migrates data from:
1. gtd_smart_suggestions.py (task suggestions)
2. knowledge_org_learning.py (MoC/Area suggestions)

Into the new unified learning system.
"""

import json
import sys
from pathlib import Path
from datetime import datetime

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

# Old learning files (check multiple possible locations)
OLD_TASK_SUGGESTIONS_FILES = [
    GTD_BASE_DIR / "suggestions" / ".suggestion_tracking.json",
    GTD_BASE_DIR / "suggestion_acceptance_tracking.json",
]
OLD_KNOWLEDGE_ORG_FILE = GTD_BASE_DIR / "knowledge_org_learning.json"
OLD_GTD_PREFERENCES_FILE = Path.home() / ".gtd_preferences.json"

# New unified file
NEW_UNIFIED_FILE = GTD_BASE_DIR / "unified_learning.json"

def load_json_file(filepath: Path):
    """Load JSON file if it exists."""
    if not filepath.exists():
        return None
    
    try:
        with open(filepath, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading {filepath}: {e}")
        return None


def migrate_task_suggestions():
    """Migrate task suggestion learning data."""
    print("\n📋 Migrating Task Suggestion Learning...")
    
    migrated_decisions = []
    
    # Try to load from suggestion tracking file (check all possible locations)
    tracking_data = None
    for filepath in OLD_TASK_SUGGESTIONS_FILES:
        tracking_data = load_json_file(filepath)
        if tracking_data:
            print(f"  Found tracking data: {filepath}")
            break
    
    if tracking_data:
        pass  # Continue with existing logic
        
        # Extract threshold data
        thresholds = {}
        if "confidence_thresholds" in tracking_data:
            thresholds = {
                "task_from_log": tracking_data["confidence_thresholds"].get("medium", 0.60),
                "task_from_log_high": tracking_data["confidence_thresholds"].get("high", 0.85),
                "task_from_log_auto": tracking_data["confidence_thresholds"].get("auto_create", 0.90),
            }
            print(f"  Extracted thresholds: {thresholds}")
        
        # Extract decision history (handle both formats)
        decision_list = tracking_data.get("decision_history") or tracking_data.get("acceptance_history", [])
        
        if decision_list:
            print(f"  Found {len(decision_list)} historical decisions")
            
            for decision in decision_list:
                # Map old decisions to unified format
                old_decision = decision.get("decision", "unknown")
                if old_decision == "dismissed":
                    new_decision = "rejected"
                elif old_decision in ["accepted", "rejected", "skipped"]:
                    new_decision = old_decision
                else:
                    new_decision = "skipped"
                
                # Determine suggestion type based on confidence and auto_created
                auto_created = decision.get("auto_created", False)
                confidence = decision.get("confidence", 0.0)
                
                if auto_created or confidence >= 0.90:
                    stype = "task_from_log_auto"
                elif confidence >= 0.85:
                    stype = "task_from_log_high"
                else:
                    stype = "task_from_log"
                
                # Convert old format to unified format
                migrated_decisions.append({
                    "id": f"migrated-task-{len(migrated_decisions)}",
                    "timestamp": decision.get("timestamp", datetime.now().isoformat()),
                    "type": stype,
                    "decision": new_decision,
                    "confidence": confidence,
                    "context": None,
                    "tags": [],
                    "rating": None,
                    "feedback_reason": None,
                    "suggestion": {
                        "original_id": decision.get("suggestion_id"),
                        "migrated": True
                    }
                })
        
        # Calculate stats from decision history
        stats = {"accepted": 0, "rejected": 0, "skipped": 0}
        for decision in migrated_decisions:
            dec_type = decision["decision"]
            if dec_type in stats:
                stats[dec_type] += 1
        
        # Or use totals if provided
        if "total_accepted" in tracking_data:
            stats["accepted"] = tracking_data.get("total_accepted", 0)
        if "total_rejected" in tracking_data:
            stats["rejected"] = tracking_data.get("total_rejected", 0)
        
        print(f"  Stats: {stats['accepted']} accepted, {stats['rejected']} rejected, {stats['skipped']} skipped")
        
        return thresholds, stats, migrated_decisions
    
    # Try GTD preferences file as fallback
    prefs_data = load_json_file(OLD_GTD_PREFERENCES_FILE)
    if prefs_data and "suggestion_tracking" in prefs_data:
        print(f"  Found preferences data: {OLD_GTD_PREFERENCES_FILE}")
        tracking = prefs_data["suggestion_tracking"]
        
        thresholds = {}
        if "confidence_thresholds" in tracking:
            thresholds = {
                "task_from_log": tracking["confidence_thresholds"].get("medium", 0.60),
                "task_from_log_high": tracking["confidence_thresholds"].get("high", 0.85),
                "task_from_log_auto": tracking["confidence_thresholds"].get("auto_create", 0.90),
            }
        
        stats = {
            "accepted": tracking.get("total_accepted", 0),
            "rejected": tracking.get("total_rejected", 0),
            "skipped": 0
        }
        
        print(f"  Stats: {stats['accepted']} accepted, {stats['rejected']} rejected")
        
        return thresholds, stats, []
    
    print("  No task suggestion data found")
    return {}, {"accepted": 0, "rejected": 0, "skipped": 0}, []


def migrate_knowledge_org():
    """Migrate knowledge organization learning data."""
    print("\n🗺️  Migrating Knowledge Organization Learning...")
    
    data = load_json_file(OLD_KNOWLEDGE_ORG_FILE)
    if not data:
        print("  No knowledge org data found")
        return {}, {}, [], {}
    
    print(f"  Found knowledge org data: {OLD_KNOWLEDGE_ORG_FILE}")
    
    # Extract thresholds
    thresholds = data.get("thresholds", {})
    print(f"  Thresholds: {thresholds}")
    
    # Extract stats
    stats_by_type = data.get("stats", {})
    
    # Extract decision history
    migrated_decisions = []
    if "decisions" in data:
        decisions = data["decisions"]
        print(f"  Found {len(decisions)} decisions")
        
        for decision in decisions:
            # Already in good format, just ensure fields exist
            migrated_decisions.append({
                "id": f"migrated-ko-{len(migrated_decisions)}",
                "timestamp": decision.get("timestamp", datetime.now().isoformat()),
                "type": decision.get("type", "unknown"),
                "decision": decision.get("decision", "unknown"),
                "confidence": decision.get("confidence", 0.0),
                "context": decision.get("suggestion", {}).get("suggested_area") or 
                          decision.get("suggestion", {}).get("area_name") or
                          decision.get("suggestion", {}).get("moc_name"),
                "tags": [],
                "suggestion": decision.get("suggestion", {})
            })
    
    # Extract patterns
    patterns = data.get("patterns", {})
    
    print(f"  Stats: {stats_by_type}")
    
    return thresholds, stats_by_type, migrated_decisions, patterns


def merge_to_unified(force: bool = False):
    """Merge all learning data into unified system."""
    print("\n🔄 Merging to Unified Learning System...")
    
    # Load existing unified data (if any)
    if NEW_UNIFIED_FILE.exists():
        print(f"⚠️  WARNING: Unified learning file already exists: {NEW_UNIFIED_FILE}")
        if not force:
            response = input("  Overwrite? (y/N): ")
            if response.lower() != 'y':
                print("  Migration cancelled")
                return False
        else:
            print("  --force flag used, overwriting...")
    
    # Migrate both sources
    task_thresholds, task_stats, task_decisions = migrate_task_suggestions()
    ko_thresholds, ko_stats, ko_decisions, ko_patterns = migrate_knowledge_org()
    
    # Create unified structure
    # Import locally to avoid issues
    sys.path.insert(0, str(Path(__file__).parent))
    try:
        from gtd_unified_learning import get_default_learning_data, SUGGESTION_TYPES
        unified = get_default_learning_data()
    except ImportError as e:
        print(f"❌ Failed to import gtd_unified_learning: {e}")
        print("   Make sure you're running from the dotfiles directory")
        return False
    
    # Merge thresholds
    unified["thresholds"].update(task_thresholds)
    unified["thresholds"].update(ko_thresholds)
    
    # Merge stats
    for stype in ["task_from_log", "task_from_log_high", "task_from_log_auto"]:
        if stype in unified["stats"]:
            unified["stats"][stype] = task_stats
    
    for stype, stats in ko_stats.items():
        if stype in unified["stats"]:
            unified["stats"][stype] = stats
    
    # Merge decisions
    all_decisions = task_decisions + ko_decisions
    unified["decisions"] = all_decisions
    
    # Merge patterns
    if ko_patterns:
        for pattern_type, pattern_data in ko_patterns.items():
            if pattern_type in unified["patterns"]:
                unified["patterns"][pattern_type] = pattern_data
    
    # Add migration metadata
    unified["migration"] = {
        "migrated_at": datetime.now().isoformat(),
        "sources": {
            "task_suggestions": {
                "decisions": len(task_decisions),
                "stats": task_stats
            },
            "knowledge_org": {
                "decisions": len(ko_decisions),
                "stats": ko_stats
            }
        },
        "total_migrated_decisions": len(all_decisions)
    }
    
    # Save unified data
    try:
        with open(NEW_UNIFIED_FILE, 'w') as f:
            json.dump(unified, f, indent=2)
        
        print(f"\n✅ Migration Complete!")
        print(f"  Unified file: {NEW_UNIFIED_FILE}")
        print(f"  Total decisions migrated: {len(all_decisions)}")
        print(f"  Task decisions: {len(task_decisions)}")
        print(f"  Knowledge org decisions: {len(ko_decisions)}")
        print()
        
        # Backup old files
        print("📦 Backing up old learning files...")
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        
        for filepath in OLD_TASK_SUGGESTIONS_FILES:
            if filepath.exists():
                backup = filepath.parent / f"{filepath.stem}_backup_{timestamp}.json"
                filepath.rename(backup)
                print(f"  Backed up: {backup}")
        
        if OLD_KNOWLEDGE_ORG_FILE.exists():
            backup = OLD_KNOWLEDGE_ORG_FILE.parent / f"knowledge_org_learning_backup_{timestamp}.json"
            OLD_KNOWLEDGE_ORG_FILE.rename(backup)
            print(f"  Backed up: {backup}")
        
        print()
        print("🎉 Migration successful! Old files have been backed up.")
        print()
        print("Next steps:")
        print("  1. Test the unified system: python3 mcp/gtd_unified_learning.py stats")
        print("  2. Update workers to use unified learning")
        print()
        
        return True
        
    except Exception as e:
        print(f"\n❌ Migration failed: {e}")
        return False


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Migrate to unified learning system")
    parser.add_argument('--force', '-f', action='store_true', help='Skip confirmation prompt')
    args = parser.parse_args()
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🔄 GTD Unified Learning Migration")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print()
    print("This will migrate learning data from:")
    print("  • Task suggestions (gtd_smart_suggestions)")
    print("  • Knowledge organization (knowledge_org_learning)")
    print()
    print("Into the new unified learning system.")
    print()
    
    if not args.force:
        response = input("Continue with migration? (y/N): ")
        if response.lower() != 'y':
            print("Migration cancelled")
            return
    
    success = merge_to_unified(force=args.force)
    
    if success:
        sys.exit(0)
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()

