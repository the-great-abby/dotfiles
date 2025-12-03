# Diagram Format Options - Quick Start

## 🎯 Overview

Your `gtd-diagram` script now supports **4 output formats** for maximum reliability with AI generation:

1. **Mermaid** (default) - Works in Obsidian, GitHub, GitLab
2. **PlantUML** - Very reliable with AI, requires Java
3. **Graphviz/DOT** - Simple and reliable, requires Graphviz
4. **Text** - Always works, no dependencies

---

## 🚀 Usage

### Basic Syntax

```bash
gtd-diagram <command> [--format <format>] [arguments]
```

### Examples

#### Mermaid (Default)
```bash
gtd-diagram mindmap "GTD System Overview"
gtd-diagram flowchart "Wedding Planning Process"
```

#### PlantUML (Most Reliable)
```bash
gtd-diagram mindmap "GTD System" --format plantuml
gtd-diagram flowchart "Process" --format plantuml
gtd-diagram create sequence "Daily Review" --format plantuml
```

#### Graphviz/DOT (Simple & Reliable)
```bash
gtd-diagram mindmap "Topic" --format dot
gtd-diagram flowchart "Workflow" --format dot
```

#### Simple Text Tree (Always Works)
```bash
gtd-diagram mindmap "Topic" --format text
gtd-diagram flowchart "Process" --format text
```

---

## 📊 Format Comparison

| Format | AI Reliability | Dependencies | Best For |
|--------|---------------|--------------|----------|
| **PlantUML** | ⭐⭐⭐⭐⭐ | Java | Flowcharts, Sequence, Mindmaps |
| **Graphviz/DOT** | ⭐⭐⭐⭐⭐ | Graphviz | Hierarchies, Mindmaps |
| **Text** | ⭐⭐⭐⭐⭐ | None | Mindmaps, Simple trees |
| **Mermaid** | ⭐⭐ | None | When it works (Obsidian/GitHub) |

---

## 🔧 Installation Requirements

### PlantUML
```bash
# macOS
brew install plantuml

# Or download from: https://plantuml.com/starting
```

### Graphviz
```bash
# macOS
brew install graphviz

# Linux
sudo apt-get install graphviz
```

### Text Format
✅ No installation needed - always works!

---

## 💡 When to Use Each Format

### Use **PlantUML** when:
- ✅ You need maximum AI reliability
- ✅ You're creating flowcharts or sequence diagrams
- ✅ You have Java installed
- ✅ You want professional-looking diagrams

### Use **Graphviz/DOT** when:
- ✅ You want simple, reliable syntax
- ✅ You're creating mindmaps or hierarchies
- ✅ You have Graphviz installed
- ✅ You want to render to PNG/SVG

### Use **Text** when:
- ✅ You want zero dependencies
- ✅ You're creating simple mindmaps
- ✅ You want human-readable output
- ✅ You can convert to other formats later

### Use **Mermaid** when:
- ✅ You're viewing in Obsidian or GitHub
- ✅ You want markdown integration
- ✅ You don't mind occasional syntax errors

---

## 📝 File Extensions

- **Mermaid**: `.md` (markdown with mermaid code blocks)
- **PlantUML**: `.puml`
- **Graphviz/DOT**: `.dot`
- **Text**: `.txt`

---

## 🎨 Rendering Diagrams

### PlantUML
```bash
# Render to PNG
plantuml diagram.puml

# Render to SVG
plantuml -tsvg diagram.puml
```

### Graphviz/DOT
```bash
# Render to PNG
dot -Tpng diagram.dot -o diagram.png

# Render to SVG
dot -Tsvg diagram.dot -o diagram.svg
```

### Text
✅ Already readable - no rendering needed!

### Mermaid
✅ Renders automatically in Obsidian, GitHub, GitLab

---

## 🔄 Converting Between Formats

You can always regenerate a diagram in a different format:

```bash
# Original (Mermaid, had errors)
gtd-diagram mindmap "Topic"

# Regenerate as PlantUML (more reliable)
gtd-diagram mindmap "Topic" --format plantuml

# Or as simple text (always works)
gtd-diagram mindmap "Topic" --format text
```

---

## 🎯 Recommended Workflow

1. **Start with PlantUML** for flowcharts and sequence diagrams
2. **Use Text** for simple mindmaps (no dependencies)
3. **Use Graphviz/DOT** if you need to render to images
4. **Use Mermaid** only if you need Obsidian/GitHub integration

---

## 🐛 Troubleshooting

### "plantuml not found"
```bash
brew install plantuml
```

### "dot not found"
```bash
brew install graphviz
```

### Mermaid syntax errors
Try regenerating with `--format plantuml` or `--format text`

---

## 📚 More Information

See `DIAGRAM_ALTERNATIVES_GUIDE.md` for detailed comparison and examples.


