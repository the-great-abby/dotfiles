# Wizard Review Guide Enhancement

## Overview

Enhanced the GTD Wizard to provide review process guides and reminders, making it easy to know what to do during each type of review.

## What Was Added

### 1. Quick Reference Guide at Top of Review Wizard

When you enter the Review Wizard (option 6), you now see a **quick reference guide** at the top showing:

- **Daily Review** (5-10 min): Morning/evening process overview
- **Weekly Review** (1-2 hours): Key tasks overview
- **Monthly Review** (2-3 hours): Main activities overview
- **Quarterly Review** (3-4 hours): Strategic activities overview
- **Yearly Review** (4-6 hours): Annual activities overview
- **Financial Review**: Options overview

This appears **automatically** every time you enter the review wizard, so you're always reminded of what each review involves.

### 2. Detailed Guide Viewer

Added option **7** to view detailed guides for any review type:

```
7) 📖 View detailed guide for a review type
```

This opens the full guide document for the review type you select, showing:
- Complete step-by-step process
- Time commitments
- Questions to ask
- Commands to run
- Best practices

### 3. Pre-Review Guide Option

When you select a review type (1-5), you're now asked if you want to view the guide first:

```
Would you like to view the Daily Review guide before starting? (y/n)
```

This lets you quickly refresh your memory on what to do before starting the review.

## How to Use

### Access Review Wizard

```bash
make gtd-wizard
# Then choose: 6) 📊 Review (daily/weekly)
```

Or directly:

```bash
gtd-wizard
# Then choose: 6
```

### What You'll See

1. **Quick Reference Guide** (shown automatically):
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   📋 Quick Reference: Review Process Guides
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   1) Daily Review (5-10 min)
      • Morning: Set priorities, plan day, check system
      • Evening: Reflect on accomplishments, plan tomorrow
      • Auto-detects time of day for appropriate questions
   
   2) Weekly Review (1-2 hours)
      • Process inbox to zero
      • Review calendar (past & upcoming week)
      • Review waiting-for items
      • Review all active projects & tasks
      • Review someday/maybe list
   
   ... (and more)
   ```

2. **Menu Options**:
   - Options 1-6: Start each review type
   - Option 7: View detailed guides

3. **When Starting a Review**:
   - Option to view guide first
   - Then the review process begins

## Benefits

1. **Always Know What To Do**: Quick reference guide shows up automatically
2. **No Need to Remember**: You don't have to remember what each review involves
3. **Quick Refresh**: Option to view guide before starting keeps you on track
4. **Detailed Reference**: Full guides available when you need more detail
5. **Better Reviews**: Reminders help ensure you don't skip important steps

## Example Flow

```
$ make gtd-wizard
Choose: 6

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Quick Reference: Review Process Guides
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Shows overview of all review types...]

What type of review would you like to do?

  1) Daily review
  2) Weekly review
  ...
  7) 📖 View detailed guide for a review type

Choose: 2

Would you like to view the Weekly Review guide before starting? (y/n)
   y

[Shows full weekly review guide]

[Then starts the weekly review process]
```

## Guide Files Referenced

The wizard references these guide files:
- `zsh/DAILY_REVIEW_TIMING_GUIDE.md`
- `zsh/WEEKLY_REVIEW_TASKS_GUIDE.md`
- `zsh/MONTHLY_REVIEW_TASKS_GUIDE.md`
- `zsh/QUARTERLY_REVIEW_TASKS_GUIDE.md`
- `zsh/YEARLY_REVIEW_TASKS_GUIDE.md`
- `zsh/FINANCIAL_REVIEW_GUIDE.md`

These files are automatically found in:
- `~/code/dotfiles/zsh/`
- `~/code/personal/dotfiles/zsh/` (fallback)

## Tips

1. **Use Quick Reference**: The guide at the top is there to help - read it!
2. **View Guide First**: When doing a review you haven't done in a while, say "y" to view the guide
3. **Option 7**: Use option 7 to browse all available guides
4. **Review Regularly**: The guides help ensure you do complete, thorough reviews

## Technical Details

### Functions Added

- `show_review_guide()`: Displays quick reference at top
- `show_detailed_review_guide()`: Menu-driven detailed guide viewer
- `show_specific_review_guide(type)`: Shows guide for specific review type

### Integration Points

- Review wizard automatically shows quick reference
- Each review option offers guide viewing
- Detailed guide viewer available as option 7
- All guide files are automatically located and displayed

