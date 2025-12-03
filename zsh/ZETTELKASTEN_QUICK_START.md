# Zettelkasten + GTD + Second Brain - Quick Start

## 🚀 Quick Start

### 1. Create Your First Atomic Note

```bash
# Quick capture to inbox
zet "My first atomic idea"
```

### 2. Link to Second Brain

```bash
# Create a Second Brain note
gtd-brain create "My Topic" Resources

# Link your atomic note to it
zet-link link ~/Documents/Second\ Brain/0-inbox/202501011200-my-first-atomic-idea.md \
  ~/Documents/Second\ Brain/Resources/my-topic.md
```

### 3. Create a GTD Project

```bash
# Create project
gtd-project create "My Project"

# Sync to Second Brain
gtd-brain-sync projects

# Link atomic note to project
zet-link gtd ~/Documents/Second\ Brain/Zettelkasten/202501011200-my-first-atomic-idea.md \
  ~/Documents/gtd/1-projects/my-project.md
```

## 📋 Common Workflows

### Learning a Topic

```bash
# 1. Create project
gtd-project create "Learn Kubernetes"
gtd-brain-sync projects

# 2. Create atomic notes
zet -z "Kubernetes Pods"
zet -z "Kubernetes Services"

# 3. Link to project
zet-link link <pod-note> Projects/learn-kubernetes.md
```

### Research & Ideas

```bash
# 1. Capture ideas
zet "Idea A"
zet "Idea B"

# 2. Create resource
gtd-brain create "Research Topic" Resources

# 3. Link ideas
zet-link link <idea-a> Resources/research-topic.md
```

### Quick Thought to Knowledge

```bash
# 1. Quick capture
zet "Interesting thought"

# 2. Develop the note (edit it)
# 3. Move to organized location
zet-link move <note-path> Resources
```

## 🔗 Key Commands

### Zettelkasten
- `zet <title>` - Create note in inbox
- `zet -z <title>` - Create in Zettelkasten directory
- `zet -r <title>` - Create in Resources
- `zet-link link <note> <target>` - Link notes
- `zet-link move <note> <category>` - Move to PARA

### Integration
- `gtd-brain-sync` - Sync GTD ↔ Second Brain
- `gtd-brain-discover connections` - Find connections
- `gtd-brain search <query>` - Search notes

## 📖 Full Documentation

See `ZETTELKASTEN_SECOND_BRAIN_INTEGRATION.md` for complete guide.



