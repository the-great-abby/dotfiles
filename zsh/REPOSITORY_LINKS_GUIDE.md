# Repository Links for Projects & Tasks

## 🎯 Overview

Projects and tasks can now be linked to GitHub/GitLab repositories. This makes it easy to track code-related work and quickly access repositories from your GTD system.

## ✨ Features

- ✅ Link projects to repositories
- ✅ Link tasks to repositories
- ✅ Support for GitHub URLs
- ✅ Support for GitLab URLs
- ✅ Shorthand notation (e.g., `user/repo` → `https://github.com/user/repo`)
- ✅ Repository links displayed in project/task listings
- ✅ Repository links shown when viewing projects/tasks

## 🔗 How to Add Repository Links

### Via Wizard

**Project Wizard:**
```
1. Run: gtd-wizard
2. Choose: 4) Manage projects
3. Choose: 1) Create a new project
4. Enter project name
5. Enter repository URL (or press Enter to skip)
```

**Task Wizard:**
```
1. Run: gtd-wizard
2. Choose: 3) Manage tasks
3. Choose: 1) Add a new task
4. Enter task description
5. Select project (optional)
6. Enter repository URL (or press Enter to skip)
```

### Via Command Line

**Projects:**
```bash
# Full URL
gtd-project create "my-project" --repository="https://github.com/user/repo"

# GitLab URL
gtd-project create "my-project" --repository="https://gitlab.com/user/repo"

# Shorthand (converts to GitHub)
gtd-project create "my-project" --repository="user/repo"
```

**Tasks:**
```bash
# With repository
gtd-task add "Fix bug in API" --repository="https://github.com/user/repo"

# With project and repository
gtd-task add "Fix bug in API" --project="my-project" --repository="user/repo"

# Shorthand
gtd-task add "Fix bug" --repository="user/repo"
```

### Via Interactive Creation

When creating projects or tasks interactively (not via wizard), you'll be prompted for repository links:

```bash
$ gtd-project create "my-project"
Project name: my-project
Repository URL (GitHub/GitLab, or press Enter to skip): user/repo
✓ Created project: my-project
  Location: ~/Documents/gtd/1-projects/my-project
```

## 📋 Repository URL Formats

### Supported Formats

1. **Full GitHub URL:**
   ```
   https://github.com/user/repo
   ```

2. **Full GitLab URL:**
   ```
   https://gitlab.com/user/repo
   https://gitlab.example.com/user/repo
   ```

3. **Shorthand (GitHub):**
   ```
   user/repo
   ```
   Automatically converts to: `https://github.com/user/repo`

### Examples

```bash
# GitHub full URL
--repository="https://github.com/microsoft/vscode"

# GitLab full URL
--repository="https://gitlab.com/gitlab-org/gitlab"

# Shorthand (GitHub)
--repository="microsoft/vscode"

# Custom GitLab instance
--repository="https://gitlab.example.com/team/project"
```

## 👀 Viewing Repository Links

### Project List
```bash
$ gtd-project list

📁 Projects (status: active)

[1] my-project
     Status: active | Created: 2024-01-01 | Tasks: 3
     Repository: https://github.com/user/my-project
     Path: ~/Documents/gtd/1-projects/my-project
```

### Task List
```bash
$ gtd-task list

📋 Tasks (status: active)

[1] Fix bug in API
     ID: 20241202120000-task
     Context: computer | Energy: high | Priority: urgent_important
     Project: my-project
     Repository: https://github.com/user/repo
```

### Viewing Projects/Tasks

When you view a project or task, the repository link is displayed:

```bash
$ gtd-project view my-project

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📁 Project: my-project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔗 Repository: https://github.com/user/my-project

# my-project

## Description
...
```

## 🔧 Updating Repository Links

You can update repository links by editing the project/task file directly, or using the frontmatter update functions:

```bash
# Update project repository
update_frontmatter_value "~/Documents/gtd/1-projects/my-project/README.md" "repository" "https://github.com/user/new-repo"
```

## 📝 Frontmatter Field

Repository links are stored in frontmatter:

**Projects:**
```yaml
---
type: project
status: active
created: 2024-01-01T12:00
project: my-project
repository: https://github.com/user/repo
tags: []
---
```

**Tasks:**
```yaml
---
type: task
status: active
created: 2024-01-01T12:00
context: computer
energy: high
priority: urgent_important
project: my-project
repository: https://github.com/user/repo
tags: []
---
```

## 💡 Use Cases

### Use Case 1: Development Projects
Link coding projects to their repositories for easy access:

```bash
gtd-project create "api-refactor" --repository="company/api-service"
```

### Use Case 2: Feature Tasks
Link specific tasks to PRs or issues:

```bash
gtd-task add "Review PR #123" --repository="https://github.com/user/repo"
```

### Use Case 3: Documentation Tasks
Link documentation tasks to wiki pages:

```bash
gtd-task add "Update README" --repository="user/docs"
```

## 🎯 Benefits

- **Quick Access**: See repository links directly in project/task lists
- **Context**: Know which repo a task/project relates to
- **Integration**: Easy to link GTD items to code work
- **Flexible**: Supports GitHub, GitLab, and custom instances
- **Convenient**: Shorthand notation for quick entry

## 📚 Related

- `gtd-project` - Project management commands
- `gtd-task` - Task management commands
- `gtd-wizard` - Interactive wizards with repository support

---

**Start linking your code work to your GTD system!** 🚀


