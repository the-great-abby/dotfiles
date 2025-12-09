# Automatic Insight Detection from Daily Logs

## 🎯 Overview

The system automatically scans your daily log entries and detects "evergreen" insights - ideas, learnings, or realizations that have lasting value. These are automatically converted into draft notes in your Second Brain for review.

## ✨ How It Works

1. **Automatic Scanning**: During morning check-in, the system scans your recent daily logs (default: last 7 days)
2. **AI Detection**: Uses AI to identify evergreen insights - principles, patterns, learnings, or realizations
3. **Draft Creation**: Creates draft notes in `Second Brain/Express/drafts/` for review
4. **Morning Review**: Prompts you during morning check-in to review the drafts

## 🚀 Usage

### Automatic (Recommended)

The system runs automatically during morning check-in:

```bash
gtd-checkin morning
```

If drafts are found, you'll see:
```
📝 Draft Notes for Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I created 2 draft note(s) from your recent daily logs.

These are evergreen insights I detected - review them?

Review drafts now? (y/N):
```

### Manual Scanning

Scan your logs manually:

```bash
# Scan last 7 days (default)
gtd-scan-insights scan

# Scan last 3 days
gtd-scan-insights scan 3

# List all drafts
gtd-scan-insights list
```

### Review Drafts

Review and process drafts:

```bash
# Interactive review
gtd-review-drafts

# Just list drafts
gtd-review-drafts list

# Show summary (for morning check-in)
gtd-review-drafts summary
```

## 📝 Review Actions

When reviewing drafts, you can:

- **[a] Accept** - Convert to zettelkasten note (promotes to permanent knowledge)
- **[e] Edit** - Open in editor to refine before accepting
- **[r] Reject** - Delete this draft (not valuable)
- **[s] Skip** - Leave for later review
- **[q] Quit** - Exit review

## ⚙️ Configuration

Edit `~/.gtd_config_ai` or `~/code/dotfiles/zsh/.gtd_config_ai`:

```bash
# Enable/disable insight scanning
GTD_INSIGHT_SCANNING_ENABLED="true"

# Days to scan back (default: 7)
GTD_INSIGHT_SCAN_DAYS="7"

# Minimum confidence threshold (0.0-1.0, default: 0.7)
GTD_INSIGHT_MIN_CONFIDENCE="0.7"

# Persona for insight detection (default: skippy)
GTD_INSIGHT_PERSONA="skippy"

# Auto-scan on morning check-in (default: true)
GTD_INSIGHT_AUTO_SCAN="true"
```

## 📋 What Gets Detected

An "evergreen insight" is:
- ✅ A principle, pattern, or lesson learned
- ✅ A realization about how something works
- ✅ A connection between ideas
- ✅ Something valuable to reference later
- ❌ NOT just a task completion
- ❌ NOT routine activities
- ❌ NOT temporary information

## 📁 File Locations

- **Drafts**: `~/Documents/obsidian/Second Brain/Express/drafts/`
- **Zettelkasten Notes**: `~/Documents/obsidian/Second Brain/Zettelkasten/`
- **Daily Logs**: `~/Documents/daily_logs/`

## 🔄 Workflow

1. **Daily**: Write entries in your daily log
2. **Morning**: System scans logs and creates drafts
3. **Review**: Review drafts during morning check-in
4. **Accept**: Convert valuable insights to zettelkasten notes
5. **Reject**: Delete drafts that aren't valuable

## 💡 Example

**Daily Log Entry:**
```
14:30 - Realized that breaking work into 25-minute pomodoros helps me focus better than trying to work for hours straight. The forced breaks prevent burnout.
```

**Detected Insight:**
- **Title**: "Pomodoro Technique Prevents Burnout"
- **Insight**: Breaking work into 25-minute focused sessions with breaks prevents burnout and improves focus compared to long continuous work sessions.
- **Confidence**: 0.85

**Draft Note Created:**
- Location: `Express/drafts/20250101143000-pomodoro-technique-prevents-burnout.md`
- Contains: Insight, source entry, metadata
- Ready for review and promotion to zettelkasten

## 🎯 Tips

1. **Review Regularly**: Check drafts during morning check-in
2. **Accept Good Insights**: Don't let valuable learnings sit in drafts
3. **Edit Before Accepting**: Refine insights to make them clearer
4. **Reject Noise**: Delete drafts that aren't truly evergreen
5. **Adjust Confidence**: Lower threshold if you want more drafts, raise if you want fewer

## 🔧 Troubleshooting

**No drafts being created?**
- Check that `GTD_INSIGHT_SCANNING_ENABLED="true"`
- Verify daily logs exist in `~/Documents/daily_logs/`
- Check AI backend is running (LM Studio or Ollama)
- Lower confidence threshold if needed

**Too many drafts?**
- Raise `GTD_INSIGHT_MIN_CONFIDENCE` (e.g., 0.8 or 0.9)
- Reduce `GTD_INSIGHT_SCAN_DAYS` (e.g., 3 instead of 7)

**Drafts not showing in morning check-in?**
- Run `gtd-scan-insights scan` manually
- Check `Express/drafts/` directory exists
- Verify drafts were created successfully
