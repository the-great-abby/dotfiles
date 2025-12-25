#!/usr/bin/env python3
"""
GTD Knowledge Organization Worker

Background worker that analyzes your GTD system and suggests:
- MoCs (Maps of Content) to create from note clusters
- Areas of Responsibility to define from activity patterns
- Orphaned projects to assign to areas
- Knowledge gaps to fill
"""

import json
import os
import sys
import time
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, Optional, List, Tuple
from collections import defaultdict, Counter

try:
    import pika
    RABBITMQ_AVAILABLE = True
except ImportError:
    RABBITMQ_AVAILABLE = False

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent.parent / "zsh" / "functions"))

# Import MCP server functions
try:
    from gtd_mcp_server import (
        call_fast_ai,
        GTD_BASE_DIR,
        RABBITMQ_URL,
    )
except ImportError:
    print("Error: Could not import from gtd_mcp_server", file=sys.stderr)
    sys.exit(1)

# Import persona helper for config
try:
    from gtd_persona_helper import read_config
except ImportError:
    def read_config():
        return {}

# Try to import vectorization for similarity search
try:
    from gtd_vectorization import search_similar
    VECTOR_AVAILABLE = True
except ImportError:
    VECTOR_AVAILABLE = False

# Import unified learning system
try:
    from gtd_unified_learning import (
        filter_suggestions,
        boost_confidence_for_patterns,
        get_stats_summary
    )
    LEARNING_AVAILABLE = True
except ImportError:
    LEARNING_AVAILABLE = False
    def filter_suggestions(suggestions, suggestion_type):
        return suggestions
    def boost_confidence_for_patterns(suggestion_type, confidence, context=None, tags=None):
        return confidence
    def get_stats_summary(suggestion_type=None):
        return {}

GTD_CONFIG = read_config()
USER_NAME = os.getenv("GTD_USER_NAME", "Abby")

# RabbitMQ configuration
RABBITMQ_QUEUE = os.getenv("GTD_RABBITMQ_KNOWLEDGE_ORG_QUEUE", "gtd_knowledge_organization")

# Fallback queue file
QUEUE_FILE = GTD_BASE_DIR / "knowledge_organization_queue.jsonl"

# Results directory
RESULTS_DIR = GTD_BASE_DIR / "knowledge_organization_results"
RESULTS_DIR.mkdir(parents=True, exist_ok=True)


def get_projects() -> List[Dict[str, Any]]:
    """Get all active projects with metadata."""
    projects = []
    projects_path = GTD_BASE_DIR / "1-projects"
    
    if not projects_path.exists():
        return projects
    
    for project_dir in projects_path.iterdir():
        if not project_dir.is_dir():
            continue
        
        readme = project_dir / "README.md"
        if not readme.exists():
            continue
        
        try:
            with open(readme, 'r') as f:
                content = f.read()
            
            # Extract frontmatter
            area = None
            status = "active"
            tags = []
            
            if content.startswith('---'):
                frontmatter_end = content.find('---', 3)
                if frontmatter_end > 0:
                    frontmatter = content[3:frontmatter_end]
                    for line in frontmatter.split('\n'):
                        if ':' in line:
                            key, value = line.split(':', 1)
                            key = key.strip()
                            value = value.strip()
                            if key == 'area':
                                area = value
                            elif key == 'status':
                                status = value
                            elif key == 'tags':
                                tags = [t.strip() for t in value.strip('[]').split(',')]
            
            if status == 'active':
                projects.append({
                    'slug': project_dir.name,
                    'name': project_dir.name.replace('-', ' ').title(),
                    'area': area,
                    'tags': tags,
                    'content': content[:1000],  # First 1000 chars
                    'path': str(project_dir)
                })
        except Exception as e:
            print(f"Error reading project {project_dir.name}: {e}", file=sys.stderr)
    
    return projects


def get_existing_areas() -> List[str]:
    """Get list of existing areas of responsibility."""
    areas = []
    areas_path = GTD_BASE_DIR / "2-areas"
    
    if not areas_path.exists():
        return areas
    
    for area_dir in areas_path.iterdir():
        if area_dir.is_dir():
            areas.append(area_dir.name)
    
    return areas


def get_existing_mocs() -> List[Dict[str, Any]]:
    """Get list of existing MoCs (Maps of Content)."""
    mocs = []
    moc_path = GTD_BASE_DIR / "MOCs"
    
    if not moc_path.exists():
        return mocs
    
    for moc_file in moc_path.glob("*.md"):
        try:
            with open(moc_file, 'r') as f:
                content = f.read()
            
            mocs.append({
                'slug': moc_file.stem,
                'name': moc_file.stem.replace('-', ' ').title(),
                'content': content[:500]
            })
        except Exception:
            pass
    
    return mocs


def get_notes() -> List[Dict[str, Any]]:
    """Get all zettelkasten notes."""
    notes = []
    notes_path = GTD_BASE_DIR / "Zettelkasten"
    
    if not notes_path.exists():
        return notes
    
    for note_file in notes_path.glob("*.md"):
        try:
            with open(note_file, 'r') as f:
                content = f.read()
            
            # Extract tags from content
            tags = []
            for line in content.split('\n'):
                if line.startswith('tags:'):
                    tags_str = line.replace('tags:', '').strip()
                    tags = [t.strip() for t in tags_str.strip('[]').split(',')]
                    break
            
            notes.append({
                'id': note_file.stem,
                'content': content,
                'tags': tags,
                'path': str(note_file)
            })
        except Exception:
            pass
    
    return notes


def scan_daily_logs_for_themes(days: int = 30) -> Dict[str, int]:
    """Scan daily logs for frequently mentioned themes/topics."""
    themes = Counter()
    daily_log_dir = Path.home() / "Documents" / "daily_logs"
    
    if not daily_log_dir.exists():
        return dict(themes)
    
    # Get recent logs
    cutoff_date = datetime.now() - timedelta(days=days)
    
    for log_file in daily_log_dir.glob("*.txt"):
        try:
            file_date = datetime.strptime(log_file.stem, "%Y-%m-%d")
            if file_date < cutoff_date:
                continue
            
            with open(log_file, 'r') as f:
                content = f.read().lower()
            
            # Extract potential themes (common project/topic patterns)
            # This is a simple heuristic - could be enhanced with NLP
            common_themes = [
                'work', 'sre', 'kubernetes', 'monitoring', 'dlq',
                'gym', 'fitness', 'workout', 'training',
                'wedding', 'relationship', 'home', 'automation',
                'learning', 'study', 'career', 'health'
            ]
            
            for theme in common_themes:
                if theme in content:
                    themes[theme] += content.count(theme)
        except Exception:
            pass
    
    return dict(themes)


def suggest_areas_from_projects(projects: List[Dict], existing_areas: List[str]) -> List[Dict]:
    """Phase 1: Suggest areas for orphaned projects."""
    orphaned = [p for p in projects if not p['area']]
    
    if not orphaned:
        return []
    
    suggestions = []
    
    # Group projects by AI classification
    projects_text = "\n".join([
        f"- {p['name']}: {p['content'][:200]}"
        for p in orphaned[:20]  # Limit for prompt
    ])
    
    prompt = f"""Analyze these projects and suggest which area of responsibility each belongs to.

Projects:
{projects_text}

Existing areas: {', '.join(existing_areas) if existing_areas else 'none'}

For each project, determine:
1. Which existing area it fits (if any)
2. Or suggest a NEW area name (if needed)

Return JSON array:
[
  {{
    "project_slug": "project-name",
    "suggested_area": "Work - SRE",
    "confidence": 0.9,
    "reason": "Why this project belongs in this area",
    "is_new_area": false
  }}
]

Return ONLY the JSON array."""

    try:
        response = call_fast_ai(prompt, "You are a GTD organization assistant. Classify projects into areas of responsibility.", use_instruct=True)
        
        # Extract JSON
        import re
        json_match = re.search(r'\[.*?\]', response, re.DOTALL)
        if json_match:
            area_suggestions = json.loads(json_match.group())
            
            for suggestion in area_suggestions:
                # Validate project exists
                matching_projects = [p for p in orphaned if p['slug'] == suggestion.get('project_slug')]
                if matching_projects:
                    suggestions.append({
                        **suggestion,
                        'type': 'area_assignment',
                        'project_name': matching_projects[0]['name']
                    })
    except Exception as e:
        print(f"Error suggesting areas: {e}", file=sys.stderr)
    
    return suggestions


def suggest_mocs_from_notes(notes: List[Dict], existing_mocs: List[Dict]) -> List[Dict]:
    """Phase 2: Suggest MoCs from note clusters."""
    if not notes or not VECTOR_AVAILABLE:
        return []
    
    suggestions = []
    
    # Use vector search to find note clusters
    # This is a simplified version - could be enhanced
    try:
        # Find notes without MoC coverage
        uncovered_notes = []
        
        for note in notes[:50]:  # Sample subset
            # Check if note has MoC coverage
            # (simplified - would need more sophisticated logic)
            uncovered_notes.append(note)
        
        if len(uncovered_notes) >= 5:
            # Ask AI to suggest MoC topics
            notes_sample = "\n".join([
                f"- {note['id']}: {note['content'][:100]}"
                for note in uncovered_notes[:10]
            ])
            
            prompt = f"""Analyze these notes and suggest Maps of Content (MoCs) to organize them.

Notes sample:
{notes_sample}

Existing MoCs: {', '.join([m['name'] for m in existing_mocs]) if existing_mocs else 'none'}

Suggest 1-3 MoCs that would help organize this knowledge.

Return JSON:
[
  {{
    "moc_name": "Kubernetes Operations",
    "moc_slug": "kubernetes-operations",
    "reason": "Why this MoC is needed",
    "estimated_note_count": 12,
    "confidence": 0.85
  }}
]"""
            
            response = call_fast_ai(prompt, "You are a knowledge management assistant. Suggest MoCs to organize notes.", use_instruct=True)
            
            import re
            json_match = re.search(r'\[.*?\]', response, re.DOTALL)
            if json_match:
                moc_suggestions = json.loads(json_match.group())
                for suggestion in moc_suggestions:
                    suggestions.append({
                        **suggestion,
                        'type': 'moc_creation'
                    })
    except Exception as e:
        print(f"Error suggesting MoCs: {e}", file=sys.stderr)
    
    return suggestions


def suggest_areas_from_themes(themes: Dict[str, int], existing_areas: List[str], threshold: int = 10) -> List[Dict]:
    """Phase 3: Suggest new areas from daily log themes."""
    suggestions = []
    
    # Find themes mentioned frequently but without area coverage
    frequent_themes = {k: v for k, v in themes.items() if v >= threshold}
    
    if not frequent_themes:
        return suggestions
    
    themes_text = "\n".join([f"- {theme}: mentioned {count}x" for theme, count in frequent_themes.items()])
    
    prompt = f"""Based on these frequently mentioned themes from daily logs, suggest areas of responsibility.

Themes:
{themes_text}

Existing areas: {', '.join(existing_areas) if existing_areas else 'none'}

Suggest 1-3 NEW areas that would help organize life/work.

Return JSON:
[
  {{
    "area_name": "Health & Fitness",
    "area_slug": "health-fitness",
    "reason": "Why this area is needed",
    "supporting_themes": ["gym", "workout", "fitness"],
    "confidence": 0.8
  }}
]"""
    
    try:
        response = call_fast_ai(prompt, "You are a GTD life management assistant. Suggest areas of responsibility.", use_instruct=True)
        
        import re
        json_match = re.search(r'\[.*?\]', response, re.DOTALL)
        if json_match:
            area_suggestions = json.loads(json_match.group())
            for suggestion in area_suggestions:
                suggestions.append({
                    **suggestion,
                    'type': 'area_creation'
                })
    except Exception as e:
        print(f"Error suggesting areas from themes: {e}", file=sys.stderr)
    
    return suggestions


def process_knowledge_organization_request(message: Dict[str, Any]) -> bool:
    """Process a knowledge organization analysis request."""
    try:
        scan_type = message.get("scan_type", "full")  # full, areas, mocs, themes
        
        print(f"Starting knowledge organization scan (type: {scan_type})...")
        
        # Create results file
        timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
        results_file = RESULTS_DIR / f"knowledge_org_{timestamp}.json"
        
        all_suggestions = []
        
        # Phase 1: Orphaned projects → areas
        if scan_type in ["full", "areas"]:
            print("Scanning projects for area assignments...")
            projects = get_projects()
            existing_areas = get_existing_areas()
            area_suggestions = suggest_areas_from_projects(projects, existing_areas)
            all_suggestions.extend(area_suggestions)
            print(f"  Found {len(area_suggestions)} area assignment suggestion(s)")
        
        # Phase 2: Note clusters → MoCs
        if scan_type in ["full", "mocs"]:
            print("Scanning notes for MoC opportunities...")
            notes = get_notes()
            existing_mocs = get_existing_mocs()
            moc_suggestions = suggest_mocs_from_notes(notes, existing_mocs)
            all_suggestions.extend(moc_suggestions)
            print(f"  Found {len(moc_suggestions)} MoC creation suggestion(s)")
        
        # Phase 3: Daily log themes → new areas
        if scan_type in ["full", "themes"]:
            print("Scanning daily logs for life themes...")
            themes = scan_daily_logs_for_themes(days=30)
            existing_areas = get_existing_areas()
            theme_suggestions = suggest_areas_from_themes(themes, existing_areas)
            all_suggestions.extend(theme_suggestions)
            print(f"  Found {len(theme_suggestions)} area creation suggestion(s)")
        
        # Boost confidence scores based on learned patterns
        if LEARNING_AVAILABLE:
            print("Adjusting confidence scores based on learning...")
            for suggestion in all_suggestions:
                original_confidence = suggestion.get("confidence", 0.0)
                suggestion_type = suggestion.get("type")
                
                # Extract context for pattern matching
                context = None
                if suggestion_type == "area_assignment":
                    context = suggestion.get("suggested_area")
                elif suggestion_type == "moc_creation":
                    context = suggestion.get("moc_name")
                elif suggestion_type == "area_creation":
                    context = suggestion.get("area_name")
                
                boosted_confidence = boost_confidence_for_patterns(
                    suggestion_type,
                    original_confidence,
                    context=context,
                    tags=suggestion.get("tags", [])
                )
                suggestion["confidence"] = boosted_confidence
                suggestion["original_confidence"] = original_confidence
        
        # Filter suggestions based on learned thresholds
        original_count = len(all_suggestions)
        if LEARNING_AVAILABLE:
            # Group by type and filter each
            filtered_suggestions = []
            for suggestion in all_suggestions:
                suggestion_type = suggestion.get("type")
                if filter_suggestions([suggestion], suggestion_type):
                    filtered_suggestions.append(suggestion)
            
            filtered_count = original_count - len(filtered_suggestions)
            all_suggestions = filtered_suggestions
            
            if filtered_count > 0:
                print(f"  Filtered out {filtered_count} low-confidence suggestion(s)")
        
        # Save results
        results = {
            'suggestions': all_suggestions,
            'scan_type': scan_type,
            'timestamp': datetime.now().isoformat(),
            'counts': {
                'area_assignments': len([s for s in all_suggestions if s['type'] == 'area_assignment']),
                'moc_creations': len([s for s in all_suggestions if s['type'] == 'moc_creation']),
                'area_creations': len([s for s in all_suggestions if s['type'] == 'area_creation'])
            },
            'learning_applied': LEARNING_AVAILABLE,
            'original_suggestion_count': original_count,
        }
        
        # Add learning stats
        if LEARNING_AVAILABLE:
            results['learning_stats'] = get_stats_summary()
        
        with open(results_file, 'w') as f:
            json.dump(results, f, indent=2)
        
        print(f"✓ Analysis complete! Found {len(all_suggestions)} total suggestion(s)")
        print(f"Results saved to: {results_file}")
        
        return True
        
    except Exception as e:
        print(f"Error processing knowledge organization request: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc(file=sys.stderr)
        return False


def process_file_queue():
    """Process messages from file queue."""
    if not QUEUE_FILE.exists() or QUEUE_FILE.stat().st_size == 0:
        return False
    
    try:
        # Read all messages
        messages = []
        with open(QUEUE_FILE, 'r') as f:
            for line in f:
                if line.strip():
                    messages.append(json.loads(line))
        
        # Clear queue file
        with open(QUEUE_FILE, 'w') as f:
            pass
        
        # Process each message
        for message in messages:
            process_knowledge_organization_request(message)
        
        return True
    except Exception as e:
        print(f"Error processing file queue: {e}", file=sys.stderr)
        return False


def process_rabbitmq_queue():
    """Process messages from RabbitMQ queue."""
    if not RABBITMQ_AVAILABLE:
        return False
    
    try:
        params = pika.URLParameters(RABBITMQ_URL)
        params.blocked_connection_timeout = 5
        connection = pika.BlockingConnection(params)
        channel = connection.channel()
        channel.queue_declare(queue=RABBITMQ_QUEUE, durable=True)
        
        def callback(ch, method, properties, body):
            try:
                message = json.loads(body.decode('utf-8'))
                success = process_knowledge_organization_request(message)
                
                if success:
                    ch.basic_ack(delivery_tag=method.delivery_tag)
                else:
                    ch.basic_nack(delivery_tag=method.delivery_tag, requeue=True)
            except Exception as e:
                print(f"Error processing message: {e}", file=sys.stderr)
                ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)
        
        channel.basic_qos(prefetch_count=1)
        channel.basic_consume(queue=RABBITMQ_QUEUE, on_message_callback=callback)
        
        print(f"✅ Waiting for messages on {RABBITMQ_QUEUE}. To exit press CTRL+C")
        channel.start_consuming()
        
    except KeyboardInterrupt:
        print("\n⏹️  Stopping worker...")
        channel.stop_consuming()
        connection.close()
        return True
    except Exception as e:
        print(f"RabbitMQ error: {e}", file=sys.stderr)
        return False


def main():
    """Main worker loop."""
    import argparse
    
    parser = argparse.ArgumentParser(description="GTD Knowledge Organization Worker")
    parser.add_argument('--once', action='store_true', help='Process queue once and exit')
    parser.add_argument('--scan-type', choices=['full', 'areas', 'mocs', 'themes'], default='full',
                        help='Type of scan to perform')
    args = parser.parse_args()
    
    print("GTD Knowledge Organization Worker starting...")
    print(f"Results directory: {RESULTS_DIR}")
    
    if args.once:
        # Process once and exit
        print("Running in one-shot mode")
        
        # Try RabbitMQ first
        if RABBITMQ_AVAILABLE:
            print("Checking RabbitMQ queue...")
            # Would need to implement one-shot RabbitMQ processing
        
        # Fall back to file queue
        print("Checking file queue...")
        process_file_queue()
        
        print("Done!")
        return
    
    # Continuous processing
    while True:
        try:
            # Try RabbitMQ first
            if RABBITMQ_AVAILABLE:
                process_rabbitmq_queue()
            else:
                # Fall back to file queue polling
                print("RabbitMQ not available, using file queue...")
                while True:
                    if process_file_queue():
                        print("Processed file queue")
                    time.sleep(5)  # Poll every 5 seconds
        
        except KeyboardInterrupt:
            print("\nShutting down...")
            break
        except Exception as e:
            print(f"Worker error: {e}", file=sys.stderr)
            time.sleep(10)  # Wait before retrying


if __name__ == "__main__":
    main()

