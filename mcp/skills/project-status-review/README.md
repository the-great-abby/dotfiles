# Project Status Review

## Directory Structure

```
project-status-review/
├── SKILL.md          # Main skill definition and instructions
├── scripts/          # Optional: Executable scripts
├── templates/        # Optional: Template files
└── resources/        # Optional: Supporting files
```

## Usage

Execute this skill via MCP:

```python
execute_agent_skill(
    skill_name="project-status-review",
    method="instructions"
)
```

## Development

Edit `SKILL.md` to update the skill instructions. The skill will be reloaded automatically on next use.
