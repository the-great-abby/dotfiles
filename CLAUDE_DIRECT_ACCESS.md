# Ask Claude Directly - Bypassing Smart Router

Most of your requests will be handled intelligently by the smart router, but sometimes you want to ask Claude directly without any Ollama involvement. That's what the **`ask`** command is for.

## Why Ask Claude Directly?

**When to use smart routing (default):**
- Quick persona advice (routes to Ollama ~80% of time)
- Task suggestions (routes to Ollama)
- Task categorization (routes to Ollama)
- Most daily work

**When to use direct Claude:**
- Strategic questions that need depth
- Complex reasoning
- When you want guaranteed Claude quality
- Testing Claude capabilities
- Important decisions

## How to Use

### From Command Line (Fastest)

```bash
# Quick syntax
claude-ask "What's your best productivity strategy?"

# Or use the full command
claude-gtd ask "How should I approach this complex problem?"
```

### From Wizard Menu

```bash
gtd-wizard
→ 11) Get advice from personas
→ 8) Quick Claude + Ollama
→ 5) Ask Claude directly
→ Type your question
```

## Examples

### Example 1: Strategic Question

```bash
claude-ask "I'm deciding between two career paths - how should I think about this decision?"
```

This gets Claude's best thinking, not Ollama's quick answer.

### Example 2: Deep Analysis

```bash
claude-ask "After reviewing my past week, what patterns are emerging in how I spend my time?"
```

Claude will provide thoughtful analysis instead of a categorized suggestion.

### Example 3: Complex Problem

```bash
claude-ask "My team keeps getting stuck on the same problem. What might be the root cause and how would you approach debugging it?"
```

Gets Claude's reasoning, not a pattern-matched response.

### Example 4: Asking About Productivity Systems

```bash
claude-ask "How does GTD compare to other productivity methodologies and what would you recommend for someone juggling multiple priorities?"
```

Complex enough that you want Claude's nuanced take.

## How It Differs From Smart Router

### Smart Router (Default in Hybrid Mode)

```
Your request
    ↓
Router analyzes complexity
    ├─ Simple? → Ollama (instant, free)
    └─ Complex? → Claude (1-3s, small cost)
```

**Pros:**
- Saves API costs (Ollama handles ~90% of requests)
- Fast for simple tasks
- Intelligent routing

**Cons:**
- Sometimes routes to Ollama when you want Claude
- Less predictable which backend you'll get

### Direct Claude

```
Your request
    ↓
Always Claude API
```

**Pros:**
- Predictable - always get Claude
- Best quality for complex questions
- No routing logic overhead

**Cons:**
- Always costs (even for simple questions)
- Slower for quick answers (~1-3s)

## Comparison Table

| Task | Router | `ask` | Better For? |
|------|--------|-------|-----------|
| Quick advice | Usually Ollama | Claude | When unsure, use `ask` |
| Planning | 50/50 split | Claude | Strategic decisions → `ask` |
| Categorization | Ollama | Claude | Routine → router, complex → `ask` |
| Analysis | Claude | Claude | Both good, `ask` is consistent |
| Simple Q&A | Ollama | Claude | Quick questions → router, deep → `ask` |

## Setting Up Claude API Key

The `ask` command requires your Claude API key. Set it once:

```bash
# Option 1: Export in shell (session-only)
export ANTHROPIC_API_KEY=sk-ant-...

# Option 2: Add to ~/.zshrc or ~/.bash_profile (permanent)
echo 'export ANTHROPIC_API_KEY=sk-ant-...' >> ~/.zshrc
source ~/.zshrc

# Option 3: Add to ~/.gtd_config_ai (permanent)
echo 'ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.gtd_config_ai
```

## Cost Considerations

### Smart Router (Default)
- ~$0.002 per request (10% to Claude)
- ~$0.05 per day average
- ~$1.50 per month

### Direct Claude
- ~$0.02 per request (varies by length)
- ~$0.50 per day if used 25 times
- ~$15 per month if used 25 times per day

### Recommendation
- Use **`ask`** for important decisions (maybe 2-5 times per day) = ~$0.10-0.25/day
- Use **router** for routine tasks = ~$0.05/day
- **Total:** ~$0.15-0.30/day = ~$5-10/month

## Real-World Workflow

### Morning Routine

```bash
# Quick persona advice (router handles, usually Ollama)
claude-gtd persona "What should I focus on?" --persona david

# Strategic planning (use Claude directly for depth)
claude-ask "Given my energy and priorities today, what's the best use of my deep focus time?"

# Get suggestions (router handles, usually Ollama)
claude-gtd suggest "finished report, need to start presentation"
```

### Stuck on a Problem

```bash
# Don't ask the router - ask Claude directly
claude-ask "I'm stuck on this architecture decision. What would you recommend and why?"
```

### Weekly Review

```bash
# Deep analysis deserves Claude
claude-ask "Looking at this week's logs, what patterns should I pay attention to for next week?"
```

## Quick Reference

### Commands

```bash
# Smart router (most requests)
claude-gtd persona "question" --persona david
claude-gtd suggest "context"
claude-gtd categorize "tasks"
claude-gtd analyze /path/to/log

# Direct Claude (guaranteed Claude)
claude-ask "your question"
claude-gtd ask "your question"

# Check status
claude-gtd status
claude-gtd mode
```

### Aliases (Optional)

Add to your `.zshrc`:

```bash
alias c="claude-ask"         # Super quick: c "question"
alias c-gtd="claude-gtd"     # Faster typing
alias c-ask="claude-ask"     # Explicit
```

Then use:

```bash
c "What's your take on this?"
c-ask "Strategic question here"
```

## Troubleshooting

### "Claude API key not configured"

```bash
# Check if key is set
echo $ANTHROPIC_API_KEY

# Set it
export ANTHROPIC_API_KEY=sk-ant-...

# Or add to config
echo 'ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.gtd_config_ai
```

### Error Connecting to Claude

```bash
# Check your API key is valid
# Try asking a simple question
claude-ask "Hello"

# Check internet connection
curl https://api.anthropic.com

# Check API status at https://status.anthropic.com
```

### Response is too short/long

Use the router's built-in prompt tuning instead. The `ask` command uses standard Claude settings.

## Advanced: Comparing Router vs Direct

Want to see the difference? Try both:

```bash
# Router (might go to Ollama)
echo "=== Via Router ==="
claude-gtd persona "What's a productivity tip?" --persona skippy

# Direct (always Claude)
echo "=== Direct Claude ==="
claude-ask "What's a productivity tip?"
```

You'll likely see Claude provides more depth, while Ollama is faster and pattern-based.

## Summary

- **Smart Router** = Fast + cheap (default, most requests)
- **Direct Claude** = Quality guaranteed (important decisions, strategic thinking)
- **Both available** from wizard or CLI
- **Start with router**, use `ask` when you need depth
- **Cost:** ~$5-15/month if you use both strategically

Use `claude-ask` for strategic questions, let the router handle routine tasks! 🚀
