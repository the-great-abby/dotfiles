# Smart Selection System - Partial Names & Numbers

## 🎯 Overview

The GTD system now supports **smart selection** that allows you to:
- Use **numbers** to select from numbered lists
- Use **partial names** for fuzzy matching (e.g., "exam" matches "cka-exam-preparation")
- Avoid typing full names manually

## 📋 How It Works

When you're asked to select an item (project, area, note, etc.), you'll see a numbered list:

```
Available projects:
  1) cka-exam-preparation
  2) website-redesign
  3) home-organization
  4) learning-kubernetes

Select project (number or partial name):
```

You can then:
- Type `1` to select the first project
- Type `exam` to match "cka-exam-preparation"
- Type `web` to match "website-redesign"
- Type the full name if you prefer

## 🔧 Using in Scripts

### Helper Function

A reusable helper function is available at:
```
~/code/dotfiles/bin/gtd-select-helper.sh
```

### Example Usage

**In a script:**

```bash
#!/bin/bash
# Source the helper
source "$HOME/code/dotfiles/bin/gtd-select-helper.sh"

# Select a project
PROJECTS_PATH="$HOME/Documents/gtd/1-projects"
selected_project=$(select_from_list "project" "$PROJECTS_PATH" "project")

if [[ -n "$selected_project" ]]; then
  echo "You selected: $selected_project"
  # Use the selected project
else
  echo "Selection cancelled"
fi
```

**For areas:**

```bash
AREAS_PATH="$HOME/Documents/gtd/2-areas"
selected_area=$(select_from_list "area" "$AREAS_PATH" "name")

if [[ -n "$selected_area" ]]; then
  echo "Selected area: $selected_area"
fi
```

**For notes:**

```bash
NOTES_PATH="$HOME/Documents/obsidian/Second Brain/Zettelkasten"
selected_note=$(select_from_list "note" "$NOTES_PATH" "name")

if [[ -n "$selected_note" ]]; then
  echo "Selected note: $selected_note"
fi
```

## 🚀 Where It's Used

The smart selection system is being integrated into:

1. **MOC Wizard** - Select MOCs by number or partial name
2. **Project Selection** - When linking items to projects
3. **Area Selection** - When assigning items to areas
4. **Zettelkasten Wizard** - When selecting notes to link/move
5. **Task Processing** - When associating tasks with projects

## 💡 Benefits

- **Faster**: Type a few characters instead of full names
- **Less error-prone**: No typos, just partial matches
- **Flexible**: Use numbers when you know the position
- **User-friendly**: Shows all available options clearly

## 🔄 Migration

Existing workflows still work! If you type a full name, it will match. The new system just adds convenience:
- Old way: Type full name → Still works!
- New way: Type number or partial name → Faster!

## 📝 Examples

### Example 1: Selecting a Project

**Before:**
```
Project name: cka-exam-preparation
```

**Now:**
```
Available projects:
  1) cka-exam-preparation
  2) website-redesign
  3) home-organization

Select project (number or partial name): exam
✓ Selected: cka-exam-preparation
```

### Example 2: Multiple Matches

If you type something that matches multiple items:

```
Select area (number or partial name): health

Multiple matches found:
  1) Health & Wellness
  2) Mental Health

Select area (number): 1
✓ Selected: Health & Wellness
```

### Example 3: Using Numbers

```
Select project (number or partial name): 3
✓ Selected: home-organization
```

## 🛠️ Technical Details

The selection function:
- Shows numbered lists for all items
- Supports case-insensitive partial matching
- Handles multiple matches gracefully
- Falls back to exact name matching
- Returns empty string if cancelled

## 📚 Integration Points

To add smart selection to a new wizard:

1. Source the helper:
   ```bash
   source "$HOME/code/dotfiles/bin/gtd-select-helper.sh"
   ```

2. Use it instead of `read -p`:
   ```bash
   # Old way
   read -p "Project name: " project_name
   
   # New way
   selected=$(select_from_list "project" "$PROJECTS_PATH" "project")
   ```

3. Handle the result:
   ```bash
   if [[ -n "$selected" ]]; then
     # Use selected item
   else
     echo "Selection cancelled"
   fi
   ```

## ✨ Coming Soon

The smart selection system is being rolled out across all wizards and scripts. Places where it will be added:

- ✅ Helper function created
- 🔄 MOC wizard
- 🔄 Project selection in gtd-process
- 🔄 Area selection in gtd-area
- 🔄 Note selection in Zettelkasten wizard
- 🔄 Habit selection (already uses numbers!)
- 🔄 Task selection

Check this guide for updates as more places are enhanced!




