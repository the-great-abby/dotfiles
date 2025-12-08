# AI-Suggested Zettelkasten Connections - Implementation Guide

## 🎯 Overview

AI-powered features to help build meaningful connections in your Zettelkasten knowledge network. These features transform your note collection into an actual knowledge network by suggesting connections, detecting orphaned notes, and identifying valuable insights worth preserving.

## ✅ Features Implemented

### 1. **When Creating Note, Suggest Related Existing Notes**

When you create a new Zettelkasten note using the `zet` command, the system automatically:
- Analyzes your note content and title
- Scans your existing notes in Second Brain
- Suggests up to 5 related notes you might want to link
- Provides reasons why each connection would be valuable

**How it works:**
```bash
zet "Understanding Kubernetes Pods"
# Automatically shows AI suggestions after creating the note
```

**Example output:**
```
💡 AI Connection Suggestions:
   1. Note: Container Orchestration | Path: ... | Reason: Related concept
   2. Note: Docker Basics | Path: ... | Reason: Building block concept
   3. Note: Distributed Systems | Path: ... | Reason: Broader context
```

### 2. **"Notes You Might Want to Link" in Weekly Review**

During your weekly review, the system automatically generates a section with:
- Orphaned notes (notes with no connections)
- Suggested connections for each orphaned note
- Actionable link suggestions

**Location:** Included in weekly review output
**Access:** Run `gtd-review weekly` - suggestions appear in "Second Brain Review" section

### 3. **Detect Orphaned Notes (No Connections)**

Identifies notes that aren't connected to your knowledge network:
- Notes with no outgoing links (`[[links]]`)
- Notes with no incoming links (backlinks)
- Helps you identify opportunities to build connections

**Command:**
```bash
gtd-brain-suggest-connections orphaned [max-notes]
```

**Example:**
```bash
gtd-brain-suggest-connections orphaned 10
```

### 4. **Suggest When Journal Entry Should Become Permanent Note**

Analyzes your daily logs to identify insights worth preserving as permanent Zettelkasten notes:
- Reviews recent log entries (default: last 7 days)
- Identifies valuable insights, concepts, or patterns
- Suggests note titles and initial content
- Provides reasons why each entry should become a permanent note

**Command:**
```bash
gtd-brain-suggest-connections permanent-notes [days-back] [max-suggestions]
```

**Example:**
```bash
gtd-brain-suggest-connections permanent-notes 7 5
```

## 🛠️ Usage

### Via Wizard (Recommended)

Access all features through the Zettelkasten wizard:

```bash
gtd-wizard
# Select: 23) Zettelkasten (atomic notes)
```

**New Options:**
- **12) AI: Suggest connections for a note** - Get connection suggestions for any note
- **13) AI: Find orphaned notes** - Discover notes that need connections
- **14) AI: Suggest log entries → permanent notes** - Find insights to preserve

### Via Command Line

#### Suggest Connections for a Note
```bash
gtd-brain-suggest-connections suggest <note-path> [max-suggestions]

# Example:
gtd-brain-suggest-connections suggest ~/Documents/Second\ Brain/Zettelkasten/my-note.md 5
```

#### Find Orphaned Notes
```bash
gtd-brain-suggest-connections orphaned [max-notes]

# Example:
gtd-brain-suggest-connections orphaned 10
```

#### Suggest Permanent Notes from Logs
```bash
gtd-brain-suggest-connections permanent-notes [days] [max-suggestions]

# Example:
gtd-brain-suggest-connections permanent-notes 7 5
```

#### Weekly Review Suggestions
```bash
gtd-brain-suggest-connections weekly [max-suggestions]

# Example:
gtd-brain-suggest-connections weekly 10
```

## 🔄 Integration Points

### Automatic Integration

1. **Note Creation (`zet` command)**
   - Automatically suggests connections after creating a note
   - No extra steps required

2. **Weekly Review (`gtd-review weekly`)**
   - Automatically includes "Notes You Might Want to Link" section
   - Shows orphaned notes with connection suggestions

### Manual Access

- **Zettelkasten Wizard** (Option 23) - All features available
- **Command Line** - Direct access to all functions
- **Weekly Review File** - Suggestions saved in review file

## 💡 Impact

### Before
- Notes exist in isolation
- Manual linking is time-consuming
- Valuable insights get lost in daily logs
- Hard to identify connection opportunities

### After
- **Automatic connection suggestions** when creating notes
- **Orphaned note detection** surfaces opportunities
- **Log entry analysis** preserves valuable insights
- **Weekly review integration** makes connection-building part of your routine

### Expected Benefits

1. **Faster Knowledge Network Growth** - Suggestions make linking easier
2. **Better Note Organization** - Discover relationships you might miss
3. **Preserve More Insights** - Catch valuable thoughts from daily logs
4. **Reduced Friction** - Less manual work to build connections

## 📊 Success Metrics

Track these to measure impact:
- **Connection Rate**: Percentage of notes with at least one link
- **Orphaned Notes Count**: Should decrease over time
- **Permanent Notes Created**: From log suggestions
- **Weekly Link Suggestions**: How many you act on

View metrics with:
```bash
gtd-success-metrics  # Shows "Zettelkasten Health" metric
```

## 🔧 Technical Details

### AI Integration
- Uses `gtd_persona_helper.py` for AI analysis
- Leverages David Allen persona for GTD-focused suggestions
- Analyzes note content, titles, and structure
- Considers semantic similarity and conceptual relationships

### Data Sources
- **Notes**: Scans `SECOND_BRAIN` directory (default: `~/Documents/obsidian/Second Brain`)
- **Daily Logs**: Reads from `DAILY_LOG_DIR` (default: `~/Documents/daily_logs`)
- **Connections**: Analyzes `[[links]]` syntax in markdown files

### Performance
- Limits note catalog to 100 most recent notes (to avoid token limits)
- Caches results where possible
- Gracefully handles missing files or directories

## 📚 Examples

### Example 1: Creating a Note with Suggestions

```bash
$ zet "Learning Rust Ownership"
✓ Created zettelkasten note: .../202501011200-learning-rust-ownership.md
  ID: 202501011200
  Category: inbox

💡 AI Connection Suggestions:
   1. Note: Memory Management | Path: ... | Reason: Related concept about resource management
   2. Note: Systems Programming | Path: ... | Reason: Rust's primary domain
   3. Note: Programming Languages | Path: ... | Reason: Broader category
   4. Note: Performance Optimization | Path: ... | Reason: Rust's strength
   5. Note: Concurrent Programming | Path: ... | Reason: Rust's concurrency model

💡 Add links using: zet-link link "..." <target-note>
```

### Example 2: Finding Orphaned Notes

```bash
$ gtd-brain-suggest-connections orphaned 5

🔍 Finding orphaned notes (no connections)...

1. Understanding TypeScript Generics
   Path: .../202412151200-understanding-typescript-generics.md
   Suggested links:
      Note: TypeScript Basics | Reason: Foundation concept
      Note: Advanced TypeScript | Reason: Building on basics

2. Kubernetes Networking
   Path: .../202412201400-kubernetes-networking.md
   Suggested links:
      Note: Container Orchestration | Reason: Related orchestration concept
      Note: Networking Fundamentals | Reason: Core networking concepts
```

### Example 3: Permanent Note Suggestions

```bash
$ gtd-brain-suggest-connections permanent-notes 7 3

🔍 Analyzing recent daily log entries for permanent note candidates...

1. Entry: 2025-01-05 14:30 - Realized that batch processing is much more efficient for large datasets
   Title: Batch Processing Efficiency Pattern
   Reason: Insight about performance optimization worth preserving
   Content: When working with large datasets, batch processing significantly improves performance compared to streaming. This applies to both data processing and API calls. Key principles: collect items, process in batches, reduce overhead.

2. Entry: 2025-01-06 09:15 - Learned that morning energy is best for creative work
   Title: Energy-Based Task Scheduling
   Reason: Personal productivity insight worth building upon
   Content: Morning hours (9-11 AM) are optimal for creative work. Afternoon (2-4 PM) better for routine tasks. Evening energy varies. Track and schedule accordingly.

💡 Create permanent notes from these suggestions using: zet "<title>"
```

## 🚀 Next Steps

1. **Try It Out**
   - Create a new note: `zet "Test Note"`
   - Check suggestions automatically displayed

2. **Weekly Review**
   - Run `gtd-review weekly`
   - Review the "Notes You Might Want to Link" section
   - Act on suggestions that resonate

3. **Find Orphans**
   - Run `gtd-brain-suggest-connections orphaned`
   - Link orphaned notes to build your network

4. **Preserve Insights**
   - Run `gtd-brain-suggest-connections permanent-notes`
   - Create permanent notes from valuable log entries

## 📝 Notes

- Suggestions are AI-powered and may vary based on your note content
- You can always ignore suggestions - they're meant to inspire, not dictate
- The system learns your style as you build more connections
- Orphaned notes aren't "bad" - they're opportunities for growth

## 🔗 Related Commands

- `zet` - Create Zettelkasten notes
- `zet-link` - Link notes together
- `gtd-brain-discover` - Discover connections manually
- `gtd-brain-metrics` - View note health metrics
- `gtd-success-metrics` - Track Zettelkasten health
