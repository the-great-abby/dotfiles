# Agent Skills Support

This system now supports **Agent Skills** - a format for giving agents new capabilities through modular, reusable skill packages. This is compatible with the [Agent Skills specification](https://agentskills.io/).

## Overview

Agent Skills are folders containing:
- **SKILL.md**: Metadata (YAML frontmatter) + instructions (Markdown)
- **Optional directories**:
  - `scripts/`: Executable scripts (Python, shell, etc.)
  - `templates/`: Template files with variable substitution
  - `resources/`: Supporting files, data, etc.

Skills are discovered automatically from the `mcp/skills/` directory and runbooks from `mcp/runbooks/` directory. Both can be used via MCP tools. Runbooks are interactive, step-by-step workflows that ask questions and wait for responses, while skills are automated workflows.

## Quick Start

### 1. Skill Directory Structure

Skills are stored in `mcp/skills/`. Each skill is a folder with a `SKILL.md` file:

```
mcp/skills/
├── example-skill/
│   └── SKILL.md
├── your-skill/
│   ├── SKILL.md
│   ├── scripts/
│   │   └── execute.sh
│   └── templates/
│       └── output.md
└── another-skill/
    └── SKILL.md
```

### 2. Creating a Skill

Create a new folder in `mcp/skills/` and add a `SKILL.md` file:

```markdown
---
name: My Skill
description: A skill that does something useful
version: 1.0.0
tags:
  - productivity
  - automation
author: Your Name
---

# My Skill

## When to Use

Describe when this skill should be used...

## How It Works

Explain how the skill works...

## Usage

Provide usage examples...
```

### 3. Using Skills via MCP

Skills are automatically available through MCP tools:

```python
# List all available skills
list_agent_skills()

# Search skills
list_agent_skills(query="productivity", tags=["automation"])

# Get skill details
get_agent_skill(skill_name="My Skill")

# Search skills (includes runbooks by default)
list_agent_skills(query="productivity", tags=["automation"])

# List only runbooks (interactive workflows)
list_agent_skills(runbooks_only=True)

# List only skills (automated workflows)
list_agent_skills(runbooks_only=False)
    skill_name="My Skill",
    method="instructions",  # or "script:run.sh" or "template:output.md"
    args={"param1": "value1"}
)

# Reload skills after adding/modifying
reload_agent_skills()
```

## SKILL.md Format

The `SKILL.md` file uses YAML frontmatter for metadata, followed by Markdown instructions:

```yaml
---
name: Skill Name
description: Brief description
version: 1.0.0
tags:
  - tag1
  - tag2
author: Author Name
# Optional: tool schema for MCP integration
tool:
  type: object
  properties:
    param1:
      type: string
      description: Parameter description
  required: ["param1"]
---
```

The Markdown body contains detailed instructions that agents can use when the skill is activated.

## Skill Execution Methods

### 1. Instructions (`method="instructions"`)

Returns the skill's instructions as text. This is the default method.

```python
execute_agent_skill(
    skill_name="My Skill",
    method="instructions"
)
```

### 2. Script Execution (`method="script:<script_name>"`)

Executes a script from the skill's `scripts/` directory.

**Python scripts:**
```bash
# scripts/my_script.py
import sys
import json
import os

args = json.loads(os.environ.get("SKILL_ARGS", "{}"))
# Use args["param1"], etc.
```

**Shell scripts:**
```bash
#!/bin/bash
# scripts/my_script.sh
# Arguments available via env vars: SKILL_ARGS (JSON) or SKILL_ARG_<NAME>
echo "Executing with args: $SKILL_ARGS"
```

```python
execute_agent_skill(
    skill_name="My Skill",
    method="script:my_script.py",
    args={"param1": "value1", "param2": "value2"}
)
```

Arguments are passed as:
- `SKILL_ARGS` environment variable (JSON string)
- Individual `SKILL_ARG_<KEY>` environment variables

### 3. Template Rendering (`method="template:<template_name>"`)

Renders a template file from the skill's `templates/` directory with variable substitution.

**Template file:**
```markdown
Hello {{ name }}!
You have {{ count }} tasks.

{{ message }}
```

```python
execute_agent_skill(
    skill_name="My Skill",
    method="template:greeting.md",
    args={
        "name": "Abby",
        "count": "5",
        "message": "Have a great day!"
    }
)
```

Templates support `{{ variable }}` and `{{{ variable }}}` syntax.

## Example Skills

### Example: Task Automation Skill

```markdown
---
name: Task Automation
description: Automate common task creation workflows
version: 1.0.0
tags:
  - tasks
  - automation
---

# Task Automation Skill

## When to Use

Use this skill when you need to create multiple related tasks from a single description or automate repetitive task creation workflows.

## How It Works

This skill uses natural language processing to break down complex goals into actionable tasks with proper context and priorities.
```

### Example: Skill with Script

```bash
# scripts/generate_report.sh
#!/bin/bash
# Generate a task report

DATE=$(date +%Y-%m-%d)
OUTPUT_FILE="/tmp/task_report_${DATE}.txt"

# Access skill arguments
TASK_TYPE=$(echo $SKILL_ARGS | jq -r '.task_type // "all"')

# Generate report...
echo "Report generated: $OUTPUT_FILE"
```

## MCP Tools Reference

### `list_agent_skills`

List all available skills, optionally filtered by query or tags.

**Parameters:**
- `query` (optional): Search query to filter skills
- `tags` (optional): Array of tags to filter skills

**Returns:**
```json
{
  "skills": [
    {
      "id": "skill-name",
      "path": "/path/to/skill",
      "metadata": {...},
      "instructions_preview": "...",
      "has_scripts": true,
      "has_templates": false,
      "has_resources": false
    }
  ],
  "count": 1
}
```

### `get_agent_skill`

Get detailed information about a specific skill.

**Parameters:**
- `skill_name` (required): Name of the skill

**Returns:**
```json
{
  "skill": {...},
  "full_instructions": "...",
  "metadata": {...},
  "has_scripts": true,
  "has_templates": true,
  "has_resources": false
}
```

### `execute_agent_skill`

Execute a skill using a specific method.

**Parameters:**
- `skill_name` (required): Name of the skill
- `method` (optional): Execution method (default: "instructions")
  - `"instructions"`: Return skill instructions
  - `"script:<script_name>"`: Execute a script
  - `"template:<template_name>"`: Render a template
- `args` (optional): Arguments to pass to the skill

**Returns:**
```json
{
  "success": true,
  "output": "...",
  "metadata": {
    "skill": "skill-name",
    "method": "instructions",
    "metadata": {...}
  }
}
```

### `reload_agent_skills`

Reload all skills from disk. Use after adding, modifying, or removing skills.

**Returns:**
```json
{
  "success": true,
  "message": "Skills reloaded successfully",
  "skills_loaded": 5,
  "skills": ["skill1", "skill2", ...]
}
```

## Best Practices

### 1. Skill Organization

- Keep skills focused on a single capability
- Use descriptive names and clear descriptions
- Tag skills appropriately for discoverability

### 2. Scripts

- Make scripts executable (chmod +x)
- Include proper error handling
- Document script arguments in SKILL.md
- Use environment variables for arguments

### 3. Templates

- Use clear variable names
- Document all template variables in SKILL.md
- Support both `{{ var }}` and `{{{ var }}}` syntax

### 4. Versioning

- Update version numbers when modifying skills
- Document breaking changes
- Keep backward compatibility when possible

### 5. Security

- Be cautious with script execution
- Validate inputs in scripts
- Don't include sensitive data in SKILL.md
- Use environment variables or secure config for secrets

## Configuration

Skills are loaded from the directory specified by `GTD_SKILLS_DIR` environment variable, or defaults to `mcp/skills/`.

To change the skills directory:

```bash
export GTD_SKILLS_DIR="/path/to/your/skills"
```

## Troubleshooting

### Skills Not Loading

1. Check that `mcp/skills/` directory exists
2. Verify each skill folder has a `SKILL.md` file
3. Check for YAML syntax errors in frontmatter
4. Run `reload_agent_skills()` to refresh

### Script Execution Fails

1. Check script permissions (`chmod +x script.sh`)
2. Verify script path is correct (`scripts/script.sh`)
3. Check script syntax (run manually to test)
4. Review error messages in execution output

### Template Not Found

1. Verify template exists in `templates/` directory
2. Check template name matches exactly (case-sensitive)
3. Ensure template file is readable

## Integration with GTD System

Skills can leverage existing GTD system capabilities:

- Access GTD directories via environment variables
- Use vector database for context-aware skills
- Integrate with task suggestion system
- Call existing MCP tools from scripts

## Resources

- [Agent Skills Specification](https://agentskills.io/)
- [Agent Skills on GitHub](https://github.com/agentskills/agentskills)
- Example skills in `mcp/skills/example-skill/`

## Future Enhancements

- Skill dependency management
- Skill versioning and updates
- Remote skill repositories
- Skill marketplace/sharing
- Enhanced template engine
- Skill testing framework
