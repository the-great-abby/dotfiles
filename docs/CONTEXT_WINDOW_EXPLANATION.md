# Context Window and Token Limits Explained

## Understanding Context Windows vs max_tokens

### Key Concepts

1. **Context Window**: The total number of tokens a model can process in a single request (input + output combined)
   - Examples: 8k, 32k, 128k tokens
   - This is a **hard limit** set by the model architecture
   - Cannot be changed via API parameters

2. **max_tokens**: The **maximum number of tokens** the model will **generate in the response** (output only)
   - This is a **parameter you set** in the API request
   - Only limits the OUTPUT, not the input
   - Must satisfy: `input_tokens + max_tokens <= context_window`

### How It Works

```
┌─────────────────────────────────────────────────┐
│         Model Context Window (e.g., 32k)        │
├─────────────────────────────────────────────────┤
│  Input Tokens        │  Output Tokens (max)     │
│  (your prompt)       │  (model response)        │
│  ~10k tokens         │  max_tokens=4000         │
│                      │                          │
│  ✅ Total: 14k < 32k ✅                         │
└─────────────────────────────────────────────────┘
```

### What Happens

1. **You send a request** with:
   - Input: System prompt + user prompt + context (e.g., 10,000 tokens)
   - `max_tokens`: 4000 (maximum output tokens)

2. **The model calculates**:
   - Input tokens: 10,000
   - Max output tokens: 4,000
   - Total needed: 14,000 tokens
   - Context window: 32,000 tokens
   - ✅ Fits! (14k < 32k)

3. **If you exceed the context window**:
   - Input: 30,000 tokens
   - `max_tokens`: 4,000
   - Total needed: 34,000 tokens
   - Context window: 32,000 tokens
   - ❌ Error: "Context length exceeded"

## Current Implementation

### What We're Doing

In `gtd_persona_helper.py` and other functions, we set `max_tokens`:

```python
max_tokens = config.get("max_tokens", 1200)  # Default: 1200 output tokens
payload = {
    "model": model_name,
    "messages": [...],  # Input (system prompt + user prompt)
    "max_tokens": max_tokens,  # Maximum OUTPUT tokens
}
```

### Current Defaults

- **Persona helper**: `max_tokens = 1200` (configurable via `MAX_TOKENS`)
- **Deep analysis**: `max_tokens = 2000` or `4000` (for advice)
- **Fast AI**: `max_tokens = 500`

### What This Means

- ✅ We're setting reasonable OUTPUT limits
- ✅ The model automatically handles the math (input + output <= context window)
- ✅ If input is too large, the model/controller will return an error
- ⚠️ We're NOT explicitly checking if input + max_tokens exceeds context window

## Common Model Context Windows

| Model Family | Typical Context Window |
|--------------|----------------------|
| Gemma 1B/2B | 8k tokens |
| Gemma 3 | 32k tokens |
| Qwen 3 4B | 128k tokens |
| Llama 3.1 8B | 128k tokens |
| GPT-OSS 20B | Varies |

## Best Practices

### 1. Set Reasonable max_tokens

- **Too low**: Responses get cut off mid-sentence
- **Too high**: Wastes tokens if response is shorter, or risks exceeding context window
- **Recommended**: Set based on expected response length
  - Short responses (Hank Hill): 500-1200 tokens
  - Medium responses (advice): 2000-4000 tokens
  - Long responses (deep analysis): 4000-8000 tokens

### 2. Monitor Input Size

If you're including lots of context (vector database results, long prompts), you may need to:
- Reduce `max_tokens` to leave room for input
- Trim context if it's too large
- Use models with larger context windows

### 3. Handle Errors

If you get "context length exceeded" errors:
- Reduce input context (fewer vector results, shorter prompts)
- Reduce `max_tokens`
- Use a model with a larger context window

## Configuration

You can configure `max_tokens` in your config files:

```bash
# In .gtd_config_ai or .daily_log_config
MAX_TOKENS="1200"  # Maximum output tokens
```

Or via environment variable:
```bash
export MAX_TOKENS=2000
```

## Relationship to Timeout Fix

**Important**: The timeout fix (starting timer when processing begins) has **nothing to do with context windows**.

- **Timeout**: When we start counting down the 60-minute limit
- **Context window**: Total tokens the model can handle
- **max_tokens**: Maximum output tokens we want

These are completely separate concerns.

## FAQ

**Q: Do we need to calculate input + output tokens?**  
A: No - the model/controller does this automatically. Just set a reasonable `max_tokens`.

**Q: What if input is very large?**  
A: The model will return an error if input + max_tokens exceeds the context window. You'd need to reduce input or max_tokens.

**Q: Can we customize context window size?**  
A: No - context window is fixed by the model architecture. You can only control `max_tokens` (output limit).

**Q: Should we set max_tokens higher for Ollama Controller?**  
A: No - `max_tokens` is independent of the controller. Set it based on how long you want responses, regardless of backend.

## Example

```python
# Scenario: Using Gemma 3 (32k context window)

# Input: 5,000 tokens (system prompt + user prompt + context)
# max_tokens: 4,000
# Total needed: 9,000 tokens
# Context window: 32,000 tokens
# ✅ Works fine (9k < 32k)

# But if input grows to 29,000 tokens:
# Input: 29,000 tokens
# max_tokens: 4,000  
# Total needed: 33,000 tokens
# Context window: 32,000 tokens
# ❌ Error: Context length exceeded
```

In this case, you'd need to either:
- Reduce input (trim context to ~28k tokens)
- Reduce max_tokens to 3,000
- Use a model with larger context window (128k)
