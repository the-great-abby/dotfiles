# Diagram & Mindmap Generation Guide

## 🎨 Overview

Your GTD system can now generate Mermaid.js diagrams and mindmaps using AI! This is perfect for visualizing your GTD system, project structures, relationships, processes, and ideas.

> **✨ New:** Diagram generation now uses the **deep analysis model** (GPT-OSS 20b) for better visual understanding and more accurate diagram syntax! See `DIAGRAM_DEEP_MODEL_INTEGRATION.md` for details.

> **🎯 Enhanced:** The diagram tool automatically gathers GTD data (projects, tasks, areas, etc.) when you create diagrams about your GTD system, making diagrams based on your actual data! See `DIAGRAM_MCP_DATA_INTEGRATION.md` for details.

---

## 🚀 Quick Start

### Create a Mindmap
```bash
gtd-diagram mindmap "GTD System Overview"
gtd-diagram mindmap "Wedding Planning"
gtd-diagram mindmap "SRE Career Path"
```

### Create a Flowchart
```bash
gtd-diagram flowchart "Daily Review Process"
gtd-diagram flowchart "Wedding Planning Workflow"
gtd-diagram flowchart "Incident Response Process"
```

### Create Other Diagram Types
```bash
gtd-diagram create sequence "Daily Log Review Process"
gtd-diagram create gantt "Wedding Planning Timeline"
gtd-diagram create state "Project Lifecycle"
```

---

## 📊 Supported Diagram Types

### 1. **Mindmap** (`mindmap`)
**Best for:**
- Brainstorming ideas
- Organizing thoughts
- Visualizing relationships
- Project structure
- Knowledge mapping

**Examples:**
```bash
gtd-diagram mindmap "GTD System Structure"
gtd-diagram mindmap "Second Brain Organization"
gtd-diagram mindmap "Wedding Planning Checklist"
```

### 2. **Flowchart** (`flowchart`)
**Best for:**
- Processes and workflows
- Decision trees
- Step-by-step procedures
- System flows

**Examples:**
```bash
gtd-diagram flowchart "Inbox Processing Workflow"
gtd-diagram flowchart "Weekly Review Process"
gtd-diagram flowchart "Incident Response Procedure"
```

### 3. **Sequence Diagram** (`sequence`)
**Best for:**
- Interactions between components
- Process sequences
- Communication flows
- System interactions

**Examples:**
```bash
gtd-diagram create sequence "GTD System Interactions"
gtd-diagram create sequence "Daily Log Review Process"
```

### 4. **Gantt Chart** (`gantt`)
**Best for:**
- Project timelines
- Scheduling
- Milestone tracking
- Wedding planning timeline

**Examples:**
```bash
gtd-diagram create gantt "Wedding Planning Timeline"
gtd-diagram create gantt "SRE Career Development Plan"
```

### 5. **State Diagram** (`state`)
**Best for:**
- State transitions
- Lifecycles
- Status flows
- Project states

**Examples:**
```bash
gtd-diagram create state "Project Lifecycle"
gtd-diagram create state "Task Status Flow"
```

### 6. **Entity-Relationship** (`er`)
**Best for:**
- Data relationships
- System architecture
- Database design
- GTD system structure

**Examples:**
```bash
gtd-diagram create er "GTD System Data Model"
gtd-diagram create er "Second Brain Structure"
```

### 7. **Class Diagram** (`class`)
**Best for:**
- System architecture
- Object relationships
- Code structure
- System design

### 8. **Journey Diagram** (`journey`)
**Best for:**
- User journeys
- Process experiences
- Workflow experiences

### 9. **Git Graph** (`gitgraph`)
**Best for:**
- Git workflows
- Branch strategies
- Development processes

### 10. **Pie Chart** (`pie`)
**Best for:**
- Data visualization
- Distribution
- Percentages

### 11. **Requirement Diagram** (`requirement`)
**Best for:**
- Requirements tracking
- Dependencies
- System requirements

---

## 💡 Common Use Cases

### 1. **Visualize Your GTD System**
```bash
gtd-diagram mindmap "My GTD System Structure"
gtd-diagram flowchart "GTD Workflow"
gtd-diagram create er "GTD Data Relationships"
```

### 2. **Wedding Planning**
```bash
gtd-diagram mindmap "Wedding Planning Checklist"
gtd-diagram flowchart "Wedding Planning Process"
gtd-diagram create gantt "Wedding Timeline"
```

### 3. **Project Planning**
```bash
gtd-diagram mindmap "Project: [Name]"
gtd-diagram flowchart "Project Workflow"
gtd-diagram create gantt "Project Timeline"
```

### 4. **SRE/Technical**
```bash
gtd-diagram flowchart "Incident Response Process"
gtd-diagram create sequence "System Architecture"
gtd-diagram create state "Service Lifecycle"
```

### 5. **Second Brain**
```bash
gtd-diagram mindmap "Second Brain Structure"
gtd-diagram create er "Note Relationships"
gtd-diagram flowchart "Knowledge Workflow"
```

### 6. **Career Planning**
```bash
gtd-diagram mindmap "SRE Career Path"
gtd-diagram flowchart "Career Development Process"
gtd-diagram create gantt "Career Goals Timeline"
```

---

## 🗺️ Integration with GTD System

### Save to Second Brain
```bash
# Create diagram
gtd-diagram mindmap "GTD System Overview"

# Save to Second Brain
gtd-diagram save gtd-system-overview.md
```

### Link to Projects
```bash
# Create project diagram
gtd-diagram flowchart "Wedding Planning Process"

# Link in project
gtd-project view "Plan Our Wedding"
# Add link to diagram
```

### Include in Notes
```bash
# Create diagram
gtd-diagram mindmap "Second Brain Structure"

# Copy diagram code to your notes
gtd-brain create "Second Brain Overview" Resources
# Paste diagram code
```

---

## 📝 Diagram Management

### List All Diagrams
```bash
gtd-diagram list
```

### View a Diagram
```bash
gtd-diagram view "gtd-system-overview"
```

### Edit Diagrams
Diagrams are saved as Markdown files with Mermaid code blocks. You can:
- Edit them directly
- View in Obsidian (renders automatically)
- View in any Mermaid-compatible viewer
- Share with others

---

## 🎯 Using AI Personas for Diagram Ideas

### Get Diagram Suggestions
```bash
# Ask personas for diagram ideas
gtd-advise tim "What diagrams would help me visualize my GTD system?"
gtd-advise david "What workflow diagrams would help my GTD process?"
gtd-advise esther "What relationship diagrams would help me understand my relationship with Louiza?"
```

### Generate Based on Advice
```bash
# Get advice, then create diagram
gtd-advise tim "How should I visualize my project structure?"
# Then create the diagram based on the advice
gtd-diagram mindmap "Project Structure"
```

---

## 💡 Pro Tips

### 1. **Start with Mindmaps**
- Great for brainstorming
- Easy to understand
- Good for organizing thoughts

### 2. **Use Flowcharts for Processes**
- Visualize workflows
- See decision points
- Understand steps

### 3. **Save to Second Brain**
- Keep diagrams with related notes
- View in Obsidian
- Link to projects/areas

### 4. **Iterate and Refine**
- Create initial diagram
- Review and refine
- Update as needed

### 5. **Combine with Projects**
- Create diagrams for major projects
- Visualize project structure
- Track project relationships

### 6. **Use for Planning**
- Visualize wedding planning
- Map out career paths
- Plan major initiatives

---

## 🚀 Quick Examples

### Example 1: GTD System Mindmap
```bash
gtd-diagram mindmap "My Complete GTD System"
```

### Example 2: Wedding Planning Flowchart
```bash
gtd-diagram flowchart "Wedding Planning Process from Start to Finish"
```

### Example 3: Daily Review Sequence
```bash
gtd-diagram create sequence "Daily Review Process with All Personas"
```

### Example 4: Career Path Gantt
```bash
gtd-diagram create gantt "SRE Career Development Timeline"
```

---

## 📚 Where Diagrams Are Saved

### Local Storage
- **Location:** `~/Documents/gtd/diagrams/`
- **Format:** Markdown files with Mermaid code blocks
- **Naming:** Based on description (sanitized)

### Second Brain Integration
- **Save to:** `Second Brain/Resources/`
- **View in:** Obsidian (auto-renders Mermaid)
- **Link from:** Projects, areas, notes

---

## 🎨 Viewing Diagrams

### In Obsidian
1. Open the diagram file
2. Mermaid diagrams render automatically
3. Edit and refine as needed

### Online Viewers
- Mermaid Live Editor: https://mermaid.live
- Copy diagram code and paste

### VS Code
- Install Mermaid extension
- Preview diagrams in editor

---

## 🔗 Integration Examples

### With Projects
```bash
# Create project
gtd-project create "Website Redesign" --area="Work & Career"

# Create diagram
gtd-diagram flowchart "Website Redesign Process"

# Link in project notes
gtd-project view "Website Redesign"
# Add: [[diagrams/website-redesign-process]]
```

### With Second Brain
```bash
# Create diagram
gtd-diagram mindmap "Second Brain Structure"

# Save to Second Brain
gtd-diagram save second-brain-structure.md

# Link from MOC
gtd-brain-moc add "Second Brain Overview" "second-brain-structure"
```

### With Daily Logs
```bash
# Create diagram
gtd-diagram flowchart "My Daily Routine"

# Reference in daily log
addInfoToDailyLog "Created daily routine diagram (Personal Development)"
```

---

## 🎯 Your Diagram System is Ready!

You can now:
- ✅ Generate mindmaps for any topic
- ✅ Create flowcharts for processes
- ✅ Visualize your GTD system
- ✅ Plan projects visually
- ✅ Save to Second Brain
- ✅ View in Obsidian

Start visualizing! 🎨✨


