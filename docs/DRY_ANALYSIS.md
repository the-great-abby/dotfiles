# DRY Analysis - Code Duplication Opportunities

This document identifies repeated code patterns that should be refactored into common helper functions.

## 1. Path Initialization (HIGH PRIORITY)

### Current Duplication
Multiple scripts manually set GTD paths:
```bash
GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
PROJECTS_PATH="${GTD_BASE_DIR}/${GTD_PROJECTS_DIR:-1-projects}"
TASKS_PATH="${GTD_BASE_DIR}/${GTD_TASKS_DIR:-3-tasks}"
AREAS_PATH="${GTD_BASE_DIR}/${GTD_AREAS_DIR:-2-areas}"
GOALS_DIR="${GTD_BASE_DIR}/${GTD_GOALS_DIR:-goals}"
```

**Found in:**
- `bin/gtd-plan` (lines 110-112, 286-288)
- `bin/gtd-wizard-org.sh` (lines 8-10, 1154-1156, 2752-2755)
- `bin/gtd-project` (line 17)
- And more...

### ✅ Solution
**Already exists:** `init_gtd_paths` in `gtd-common.sh` - but not consistently used!

**Action:** Ensure all scripts source `gtd-common.sh` and use `init_gtd_paths` instead of manual path setup.

---

## 2. Finding Task Files (HIGH PRIORITY)

### Current Duplication
Repeated pattern to find a task by ID:
```bash
task_file=$(find "$TASKS_PATH" -name "${task_id}*.md" 2>/dev/null | head -1)
if [[ -z "$task_file" ]]; then
  task_file=$(find "$PROJECTS_PATH" -name "${task_id}*.md" ! -name "README.md" 2>/dev/null | head -1)
fi
```

**Found in:**
- `bin/gtd-wizard` (lines 615-619)
- `bin/gtd-wizard-org.sh` (lines 722-725, 2040-2043, 2829-2832)
- `bin/gtd-task` (likely)

### ✅ Solution
**Already exists:** `find_task_file()` in `gtd-task` script!

**Action:** Extract `find_task_file` to `gtd-common.sh` so all scripts can use it.

---

## 3. Reading Frontmatter Values (HIGH PRIORITY)

### Current Duplication
Repeated pattern to extract frontmatter values:
```bash
name=$(grep "^name:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
status=$(grep "^status:" "$file" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
```

**Found in:**
- `bin/gtd-plan` (lines 143, 147, 309, 311)
- `bin/gtd-wizard-org.sh` (line 16, 1581-1583, 2784, 2808-2810, 2854)
- `bin/gtd-select-helper.sh` (lines 65, 67, 77, 83)

### ✅ Solution
**Already exists:** `gtd_get_frontmatter_value()` in `gtd-common.sh`!

**Action:** Replace all manual `grep | cut | sed` patterns with `gtd_get_frontmatter_value "$file" "name"`.

---

## 4. Project Name Extraction (MEDIUM PRIORITY)

### Current Duplication
Repeated pattern to get project name (check `project:` then `name:`):
```bash
proj_name=$(grep "^project:" "$readme" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
if [[ -z "$proj_name" ]]; then
  proj_name=$(grep "^name:" "$readme" 2>/dev/null | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
fi
if [[ -z "$proj_name" ]]; then
  proj_name=$(basename "$(dirname "$readme")")
fi
```

**Found in:**
- `bin/gtd-plan` (lines 309-311)
- `bin/gtd-wizard-org.sh` (lines 1581-1583, 2808-2810)
- `bin/gtd-select-helper.sh` (lines 65-71)

### ✅ Solution
**Create helper:** `get_project_name()` in `gtd-common.sh`:
```bash
get_project_name() {
  local readme_file="$1"
  local name=$(gtd_get_frontmatter_value "$readme_file" "project")
  [[ -z "$name" ]] && name=$(gtd_get_frontmatter_value "$readme_file" "name")
  [[ -z "$name" ]] && name=$(basename "$(dirname "$readme_file")")
  echo "$name"
}
```

---

## 5. Checking Directory Has Files (MEDIUM PRIORITY)

### Current Duplication
Repeated pattern to check if directory has markdown files:
```bash
if [[ -d "$AREAS_PATH" ]] && [[ -n "$(find "$AREAS_PATH" -type f -name "*.md" 2>/dev/null)" ]]; then
```

**Found in:**
- `bin/gtd-wizard-org.sh` (lines 736, 1034, 1045, 1060, 1077, 1095, 1380, 1468)

### ✅ Solution
**Create helper:** `directory_has_files()` in `gtd-common.sh`:
```bash
directory_has_files() {
  local dir="$1"
  local pattern="${2:-*.md}"
  [[ -d "$dir" ]] && [[ -n "$(find "$dir" -type f -name "$pattern" 2>/dev/null | head -1)" ]]
}
```

---

## 6. Task ID by Number Parsing (LOW PRIORITY - Already Standardized)

### Current Status
✅ **Already standardized:** `get_task_id_by_number()` in `gtd-wizard`

**Action:** Ensure all scripts use this function (already done in `gtd-plan`).

---

## 7. Display Name Extraction (LOW PRIORITY - Partially Standardized)

### Current Status
✅ **Partially standardized:** `get_display_name()` in `gtd-select-helper.sh` (internal function)

**Action:** Consider extracting to `gtd-common.sh` if needed elsewhere, but current usage is fine.

---

## 8. User Input Patterns (LOW PRIORITY)

### Current Duplication
Many scripts have similar input patterns:
```bash
echo -n "Choose: "
read choice
case "$choice" in
  1) ... ;;
  2) ... ;;
esac
```

**Note:** This is acceptable duplication - each menu is context-specific. No action needed.

---

## Recommended Refactoring Priority

### Phase 1: High Impact, Low Risk
1. ✅ **Use `gtd_get_frontmatter_value` everywhere** - Replace all `grep | cut | sed` patterns
2. ✅ **Use `init_gtd_paths` everywhere** - Remove manual path initialization
3. ✅ **Extract `find_task_file` to `gtd-common.sh`** - Make it available to all scripts

### Phase 2: Medium Impact
4. ✅ **Create `get_project_name()` helper** - Standardize project name extraction
5. ✅ **Create `directory_has_files()` helper** - Simplify directory checks

### Phase 3: Code Review
6. Review all scripts to ensure they source `gtd-common.sh`
7. Add unit tests for new helper functions
8. Update DRY principle rule with new helpers

---

## Files to Update

### High Priority
- `bin/gtd-plan` - Use `gtd_get_frontmatter_value`, `init_gtd_paths`
- `bin/gtd-wizard-org.sh` - Use `gtd_get_frontmatter_value`, `find_task_file`, `directory_has_files`
- `bin/gtd-select-helper.sh` - Use `gtd_get_frontmatter_value` instead of manual parsing

### Medium Priority
- `bin/gtd-project` - Ensure uses `init_gtd_paths`
- Any other scripts with manual path initialization

---

## New Helper Functions to Add

### To `gtd-common.sh`:

```bash
# Get project name from README (checks project:, name:, then directory name)
get_project_name() {
  local readme_file="$1"
  [[ -z "$readme_file" || ! -f "$readme_file" ]] && return 1
  
  local name=$(gtd_get_frontmatter_value "$readme_file" "project")
  [[ -z "$name" ]] && name=$(gtd_get_frontmatter_value "$readme_file" "name")
  [[ -z "$name" ]] && name=$(basename "$(dirname "$readme_file")")
  echo "$name"
}

# Check if directory has files matching pattern
directory_has_files() {
  local dir="$1"
  local pattern="${2:-*.md}"
  [[ -d "$dir" ]] && [[ -n "$(find "$dir" -type f -name "$pattern" 2>/dev/null | head -1)" ]]
}

# Find task file by ID (searches TASKS_PATH and PROJECTS_PATH)
find_task_file() {
  local task_id="$1"
  [[ -z "$task_id" ]] && return 1
  
  # Search in tasks directory
  local task_file=$(find "$TASKS_PATH" -name "${task_id}*.md" 2>/dev/null | head -1)
  
  # If not found, search in project directories
  if [[ -z "$task_file" ]] && [[ -d "$PROJECTS_PATH" ]]; then
    task_file=$(find "$PROJECTS_PATH" -name "${task_id}*.md" ! -name "README.md" 2>/dev/null | head -1)
  fi
  
  if [[ -n "$task_file" && -f "$task_file" ]]; then
    echo "$task_file"
    return 0
  fi
  
  return 1
}
```

---

## Testing Checklist

After refactoring:
- [ ] All scripts still work correctly
- [ ] Unit tests pass
- [ ] No regressions in wizard functionality
- [ ] Path initialization is consistent
- [ ] Frontmatter reading is consistent
- [ ] Task file finding works in all contexts
