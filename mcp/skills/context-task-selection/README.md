# Context-Based Task Selection

## Directory Structure

```
context-task-selection/
├── SKILL.md          # Main skill definition and instructions
├── scripts/          # Optional: Executable scripts
├── templates/        # Optional: Template files
└── resources/        # Optional: Supporting files
```

## Usage

Execute this skill via MCP:

```python
execute_agent_skill(
    skill_name="context-task-selection",
    method="instructions"
)
```

## Development

Edit `SKILL.md` to update the skill instructions. The skill will be reloaded automatically on next use.
