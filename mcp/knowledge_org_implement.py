#!/usr/bin/env python3
"""
Knowledge Organization Implementation Helper

Helps implement MoC/Area suggestions by calling the appropriate
gtd-area and gtd-moc commands.
"""

import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Any, List

# Import GTD base path
try:
    from gtd_mcp_server import GTD_BASE_DIR
except ImportError:
    GTD_BASE_DIR = Path.home() / "Documents" / "gtd"

# Import unified learning system
try:
    from gtd_unified_learning import record_decision
except ImportError:
    def record_decision(*args, **kwargs):
        """Fallback if learning system not available."""
        return True

RESULTS_DIR = GTD_BASE_DIR / "knowledge_organization_results"


def implement_area_assignment(suggestion: Dict[str, Any]) -> bool:
    """Implement an area assignment suggestion."""
    project_slug = suggestion.get("project_slug")
    suggested_area = suggestion.get("suggested_area")
    
    if not project_slug or not suggested_area:
        print(f"❌ Invalid suggestion: missing project_slug or suggested_area")
        return False
    
    # Convert area name to slug
    area_slug = suggested_area.lower().replace(" ", "-")
    
    # Check if area exists, create if not
    areas_path = GTD_BASE_DIR / "2-areas"
    area_file = areas_path / f"{area_slug}.md"
    
    if not area_file.exists():
        print(f"  Creating new area: {suggested_area}")
        try:
            subprocess.run(
                ["gtd-area", "create", suggested_area],
                input=f"{suggested_area}\n",
                text=True,
                check=False,
                capture_output=True
            )
        except Exception as e:
            print(f"❌ Failed to create area: {e}")
            return False
    
    # Update project frontmatter to assign area
    projects_path = GTD_BASE_DIR / "1-projects"
    project_dir = projects_path / project_slug
    project_readme = project_dir / "README.md"
    
    if not project_readme.exists():
        print(f"❌ Project README not found: {project_readme}")
        return False
    
    # Read and update frontmatter
    try:
        with open(project_readme, 'r') as f:
            content = f.read()
        
        if not content.startswith('---'):
            print(f"❌ No frontmatter in project: {project_slug}")
            return False
        
        # Find frontmatter end
        end_idx = content.find('---', 3)
        if end_idx == -1:
            print(f"❌ Invalid frontmatter in project: {project_slug}")
            return False
        
        frontmatter = content[3:end_idx]
        body = content[end_idx+3:]
        
        # Update or add area field
        lines = frontmatter.strip().split('\n')
        area_found = False
        new_lines = []
        
        for line in lines:
            if line.startswith('area:'):
                new_lines.append(f'area: {area_slug}')
                area_found = True
            else:
                new_lines.append(line)
        
        if not area_found:
            new_lines.append(f'area: {area_slug}')
        
        # Reconstruct file
        new_content = f"---\n{chr(10).join(new_lines)}\n---{body}"
        
        with open(project_readme, 'w') as f:
            f.write(new_content)
        
        print(f"  ✓ Assigned {project_slug} → {suggested_area}")
        
        # Record decision in unified learning system
        record_decision(
            suggestion_type="area_assignment",
            suggestion=suggestion,
            decision="accepted",
            confidence=suggestion.get("confidence", 0.0),
            context=suggested_area
        )
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to update project: {e}")
        
        # Record failure
        record_decision(
            suggestion_type="area_assignment",
            suggestion=suggestion,
            decision="rejected",
            confidence=suggestion.get("confidence", 0.0),
            context=suggested_area
        )
        
        return False


def implement_moc_creation(suggestion: Dict[str, Any]) -> bool:
    """Implement a MoC creation suggestion."""
    moc_name = suggestion.get("moc_name")
    moc_slug = suggestion.get("moc_slug")
    reason = suggestion.get("reason", "")
    
    if not moc_name or not moc_slug:
        print(f"❌ Invalid suggestion: missing moc_name or moc_slug")
        return False
    
    # Check if MoC already exists
    mocs_path = GTD_BASE_DIR / "MOCs"
    moc_file = mocs_path / f"{moc_slug}.md"
    
    if moc_file.exists():
        print(f"⚠️  MoC already exists: {moc_slug}")
        return False
    
    # Create MoC
    print(f"  Creating MoC: {moc_name}")
    try:
        # Use gtd-moc to create
        process = subprocess.Popen(
            ["gtd-moc", "create", moc_name],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Send description (use reason as description)
        stdout, stderr = process.communicate(input=f"{reason}\n\n")
        
        if process.returncode == 0:
            print(f"  ✓ Created MoC: {moc_name}")
            
            # Record decision
            record_decision(
                suggestion_type="moc_creation",
                suggestion=suggestion,
                decision="accepted",
                confidence=suggestion.get("confidence", 0.0),
                context=moc_name
            )
            
            return True
        else:
            print(f"❌ Failed to create MoC: {stderr}")
            
            # Record rejection
            record_decision(
                suggestion_type="moc_creation",
                suggestion=suggestion,
                decision="rejected",
                confidence=suggestion.get("confidence", 0.0),
                context=moc_name
            )
            
            return False
            
    except Exception as e:
        print(f"❌ Failed to create MoC: {e}")
        
        # Record rejection
        record_decision(
            suggestion_type="moc_creation",
            suggestion=suggestion,
            decision="rejected",
            confidence=suggestion.get("confidence", 0.0),
            context=moc_name
        )
        
        return False


def implement_area_creation(suggestion: Dict[str, Any]) -> bool:
    """Implement an area creation suggestion."""
    area_name = suggestion.get("area_name")
    area_slug = suggestion.get("area_slug")
    reason = suggestion.get("reason", "")
    
    if not area_name or not area_slug:
        print(f"❌ Invalid suggestion: missing area_name or area_slug")
        return False
    
    # Check if area already exists
    areas_path = GTD_BASE_DIR / "2-areas"
    area_file = areas_path / f"{area_slug}.md"
    
    if area_file.exists():
        print(f"⚠️  Area already exists: {area_slug}")
        return False
    
    # Create area
    print(f"  Creating area: {area_name}")
    try:
        process = subprocess.Popen(
            ["gtd-area", "create", area_name],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Send description (use reason as description)
        stdout, stderr = process.communicate(input=f"{reason}\n")
        
        if process.returncode == 0:
            print(f"  ✓ Created area: {area_name}")
            
            # Record decision
            record_decision(
                suggestion_type="area_creation",
                suggestion=suggestion,
                decision="accepted",
                confidence=suggestion.get("confidence", 0.0),
                context=area_name
            )
            
            return True
        else:
            print(f"❌ Failed to create area: {stderr}")
            
            # Record rejection
            record_decision(
                suggestion_type="area_creation",
                suggestion=suggestion,
                decision="rejected",
                confidence=suggestion.get("confidence", 0.0),
                context=area_name
            )
            
            return False
            
    except Exception as e:
        print(f"❌ Failed to create area: {e}")
        
        # Record rejection
        record_decision(
            suggestion_type="area_creation",
            suggestion=suggestion,
            decision="rejected",
            confidence=suggestion.get("confidence", 0.0),
            context=area_name
        )
        
        return False


def implement_suggestions(result_file: Path, indices: List[int] = None) -> Dict[str, int]:
    """Implement knowledge organization suggestions.
    
    Args:
        result_file: Path to the results JSON file
        indices: List of suggestion indices to implement (1-based), or None for all
    
    Returns:
        Dict with counts: {"success": N, "failed": M, "skipped": K}
    """
    try:
        with open(result_file, 'r') as f:
            data = json.load(f)
        
        suggestions = data.get('suggestions', [])
        
        if not suggestions:
            print("No suggestions to implement")
            return {"success": 0, "failed": 0, "skipped": 0}
        
        # Filter by indices if provided
        if indices:
            suggestions = [s for i, s in enumerate(suggestions, 1) if i in indices]
        
        counts = {"success": 0, "failed": 0, "skipped": 0}
        
        for idx, suggestion in enumerate(suggestions, 1):
            suggestion_type = suggestion.get('type')
            
            print(f"\n[{idx}] Implementing {suggestion_type}...")
            
            try:
                if suggestion_type == 'area_assignment':
                    if implement_area_assignment(suggestion):
                        counts["success"] += 1
                    else:
                        counts["failed"] += 1
                        
                elif suggestion_type == 'moc_creation':
                    if implement_moc_creation(suggestion):
                        counts["success"] += 1
                    else:
                        counts["skipped"] += 1  # Already exists
                        
                elif suggestion_type == 'area_creation':
                    if implement_area_creation(suggestion):
                        counts["success"] += 1
                    else:
                        counts["skipped"] += 1  # Already exists
                else:
                    print(f"❌ Unknown suggestion type: {suggestion_type}")
                    counts["failed"] += 1
                    
            except Exception as e:
                print(f"❌ Error implementing suggestion: {e}")
                counts["failed"] += 1
        
        return counts
        
    except Exception as e:
        print(f"❌ Error reading results: {e}")
        return {"success": 0, "failed": 0, "skipped": 0}


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description="Implement knowledge organization suggestions")
    parser.add_argument('result_file', help='Path to the results JSON file')
    parser.add_argument('--indices', type=str, help='Comma-separated indices to implement (e.g., 1,3,5)')
    args = parser.parse_args()
    
    result_file = Path(args.result_file)
    
    if not result_file.exists():
        print(f"❌ Result file not found: {result_file}")
        sys.exit(1)
    
    indices = None
    if args.indices:
        try:
            indices = [int(i.strip()) for i in args.indices.split(',')]
        except ValueError:
            print(f"❌ Invalid indices format: {args.indices}")
            sys.exit(1)
    
    print("Implementing knowledge organization suggestions...")
    print("")
    
    counts = implement_suggestions(result_file, indices)
    
    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"✓ Success: {counts['success']}")
    print(f"⊗ Failed: {counts['failed']}")
    print(f"⊘ Skipped: {counts['skipped']}")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")


if __name__ == "__main__":
    main()

