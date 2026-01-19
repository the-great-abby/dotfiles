#!/bin/bash
# Agent Skill Creation Helper
# Interactive script to create new Agent Skills following best practices

set -e

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

# Ensure skills directory exists
mkdir -p "$SKILLS_DIR"

echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${CYAN}✨ Agent Skill Creation Helper${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Step 1: Get skill name
echo -e "${BOLD}Skill Name:${NC}"
echo -e "  This will be the folder name (lowercase, hyphens, no spaces)"
echo -e "  Example: morning-checkin, inbox-processing, daily-review"
echo -n "Enter skill name: "
read skill_name

# Validate skill name
if [[ -z "$skill_name" ]]; then
  echo -e "${YELLOW}Error: Skill name cannot be empty${NC}"
  exit 1
fi

# Sanitize skill name (lowercase, replace spaces with hyphens)
skill_name=$(echo "$skill_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

# Check if skill already exists
skill_dir="${SKILLS_DIR}/${skill_name}"
if [[ -d "$skill_dir" ]]; then
  echo -e "${YELLOW}Warning: Skill '${skill_name}' already exists${NC}"
  read -p "Overwrite? (y/n): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
fi

# Step 2: Get skill metadata
echo ""
echo -e "${BOLD}Skill Metadata:${NC}"
echo ""

echo -n "Display Name (e.g., 'Morning Check-In'): "
read display_name
display_name="${display_name:-$skill_name}"

echo -n "Description (brief, one line): "
read description
description="${description:-No description provided}"

echo -n "Version (default: 1.0.0): "
read version
version="${version:-1.0.0}"

echo -n "Tags (comma-separated, e.g., 'routine,productivity,daily'): "
read tags_input
tags=$(echo "$tags_input" | sed 's/, */\n  - /g' | sed 's/^/  - /' | head -1 | sed 's/^  - //')

echo -n "Author (default: GTD System): "
read author
author="${author:-GTD System}"

# Step 3: Get workflow details
echo ""
echo -e "${BOLD}Workflow Details:${NC}"
echo ""

echo -n "When to use this skill? (brief description): "
read when_to_use
when_to_use="${when_to_use:-Use this skill when appropriate}"

echo -n "How does it work? (brief description): "
read how_it_works
how_it_works="${how_it_works:-This skill provides guidance and workflows}"

# Step 4: MCP Tools used
echo ""
echo -e "${BOLD}MCP Tools Used:${NC}"
echo -e "  List the MCP tools this skill will use (comma-separated)"
echo -e "  Examples: read_daily_log, create_task, suggest_tasks_from_text"
echo -n "MCP tools: "
read mcp_tools_input

# Step 5: Create skill structure
echo ""
echo -e "${GREEN}Creating skill structure...${NC}"
mkdir -p "$skill_dir"

# Create SKILL.md with template
cat > "${skill_dir}/SKILL.md" <<EOF
---
name: ${display_name}
description: ${description}
version: ${version}
tags:
EOF

# Add tags
if [[ -n "$tags_input" ]]; then
  IFS=',' read -ra TAG_ARRAY <<< "$tags_input"
  for tag in "${TAG_ARRAY[@]}"; do
    tag=$(echo "$tag" | xargs)  # Trim whitespace
    echo "  - ${tag}" >> "${skill_dir}/SKILL.md"
  done
else
  echo "  - workflow" >> "${skill_dir}/SKILL.md"
fi

cat >> "${skill_dir}/SKILL.md" <<EOF
author: ${author}
---

# ${display_name}

${description}

## When to Use

${when_to_use}

## How It Works

${how_it_works}

This workflow uses MCP tools to provide structured guidance and automate tasks.

### MCP Tools Used

EOF

# Add MCP tools list
if [[ -n "$mcp_tools_input" ]]; then
  IFS=',' read -ra TOOL_ARRAY <<< "$mcp_tools_input"
  for tool in "${TOOL_ARRAY[@]}"; do
    tool=$(echo "$tool" | xargs)  # Trim whitespace
    echo "- \`${tool}\`: [Describe what this tool does]" >> "${skill_dir}/SKILL.md"
  done
else
  echo "- [List MCP tools used by this skill]" >> "${skill_dir}/SKILL.md"
fi

cat >> "${skill_dir}/SKILL.md" <<EOF

## Workflow Steps

### Step 1: [First Step]

**Purpose:** [Why this step is important]

**Actions:**
1. [Action to take]
2. [Another action]
3. [Use MCP tools as needed]

---

### Step 2: [Second Step]

**Purpose:** [Why this step is important]

**Actions:**
1. [Action to take]
2. [Use MCP tools]

---

[Add more steps as needed]

## Best Practices

- [Practice 1]
- [Practice 2]
- [Practice 3]

## Integration with Other Skills

This skill works well with:
- **\`[related-skill]\`**: [How they work together]

## Troubleshooting

### "[Common Issue]"

[Solution or guidance]

## Success Criteria

A successful execution means:
- ✓ [Criterion 1]
- ✓ [Criterion 2]
- ✓ [Criterion 3]
EOF

# Create optional directories
mkdir -p "${skill_dir}/scripts"
mkdir -p "${skill_dir}/templates"
mkdir -p "${skill_dir}/resources"

# Create README for directory structure
cat > "${skill_dir}/README.md" <<EOF
# ${display_name}

## Directory Structure

\`\`\`
${skill_name}/
├── SKILL.md          # Main skill definition and instructions
├── scripts/          # Optional: Executable scripts
├── templates/        # Optional: Template files
└── resources/        # Optional: Supporting files
\`\`\`

## Usage

Execute this skill via MCP:

\`\`\`python
execute_agent_skill(
    skill_name="${skill_name}",
    method="instructions"
)
\`\`\`

## Development

Edit \`SKILL.md\` to update the skill instructions. The skill will be reloaded automatically on next use.
EOF

echo ""
echo -e "${GREEN}✓ Skill created successfully!${NC}"
echo ""
echo -e "${BOLD}Skill location:${NC} ${skill_dir}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Edit ${skill_dir}/SKILL.md to add detailed workflow steps"
echo "  2. Add scripts, templates, or resources as needed"
echo "  3. Test with: python3 -c \"from gtd_skills import get_registry; r = get_registry(); r.reload_skills(); print('Reloaded:', [s['id'] for s in r.list_skills()])\""
echo "  4. Use in wizard or via MCP: execute_agent_skill(skill_name=\"${skill_name}\")"
echo ""

# Offer to open in editor
read -p "Open SKILL.md in editor? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  ${EDITOR:-nano} "${skill_dir}/SKILL.md"
fi
