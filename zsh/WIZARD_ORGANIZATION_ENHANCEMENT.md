# Wizard Organization Enhancement

## Overview

Enhanced the GTD Wizard with better organization and comprehensive guides showing different organization techniques and tips.

## What Was Added

### 1. Organization Techniques Guide at Top

When you start the wizard, you now see **organization techniques guide** showing:

- **GTD (Getting Things Done)**: Core workflow and principles
- **PARA Method**: Projects, Areas, Resources, Archives structure
- **Second Brain (CODE)**: Capture, Organize, Distill, Express
- **Zettelkasten**: Atomic notes and knowledge graphs
- **Maps of Content (MOCs)**: Topic-based organization

This appears **before** the process reminders, giving you a quick reference to all the organization methods used in your system.

### 2. Reorganized Menu into Logical Groups

The wizard menu is now organized into clear categories:

#### 📥 INPUTS - Capture & Process
- Capture to inbox
- Process inbox items
- Log to daily log
- Morning/Evening Check-In

#### 🗂️ ORGANIZATION - Manage Your System
- Manage tasks
- Manage projects
- Manage areas of responsibility
- Manage MOCs
- Zettelkasten (atomic notes)

#### 📤 OUTPUTS - Reviews & Creation
- Review (daily/weekly/monthly)
- Sync with Second Brain
- Express Phase (create content)
- Use Templates
- Create diagrams & mindmaps

#### 📚 LEARNING - Guides & Discovery
- Learn Organization System
- Learn Second Brain
- Discover Life Vision
- Learn Kubernetes/CKA
- Learn Greek (Language)

#### 🔍 ANALYSIS - Insights & Tracking
- Search GTD system
- System status
- Goal Tracking & Progress
- Energy Audit

#### 🛠️ TOOLS & SUPPORT
- Get advice from personas
- Manage habits & recurring tasks
- AI Suggestions & MCP Tools

#### ⚙️ SETTINGS
- Configuration & Setup
- Gamification & Habitica

## Benefits

1. **Better Organization**: Menu items grouped by function (inputs/outputs/learning)
2. **Quick Reference**: Organization techniques visible at top for quick recall
3. **Clearer Navigation**: Easier to find what you're looking for
4. **Educational**: Learn about different organization methods while using the system
5. **Comprehensive**: All major organization techniques (GTD, PARA, CODE, Zettelkasten) shown

## How It Works

### Organization Techniques Guide

Shows at the top of the wizard:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Organization Techniques & Quick Guides
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎯 GTD (Getting Things Done):
  • Capture → Process → Organize → Review → Do
  • 5 Horizons: Runway → 10k → 20k → 30k → 40k
  • 2-Minute Rule: Do it now if < 2 minutes
  • Weekly Review: Critical for system health

📁 PARA Method:
  • Projects: Multi-step outcomes with deadlines
  • Areas: Ongoing responsibilities to maintain
  • Resources: Topics of ongoing interest
  • Archives: Inactive items from other categories

🧠 Second Brain (CODE):
  • Capture: Keep what resonates
  • Organize: Save by actionability (PARA)
  • Distill: Progressive summarization (3 levels)
  • Express: Create content from notes

🔗 Zettelkasten:
  • Atomic Notes: One idea per note
  • Permanent Notes: Core insights
  • Literature Notes: From external sources
  • Link Everything: Build knowledge graph

🗺️  Maps of Content (MOCs):
  • Organize notes by topic/theme
  • Dynamic indexes that evolve
  • Create when you have 3+ related notes
```

### Grouped Menu Display

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 GTD Interactive Wizard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Organization Techniques Guide]
[Process Reminders Guide]

What would you like to do?

📥 INPUTS - Capture & Process:
  1) 📥 Capture something to inbox
  2) 📋 Process inbox items
  15) 📝 Log to daily log
  19) 🌅 Morning/Evening Check-In

🗂️  ORGANIZATION - Manage Your System:
  3) ✅ Manage tasks
  4) 📁 Manage projects
  5) 🎯 Manage areas of responsibility
  8) 🗺️  Manage MOCs (Maps of Content)
  23) 🔗 Zettelkasten (atomic notes)

📤 OUTPUTS - Reviews & Creation:
  6) 📊 Review (daily/weekly/monthly)
  7) 🧠 Sync with Second Brain
  9) ✍️  Express Phase (create content from notes)
  10) 📋 Use Templates
  22) 🎨 Create diagrams & mindmaps

[And more groups...]
```

## Technical Details

### Functions Added

- `show_organization_guide()`: Displays organization techniques at top
  - Shows GTD principles
  - Shows PARA method structure
  - Shows Second Brain CODE method
  - Shows Zettelkasten concepts
  - Shows MOCs guidance

### Menu Organization

- Menu items organized into 7 logical groups
- Group headers use color coding for visibility
- Original menu numbers preserved (backward compatible)
- Same functionality, better organization

### Integration Points

- Organization guide shows before process reminders
- Process reminders show after organization guide
- Both guides appear at top of main menu
- Menu items grouped by function below guides

## Tips

1. **Read the Guides**: Take a moment to review organization techniques
2. **Use Groups**: Navigate by category (inputs/outputs/learning)
3. **Quick Reference**: Guides help remember methodology while working
4. **Comprehensive View**: See all organization methods at a glance

## Future Enhancements

Potential additions:
- Expandable guides (show/hide)
- Links to detailed guides for each method
- Interactive examples
- Quick tips specific to current context

