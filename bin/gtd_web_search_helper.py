#!/usr/bin/env python3
"""
GTD Web Search Helper - Performs web search and returns formatted results.
Note: Browser MCP tools are only available to the AI assistant, not to Python scripts.
This script outputs instructions for the AI assistant to perform the search.
"""

import sys
import json
from urllib.parse import quote_plus

def perform_web_search(query):
    """
    Output web search request that the AI assistant should perform.
    The AI assistant will use browser MCP tools to actually perform the search.
    """
    # Construct Google search URL
    encoded_query = quote_plus(query)
    search_url = f"https://www.google.com/search?q={encoded_query}"
    
    # Output a clear instruction for the AI assistant
    # The AI assistant should detect this and perform the search using browser MCP tools
    result = {
        "query": query,
        "search_url": search_url,
        "status": "pending",
        "instruction": f"AI ASSISTANT: Please perform web search using browser MCP tools:\n1. Navigate to: {search_url}\n2. Take snapshot\n3. Extract key information\n4. Return results"
    }
    
    return json.dumps(result, indent=2)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: gtd_web_search_helper.py <query>")
        sys.exit(1)
    
    query = " ".join(sys.argv[1:])
    result = perform_web_search(query)
    print(result)

