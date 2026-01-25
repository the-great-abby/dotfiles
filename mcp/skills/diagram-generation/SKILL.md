---
name: Diagram Generation
description: Generate visual diagrams and mindmaps using AI. Supports Mermaid, PlantUML, DOT, and Text formats. Automatically gathers GTD data when creating diagrams about your GTD system.
version: 1.0.0
tags:
  - visualization
  - diagrams
  - mindmaps
  - productivity
  - gtd
  - mermaid
  - plantuml
author: GTD System
---

# Diagram Generation Skill

A comprehensive skill for generating visual diagrams and mindmaps using AI. Perfect for visualizing your GTD system, project structures, relationships, processes, and ideas.

## When to Use

Use this skill when you need to:
- **Visualize GTD system**: Create mindmaps or flowcharts of your GTD structure
- **Project planning**: Generate diagrams for project workflows and timelines
- **Process documentation**: Create flowcharts for processes and workflows
- **Relationship mapping**: Visualize connections between projects, tasks, areas
- **Knowledge organization**: Create mindmaps for learning and knowledge management
- **Planning**: Generate Gantt charts for timelines, sequence diagrams for processes

## How It Works

This skill uses the `gtd-diagram` command-line tool which:
1. Uses Claude API (preferred) or deep model to generate diagram code
2. Automatically gathers GTD data (projects, tasks, areas) when relevant
3. Supports multiple output formats (Mermaid, PlantUML, DOT, Text)
4. Saves diagrams to `~/Documents/gtd/diagrams/` directory

## Supported Diagram Types

### 1. **Mindmap** (`mindmap`)
Best for brainstorming, organizing thoughts, visualizing relationships, project structure.

**Examples:**
- "Create a mindmap of my GTD system"
- "Create a mindmap of my active projects"
- "Create a mindmap of wedding planning"

### 2. **Flowchart** (`flowchart`)
Best for processes, workflows, decision trees, step-by-step procedures.

**Examples:**
- "Create a flowchart of the inbox processing workflow"
- "Create a flowchart of the weekly review process"
- "Create a flowchart of incident response procedure"

### 3. **Sequence Diagram** (`sequence`)
Best for interactions between components, process sequences, communication flows.

**Examples:**
- "Create a sequence diagram of GTD system interactions"
- "Create a sequence diagram of daily log review process"

### 4. **Gantt Chart** (`gantt`)
Best for project timelines, scheduling, milestone tracking.

**Examples:**
- "Create a Gantt chart of wedding planning timeline"
- "Create a Gantt chart of SRE career development plan"

### 5. **State Diagram** (`state`)
Best for state transitions, lifecycles, status flows.

**Examples:**
- "Create a state diagram of project lifecycle"
- "Create a state diagram of task status flow"

### 6. **Entity-Relationship** (`er`)
Best for data relationships, system architecture, database design.

**Examples:**
- "Create an ER diagram of GTD system data model"
- "Create an ER diagram of Second Brain structure"

## Supported Output Formats

### 1. **Mermaid** (default)
- Works in Obsidian, GitHub, GitLab
- Format: `--format mermaid` or default

### 2. **PlantUML**
- Very reliable with AI, requires Java
- Format: `--format plantuml`
- Best for flowcharts and sequence diagrams

### 3. **Graphviz/DOT**
- Simple, reliable, requires Graphviz
- Format: `--format dot`
- Best for hierarchies and mindmaps

### 4. **Text**
- Always works, no dependencies
- Format: `--format text`
- Best for simple mindmaps

## Step-by-Step Workflow

### Step 1: Determine Diagram Type and Topic

**Questions to ask:**
- What do you want to visualize? (system, project, process, relationships)
- What type of diagram fits best? (mindmap, flowchart, sequence, etc.)
- What format should be used? (mermaid, plantuml, dot, text)

**Examples:**
- "I want to visualize my GTD system structure" → mindmap
- "I want to document my inbox processing workflow" → flowchart
- "I want to see my project timeline" → gantt

### Step 2: Gather GTD Data (if relevant)

If the diagram is about GTD system, projects, tasks, or areas, the tool automatically gathers data. However, you can also gather it manually:

**For projects:**
- Use `gtd_list_projects()` to get project list
- Use `gtd_get_project_status(project_name="...")` for project details

**For tasks:**
- Use `gtd_list_tasks(status="active")` to get active tasks
- Use `gtd_get_context_tasks(context="...")` for context-specific tasks

**For areas:**
- Use `gtd_list_areas()` to get areas of responsibility

**Note:** The `gtd-diagram` tool automatically detects GTD-related keywords and gathers data, so manual gathering is usually not needed.

### Step 3: Generate Diagram

Use the `gtd-diagram` command with appropriate parameters:

**Basic syntax:**
```bash
gtd-diagram <type> "<description>" [--format <format>]
```

**Examples:**
```bash
# Create a mindmap
gtd-diagram mindmap "GTD System Overview"

# Create a flowchart with PlantUML format
gtd-diagram flowchart "Daily Review Process" --format plantuml

# Create a Gantt chart
gtd-diagram create gantt "Wedding Planning Timeline"

# Create a sequence diagram
gtd-diagram create sequence "GTD System Interactions"
```

### Step 4: Review and Refine

After generation:
1. Check the diagram file in `~/Documents/gtd/diagrams/`
2. View in Obsidian (for Mermaid) or render (for PlantUML/DOT)
3. If syntax errors, use `gtd-diagram fix <name>` to fix
4. Refine description and regenerate if needed

## Detailed Workflow Examples

### Example 1: Create GTD System Mindmap

**Goal:** Visualize the complete GTD system structure

**Steps:**
1. Determine: mindmap type, mermaid format (default)
2. The tool automatically detects "GTD system" and gathers:
   - Active projects
   - Active tasks
   - Areas of responsibility
3. Generate:
   ```bash
   gtd-diagram mindmap "My Complete GTD System"
   ```
4. Review the generated diagram in `~/Documents/gtd/diagrams/my-complete-gtd-system.md`

**Expected output:**
- Mindmap with root node "My Complete GTD System"
- Branches for Projects, Tasks, Areas
- Sub-branches with actual project/task/area names from your system

### Example 2: Create Project Workflow Flowchart

**Goal:** Document the workflow for a specific project

**Steps:**
1. Gather project information:
   ```python
   project = gtd_get_project_status(project_name="Wedding Planning")
   tasks = gtd_list_tasks(project="Wedding Planning", status="active")
   ```
2. Determine: flowchart type, plantuml format (more reliable)
3. Generate:
   ```bash
   gtd-diagram flowchart "Wedding Planning Process from Start to Finish" --format plantuml
   ```
4. The tool automatically includes project data if detected in description

**Expected output:**
- Flowchart showing project workflow
- Steps based on actual tasks in the project
- Decision points and process flow

### Example 3: Create Task Organization Diagram

**Goal:** Visualize how tasks are organized by priority and context

**Steps:**
1. Gather task data:
   ```python
   tasks = gtd_list_tasks(status="active")
   # Group by priority and context
   ```
2. Determine: mindmap or flowchart, dot format (simple and reliable)
3. Generate:
   ```bash
   gtd-diagram mindmap "Task Organization by Priority and Context" --format dot
   ```
4. Review and refine if needed

### Example 4: Create Process Sequence Diagram

**Goal:** Document the sequence of interactions in a process

**Steps:**
1. Determine: sequence diagram type, plantuml format
2. Generate:
   ```bash
   gtd-diagram create sequence "Daily Review Process with All Personas" --format plantuml
   ```
3. The description should include key actors/participants

**Expected output:**
- Sequence diagram showing interactions
- Participants as actors
- Messages/actions between participants

## Format Selection Guide

### Use **PlantUML** when:
- ✅ You're creating flowcharts or sequence diagrams
- ✅ You want professional-looking diagrams
- ✅ You need reliable syntax (AI generates it well)
- ✅ You have Java installed (for rendering)

### Use **Graphviz/DOT** when:
- ✅ You're creating mindmaps or hierarchies
- ✅ You want simple, reliable syntax
- ✅ You have Graphviz installed (for rendering)
- ✅ You want to render to PNG/SVG

### Use **Text** when:
- ✅ You're creating simple mindmaps
- ✅ You want no dependencies
- ✅ You don't need visual rendering
- ✅ You want maximum reliability

### Use **Mermaid** when:
- ✅ You need Obsidian/GitHub integration
- ✅ You want to view in markdown viewers
- ✅ You're okay with occasional syntax issues (AI sometimes generates invalid Mermaid)

## Best Practices

### Diagram Descriptions

**Good descriptions:**
- "My GTD System Overview" (clear, specific)
- "Wedding Planning Process from Start to Finish" (descriptive)
- "Daily Review Workflow with Decision Points" (includes key elements)

**Poor descriptions:**
- "diagram" (too vague)
- "stuff" (not descriptive)
- "my system" (unclear what system)

### GTD Data Integration

The tool automatically detects GTD-related keywords:
- "my projects", "projects", "gtd", "tasks", "areas", etc.

When detected, it automatically:
1. Gathers relevant GTD data
2. Includes it in the prompt
3. Generates diagrams based on actual data

**To ensure data is included:**
- Use keywords like "my projects", "my tasks", "my GTD system"
- Be specific about what GTD data to include

### Format Selection

**For reliability:**
1. Start with PlantUML for flowcharts/sequences
2. Use DOT for mindmaps
3. Use Text for simple mindmaps
4. Use Mermaid only if you need Obsidian integration

**For rendering:**
- PlantUML: `plantuml diagram.puml`
- DOT: `dot -Tpng diagram.dot -o diagram.png`
- Mermaid: View in Obsidian or Mermaid Live Editor
- Text: View directly

### Error Handling

If diagram generation fails or has syntax errors:

1. **Try a different format:**
   ```bash
   # Original (Mermaid, had errors)
   gtd-diagram mindmap "Topic"
   
   # Try PlantUML instead
   gtd-diagram mindmap "Topic" --format plantuml
   ```

2. **Use the fix command:**
   ```bash
   gtd-diagram fix my-diagram-name
   ```

3. **Regenerate with clearer description:**
   - Be more specific about what you want
   - Include key elements in the description

## Integration with Other Skills

This skill works well with:
- **`task-summary`**: Generate diagrams from task summaries
- **`project-status-review`**: Create diagrams of project structures
- **`interactive-morning-review-runbook`**: Visualize daily workflows
- **`daily-review`**: Create diagrams of review processes

## Common Use Cases

### 1. Visualize GTD System Structure
```bash
gtd-diagram mindmap "My GTD System Structure"
```

### 2. Document Workflows
```bash
gtd-diagram flowchart "Inbox Processing Workflow" --format plantuml
```

### 3. Plan Projects
```bash
gtd-diagram gantt "Wedding Planning Timeline"
gtd-diagram mindmap "Wedding Planning Checklist"
```

### 4. Understand Relationships
```bash
gtd-diagram create er "GTD System Data Relationships"
```

### 5. Document Processes
```bash
gtd-diagram flowchart "Weekly Review Process" --format plantuml
gtd-diagram create sequence "Daily Log Review Process"
```

## Troubleshooting

### "Diagram has syntax errors"

**Solutions:**
1. Use `gtd-diagram fix <name>` to auto-fix
2. Try a different format (PlantUML or DOT are more reliable)
3. Regenerate with a clearer description

### "Diagram doesn't include my GTD data"

**Solutions:**
1. Use keywords like "my projects", "my tasks", "my GTD system"
2. Be specific in the description about what data to include
3. Check that the tool detected GTD keywords (it should print "📊 Gathering GTD data...")

### "Claude API not configured"

**Solutions:**
1. Set `ANTHROPIC_API_KEY` environment variable
2. Or add to `~/.gtd_config_ai`: `ANTHROPIC_API_KEY="sk-ant-..."`
3. The tool will fall back to deep model or persona helper if Claude isn't available

### "Format not rendering"

**Solutions:**
- **PlantUML**: Install Java and PlantUML (`brew install plantuml`)
- **DOT**: Install Graphviz (`brew install graphviz`)
- **Mermaid**: View in Obsidian or use Mermaid Live Editor
- **Text**: View directly (no rendering needed)

## Success Criteria

A successful diagram generation:
- ✓ Diagram file created in `~/Documents/gtd/diagrams/`
- ✓ Diagram syntax is valid (or can be fixed)
- ✓ Diagram includes relevant GTD data (if applicable)
- ✓ Diagram is viewable/rendered correctly
- ✓ Diagram helps visualize the intended concept

## Advanced Usage

### Custom System Prompts

The tool uses Claude API with a system prompt optimized for diagram generation. The system prompt includes:
- Instructions for proper syntax
- Format-specific requirements
- GTD data usage guidelines

### Batch Generation

You can generate multiple diagrams:
```bash
gtd-diagram mindmap "Project A Structure"
gtd-diagram mindmap "Project B Structure"
gtd-diagram flowchart "Combined Workflow"
```

### Integration with Second Brain

Diagrams can be saved to Second Brain:
```bash
gtd-diagram save my-diagram.md
```

This copies the diagram to `Second Brain/Resources/` for viewing in Obsidian.

## Example Output Locations

Diagrams are saved to:
- **Location**: `~/Documents/gtd/diagrams/`
- **Format**: Markdown files with diagram code blocks
- **Naming**: Based on description (sanitized, lowercase, hyphenated)

**Example files:**
- `my-gtd-system.md` (Mermaid mindmap)
- `wedding-planning-process.puml` (PlantUML flowchart)
- `task-organization.dot` (DOT graph)
- `simple-mindmap.txt` (Text tree)

## Related Documentation

- **Diagram Guide**: `docs/DIAGRAM_GENERATION_GUIDE.md`
- **Format Guide**: `docs/DIAGRAM_FORMATS_QUICK_START.md`
- **Deep Model Integration**: `docs/DIAGRAM_DEEP_MODEL_INTEGRATION.md`
- **MCP Data Integration**: `docs/DIAGRAM_MCP_DATA_INTEGRATION.md`

Remember: The goal is to create visual representations that help you understand, plan, and organize your GTD system and projects more effectively.
