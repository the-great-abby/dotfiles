#!/usr/bin/env python3
"""
Ollama Web Search Integration
Provides web search and web fetch capabilities using Ollama's API
"""

import json
import os
import sys
import urllib.request
import urllib.error
from typing import Dict, Any, List, Optional
from pathlib import Path


def _get_ollama_api_key() -> Optional[str]:
    """Get Ollama API key from environment or config."""
    # Check environment variable first
    api_key = os.getenv("OLLAMA_API_KEY")
    if api_key:
        return api_key
    
    # Try to read from config files
    config_paths = [
        Path.home() / ".gtd_config_ai",
        Path.home() / ".gtd_config",
        Path(__file__).parent.parent / ".gtd_config_ai",
        Path(__file__).parent.parent / ".gtd_config",
    ]
    
    for config_path in config_paths:
        if config_path.exists():
            try:
                with open(config_path, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip().strip('"').strip("'")
                            # Handle variable expansion syntax
                            if value.startswith("${") and ":-" in value:
                                value = value.split(":-", 1)[1].rstrip("}")
                            if key == "OLLAMA_API_KEY" and value:
                                return value
            except Exception:
                continue
    
    return None


def ollama_web_search(query: str, max_results: int = 5) -> Dict[str, Any]:
    """
    Perform a web search using Ollama's web search API.
    
    Args:
        query: Search query string
        max_results: Maximum number of results to return (default 5, max 10)
    
    Returns:
        Dictionary with 'results' key containing list of search results
        Each result has 'title', 'url', and 'content' keys
    
    Raises:
        Exception: If API call fails or API key is missing
    """
    api_key = _get_ollama_api_key()
    if not api_key:
        raise Exception("OLLAMA_API_KEY not found. Please set it in your environment or config file.")
    
    # Validate max_results
    max_results = min(max(1, max_results), 10)
    
    url = "https://ollama.com/api/web_search"
    payload = {
        "query": query,
        "max_results": max_results
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        }
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else "Unknown error"
        try:
            error_data = json.loads(error_body)
            error_msg = error_data.get('error', {}).get('message', error_body)
        except:
            error_msg = error_body
        raise Exception(f"Ollama web search failed (HTTP {e.code}): {error_msg}")
    except urllib.error.URLError as e:
        raise Exception(f"Ollama web search connection error: {str(e)}")
    except Exception as e:
        raise Exception(f"Ollama web search error: {str(e)}")


def ollama_web_fetch(url: str) -> Dict[str, Any]:
    """
    Fetch a web page using Ollama's web fetch API.
    
    Args:
        url: URL to fetch
    
    Returns:
        Dictionary with 'title', 'content', and 'links' keys
    
    Raises:
        Exception: If API call fails or API key is missing
    """
    api_key = _get_ollama_api_key()
    if not api_key:
        raise Exception("OLLAMA_API_KEY not found. Please set it in your environment or config file.")
    
    api_url = "https://ollama.com/api/web_fetch"
    payload = {
        "url": url
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        api_url,
        data=data,
        headers={
            'Content-Type': 'application/json',
            'Authorization': f'Bearer {api_key}'
        }
    )
    
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            return result
    except urllib.error.HTTPError as e:
        error_body = e.read().decode('utf-8') if e.fp else "Unknown error"
        try:
            error_data = json.loads(error_body)
            error_msg = error_data.get('error', {}).get('message', error_body)
        except:
            error_msg = error_body
        raise Exception(f"Ollama web fetch failed (HTTP {e.code}): {error_msg}")
    except urllib.error.URLError as e:
        raise Exception(f"Ollama web fetch connection error: {str(e)}")
    except Exception as e:
        raise Exception(f"Ollama web fetch error: {str(e)}")


def format_ollama_search_results(query: str, results: Dict[str, Any]) -> str:
    """
    Format Ollama web search results into a readable string.
    
    Args:
        query: Original search query
        results: Results dictionary from ollama_web_search()
    
    Returns:
        Formatted string with search results
    """
    if not results or 'results' not in results:
        return f"Web search for '{query}' returned no results."
    
    search_results = results['results']
    if not search_results:
        return f"Web search for '{query}' returned no results."
    
    formatted = f"Web Search Results for '{query}':\n\n"
    
    for i, result in enumerate(search_results, 1):
        title = result.get('title', 'Untitled')
        url = result.get('url', '')
        content = result.get('content', '')
        
        formatted += f"{i}. {title}\n"
        if url:
            formatted += f"   URL: {url}\n"
        if content:
            # Truncate very long content
            if len(content) > 500:
                content = content[:500] + "..."
            formatted += f"   {content}\n"
        formatted += "\n"
    
    return formatted


def execute_ollama_web_search(query: str, max_results: int = 5) -> str:
    """
    Execute Ollama web search and return formatted results.
    This is the main entry point for using Ollama web search.
    
    Args:
        query: Search query string
        max_results: Maximum number of results (default 5, max 10)
    
    Returns:
        Formatted search results string
    """
    try:
        results = ollama_web_search(query, max_results=max_results)
        return format_ollama_search_results(query, results)
    except Exception as e:
        return f"Error performing Ollama web search for '{query}': {str(e)}"


if __name__ == "__main__":
    # Test the module
    if len(sys.argv) < 2:
        print("Usage: gtd_ollama_web_search.py <query> [max_results]")
        sys.exit(1)
    
    query = sys.argv[1]
    max_results = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    
    try:
        result = execute_ollama_web_search(query, max_results=max_results)
        print(result)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
