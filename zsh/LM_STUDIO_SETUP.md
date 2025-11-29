# LM Studio Setup Guide

## What Happens Automatically

### 1. Daily Log Reminders (Every 5 Commands)
Yes! There's an automatic reminder system built into your zsh config:

- **Location**: `zshrc_mac_mise` lines 80-104
- **What it does**: After every 5 commands you run, it shows a friendly reminder to log your thoughts
- **How it works**: Uses zsh's `precmd` hook to track command count
- **Example**: 
  ```
  Command 1-4: Nothing
  Command 5: 💭 Friendly reminder: Don't forget to log your thoughts...
  Command 6-9: Nothing
  Command 10: Reminder again
  ```

### 2. Automatic Advice When Logging
When you run `addInfoToDailyLog "your entry"`:
- ✅ Automatically writes to your daily log file
- ✅ Automatically calls LM Studio for advice (if configured)
- ✅ Uses the default persona (Hank) unless you specify otherwise

### 3. What Does NOT Happen Automatically
- ❌ Model loading (you need to load a model in LM Studio)
- ❌ Server starting (LM Studio needs to be running)
- ❌ Model downloading (you need to download models first)

## How to Download Models in LM Studio

### Step 1: Open LM Studio
Make sure LM Studio is installed and running on your Mac.

### Step 2: Navigate to the Search/Discover Tab
1. Open LM Studio
2. Click on the **"Search"** or **"Discover"** tab (usually at the top)
3. This is where you browse and download models

### Step 3: Search for a Model
You can search by:
- Model name (e.g., "Qwen", "Llama", "Mistral")
- Use case (e.g., "chat", "instruct", "embedding")
- Size (e.g., "small", "7B", "13B")

### Step 4: Choose a Model
**Recommended models for your setup:**

#### Small & Fast (Good for quick responses):
- **Qwen2.5-0.5B-Instruct** - Very small, very fast
- **Phi-3-mini-4k-instruct** - Small, good quality
- **TinyLlama-1.1B-Chat-v1.0** - Tiny, extremely fast

#### Balanced (Good quality/speed):
- **Qwen2.5-7B-Instruct** - Good balance
- **Llama-3.2-3B-Instruct** - Good quality
- **Mistral-7B-Instruct-v0.3** - Excellent quality

#### Embedding Models (for future use):
- **nomic-embed-text-v1.5** - Popular embedding model
- **text-embedding-embeddinggemma-300m-qat** - Smaller embedding

### Step 5: Download the Model
1. Click on a model to see its details
2. You'll see different **quantization** options:
   - **Q4_K_M** - Smaller file, slightly lower quality (recommended)
   - **Q8_0** - Larger file, better quality
   - **F16** - Full precision (largest file)
3. Click the **"Download"** button next to your preferred quantization
4. Wait for the download to complete (progress bar will show)

### Step 6: Load the Model
1. Go to the **"Chat"** tab (or "Models" tab)
2. Find your downloaded model in the list
3. Click on it
4. Click the **"Load"** button (or double-click the model)
5. Wait for it to load (you'll see a progress indicator)

### Step 7: Start the Server
1. Go to the **"Server"** tab in LM Studio
2. Make sure the server is running (should show "Server running" or similar)
3. The default port is usually **1234** (which matches your config)

## Troubleshooting

### "Connection timed out" Error
This usually means:
1. **No model is loaded** - Go to Chat tab and load a model
2. **Model is still loading** - Wait for the loading to complete
3. **Server isn't running** - Check the Server tab

### "Could not connect" Error
1. **LM Studio isn't running** - Open LM Studio app
2. **Wrong port** - Check your config matches LM Studio's server port
3. **Firewall blocking** - Check macOS firewall settings

### Model Not Showing Up
1. **Refresh the model list** - Sometimes you need to refresh
2. **Check download completed** - Make sure download finished
3. **Restart LM Studio** - Sometimes a restart helps

## Quick Setup Checklist

- [ ] LM Studio is installed and running
- [ ] Downloaded at least one chat model (e.g., Qwen2.5-0.5B-Instruct)
- [ ] Model is loaded in the Chat tab
- [ ] Server is running (check Server tab)
- [ ] Test connection: `curl http://localhost:1234/v1/models`

## Testing Your Setup

### Test 1: Check if server is accessible
```bash
curl http://localhost:1234/v1/models
```
Should return JSON with model list.

### Test 2: Test with a persona
```bash
python3 ~/code/personal/dotfiles/zsh/functions/gtd_persona_helper.py hank "Test message"
```

### Test 3: Test with daily log
```bash
addInfoToDailyLog "Testing the connection"
```

## Model Recommendations by Use Case

### For Quick Responses (Personas)
- **Qwen2.5-0.5B-Instruct** - Fastest, good for quick advice
- **Phi-3-mini-4k-instruct** - Small but capable

### For Better Quality
- **Qwen2.5-7B-Instruct** - Good balance
- **Mistral-7B-Instruct-v0.3** - High quality

### For Comedians (Need More Creativity)
- **Mistral-7B-Instruct** - Better at creative/satirical responses
- **Llama-3.2-3B-Instruct** - Good for humor

## Tips

1. **Start small** - Download a small model first (0.5B-3B) to test
2. **Check your Mac's RAM** - Larger models need more RAM
3. **Use quantization** - Q4_K_M is usually the sweet spot
4. **One model at a time** - Only load one model at a time
5. **Keep LM Studio running** - Don't quit the app if you want to use it

## Your Current Config

Based on your `.daily_log_config`:
- **Chat Model**: `Qwen2.5-0.5B-Instruct` (you need to download this)
- **Embedding Model**: `nomic-embed-text-v1.5` (for future use)
- **Max Tokens**: 1200
- **Server URL**: `http://localhost:1234/v1/chat/completions`

Make sure the model name in LM Studio matches (or use "local-model" to use whatever is loaded).



