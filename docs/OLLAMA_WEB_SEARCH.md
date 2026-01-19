# Ollama Web Search Integration

The GTD system now supports Ollama's web search API, providing high-quality search results with better accuracy and relevance.

## Overview

Ollama's web search API offers:
- **Better accuracy**: More relevant search results
- **Structured data**: Clean, formatted results with titles, URLs, and content snippets
- **Web fetch**: Ability to fetch full page content for specific URLs
- **Integration**: Works seamlessly with existing GTD search functionality

## Setup

### 1. Get Ollama API Key

1. Create a free Ollama account at https://ollama.com
2. Generate an API key from your account settings
3. Set it in your environment:

```bash
export OLLAMA_API_KEY="your-api-key-here"
```

To make it permanent, add to your `~/.zshrc` or `~/.bash_profile`:
```bash
echo 'export OLLAMA_API_KEY="your-api-key-here"' >> ~/.zshrc
source ~/.zshrc
```

### 2. Configure Web Search Provider

Edit `zsh/.gtd_config_ai`:

```bash
# Web Search Provider Configuration
# Options: "ollama" (uses Ollama's web search API) or "duckduckgo" (default)
GTD_WEB_SEARCH_PROVIDER="ollama"
```

Or set via environment variable:
```bash
export GTD_WEB_SEARCH_PROVIDER="ollama"
```

## Usage

### Automatic Integration

Once configured, Ollama web search is automatically used by:
- `execute_web_search()` function
- All persona helper web searches
- Tool calling web searches
- Enhanced search system

### Manual Testing

Test the Ollama web search module directly:
```bash
python3 zsh/functions/gtd_ollama_web_search.py "what is ollama?"
```

Test the full integration:
```bash
bin/test-ollama-web-search "what is ollama?"
```

### Python API

```python
from zsh.functions.gtd_ollama_web_search import (
    ollama_web_search,
    ollama_web_fetch,
    execute_ollama_web_search,
    format_ollama_search_results
)

# Simple search
results = execute_ollama_web_search("what is ollama?", max_results=5)
print(results)

# Advanced usage
search_results = ollama_web_search("python best practices", max_results=10)
formatted = format_ollama_search_results("python best practices", search_results)
print(formatted)

# Fetch a specific page
page_content = ollama_web_fetch("https://ollama.com")
print(page_content['title'])
print(page_content['content'][:500])
```

## Features

### Web Search API

- **Query**: Search query string
- **Max Results**: 1-10 results (default: 5)
- **Returns**: Structured results with title, URL, and content snippet

### Web Fetch API

- **URL**: URL to fetch
- **Returns**: Full page content with title, content, and links

## Configuration

### Environment Variables

- `OLLAMA_API_KEY`: Your Ollama API key (required for Ollama web search)
- `GTD_WEB_SEARCH_PROVIDER`: Set to "ollama" to use Ollama, "duckduckgo" for default
- `GTD_DEBUG`: Set to "true" to see debug messages about search provider fallbacks

### Config File Options

In `zsh/.gtd_config_ai`:
```bash
# Web Search Provider
GTD_WEB_SEARCH_PROVIDER="ollama"  # or "duckduckgo"

# Ollama API Key (can also be set via environment variable)
OLLAMA_API_KEY="${OLLAMA_API_KEY:-}"
```

## Fallback Behavior

The system automatically falls back to DuckDuckGo if:
- Ollama API key is not set
- Ollama web search module is not found
- Ollama API call fails
- `GTD_WEB_SEARCH_PROVIDER` is set to "duckduckgo" or not set

## Integration with Enhanced Search

Ollama web search works with the enhanced search system:
- Enhanced search can use Ollama as the underlying search provider
- Query enhancement and result synthesis still apply
- Better results when combined with enhanced search

## Examples

### Basic Search
```python
from zsh.functions.gtd_persona_helper import execute_web_search

# Will use Ollama if configured, otherwise DuckDuckGo
results = execute_web_search("latest Python features")
print(results)
```

### With Persona Helper
```python
from zsh.functions.gtd_persona_helper import call_persona, read_config

config = read_config()
result, code = call_persona(
    config, 
    'hank', 
    'What are the latest productivity techniques? [WEB_SEARCH_REQUESTED]'
)
print(result)
```

## Troubleshooting

### "OLLAMA_API_KEY not found"
- Make sure you've set the environment variable or config value
- Check that it's exported in your current shell session
- Verify with: `echo $OLLAMA_API_KEY`

### "Ollama web search failed"
- Check your internet connection
- Verify your API key is valid
- Check Ollama API status: https://ollama.com/status
- System will automatically fall back to DuckDuckGo

### Still using DuckDuckGo
- Check `GTD_WEB_SEARCH_PROVIDER` is set to "ollama"
- Verify `OLLAMA_API_KEY` is set
- Enable debug mode: `export GTD_DEBUG=true` to see fallback messages

## API Reference

See [Ollama Web Search Documentation](https://docs.ollama.com/capabilities/web-search) for full API details.

## Related Files

- `zsh/functions/gtd_ollama_web_search.py` - Ollama web search module
- `zsh/functions/gtd_persona_helper.py` - Main web search integration
- `zsh/functions/gtd_enhanced_search.py` - Enhanced search system
- `zsh/.gtd_config_ai` - Configuration file
