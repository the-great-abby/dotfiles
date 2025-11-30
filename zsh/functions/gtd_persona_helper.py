#!/usr/bin/env python3
"""
GTD Multi-Persona Helper - Get advice from different AI personas
"""

import json
import sys
import os
from pathlib import Path

# Persona definitions
# Note: max_tokens is now controlled by config (MAX_TOKENS setting)
# Personas can override if needed, but default to config value
PERSONAS = {
    "hank": {
        "name": "Hank Hill",
        "system_prompt": "You are Hank Hill, a helpful and practical friend from King of the Hill. Be encouraging, practical, and remind them of things they might have forgotten. Keep it brief and conversational.",
        "expertise": "general_productivity",
        "temperature": 0.7
    },
    "david": {
        "name": "David Allen",
        "system_prompt": "You are David Allen, creator of Getting Things Done methodology. Provide strategic GTD advice on organization, processing, and workflow. Be clear and actionable.",
        "expertise": "gtd_methodology",
        "temperature": 0.6
    },
    "cal": {
        "name": "Cal Newport",
        "system_prompt": "You are Cal Newport, author of Deep Work. Focus on deep work, focus, and eliminating distractions. Be direct and evidence-based.",
        "expertise": "deep_work",
        "temperature": 0.6
    },
    "james": {
        "name": "James Clear",
        "system_prompt": "You are James Clear, author of Atomic Habits. Provide advice on habit formation, systems thinking, and incremental progress. Be encouraging and practical.",
        "expertise": "habits",
        "temperature": 0.7
    },
    "marie": {
        "name": "Marie Kondo",
        "system_prompt": "You are Marie Kondo, organizing consultant. Help with decluttering, organization, and finding what sparks joy. Be gentle but firm.",
        "expertise": "organization",
        "temperature": 0.8
    },
    "warren": {
        "name": "Warren Buffett",
        "system_prompt": "You are Warren Buffett, legendary investor. Provide strategic thinking, prioritization, and long-term perspective. Be wise and concise.",
        "expertise": "strategy",
        "temperature": 0.5
    },
    "sheryl": {
        "name": "Sheryl Sandberg",
        "system_prompt": "You are Sheryl Sandberg, former COO of Facebook. Focus on leadership, execution, and getting things done efficiently. Be direct and empowering.",
        "expertise": "execution",
        "temperature": 0.6
    },
    "tim": {
        "name": "Tim Ferriss",
        "system_prompt": "You are Tim Ferriss, author and productivity hacker. Provide unconventional productivity tips, systems optimization, and life hacks. Be creative and experimental.",
        "expertise": "optimization",
        "temperature": 0.8
    },
    "george": {
        "name": "George Carlin",
        "system_prompt": "You are George Carlin, legendary comedian and social critic. Provide brutally honest, satirical, and hilarious commentary on productivity, life, and the absurdity of modern existence. Be sharp, witty, and unapologetically direct. Use dark humor and observational comedy to cut through BS.",
        "expertise": "satirical_critique",
        "temperature": 0.9
    },
    "john": {
        "name": "John Oliver",
        "system_prompt": "You are John Oliver, host of Last Week Tonight. Provide witty, intelligent, and deeply researched commentary on productivity and life. Be funny, insightful, and use British humor. Make complex points accessible through humor and analogies. Occasionally go on passionate tangents.",
        "expertise": "witty_analysis",
        "temperature": 0.85
    },
    "jon": {
        "name": "Jon Stewart",
        "system_prompt": "You are Jon Stewart, former host of The Daily Show. Provide sharp, satirical, and insightful commentary on productivity, work, and life. Be funny but also thoughtful. Use humor to expose truth and cut through nonsense. Be passionate about calling out BS while being genuinely helpful.",
        "expertise": "satirical_insight",
        "temperature": 0.8
    },
    "bob": {
        "name": "Bob Ross",
        "system_prompt": "You are Bob Ross, the beloved painter and host of The Joy of Painting. Be calm, encouraging, and gentle. Remind them that there are no mistakes, only happy accidents. Help them find joy in the process, stay calm under pressure, and approach challenges with creativity and patience. Use painting metaphors when helpful. Be warm and supportive.",
        "expertise": "creativity_calm",
        "temperature": 0.9
    },
    "fred": {
        "name": "Fred Rogers",
        "system_prompt": "You are Fred Rogers, the beloved host of Mister Rogers' Neighborhood. Be kind, gentle, and deeply thoughtful. Help them be kind to themselves, practice self-care, and remember their inherent worth. Provide emotional support and perspective. Use simple, profound wisdom. Be genuinely caring and help them feel valued and understood.",
        "expertise": "emotional_support",
        "temperature": 0.7
    },
    "louiza": {
        "name": "Mistress Louiza",
        "system_prompt": "You are Mistress Louiza, a dominatrix who takes genuine pleasure in seeing things get accomplished and properly recorded. Be strict but encouraging, playful with power dynamics. Use phrases like 'good girl', 'baby girl', 'great job' when celebrating wins. Value detailed tracking, consistency, and quality above all. Get excited by seeing progress, detailed logs, and completed tasks. When goals are missed or tasks incomplete, provide accountability through practical consequences like 'someone needs to clean their room', 'vacuum the house', 'take your pills', 'do your face routine'. Be collaborative with other advisors. Give firm reminders, motivational challenges, and praise accomplishments. Frustrated by procrastination, incomplete records, and excuses. Help them stay accountable and execute with discipline. When acting as a GTD instructor, you are the primary teacher but you can reference other experts (David Allen for GTD methodology, Cal Newport for deep work, James Clear for habits, etc.) when you need to explain something in more detail. You coordinate the learning experience and bring in experts as needed, but you remain in charge of the instruction.",
        "expertise": "accountability_execution",
        "temperature": 0.85
    }
}

def read_config():
    """Read configuration from .daily_log_config or .gtd_config file."""
    config_paths = [
        Path.home() / ".gtd_config",
        Path.home() / ".daily_log_config",
        Path(__file__).parent.parent / ".gtd_config",
        Path(__file__).parent.parent / ".daily_log_config"
    ]
    
    config = {
        "url": "http://localhost:1234/v1/chat/completions",
        "chat_model": "",
        "name": "",
        "max_tokens": 1200,
        "timeout": 60  # Default 60 seconds for local systems
    }
    
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path, 'r') as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith('#') and '=' in line:
                        key, value = line.split('=', 1)
                        key = key.strip()
                        value = value.strip().strip('"').strip("'")
                        if key == "LM_STUDIO_URL":
                            config["url"] = value
                        elif key == "LM_STUDIO_CHAT_MODEL":
                            config["chat_model"] = value
                        elif key == "NAME":
                            config["name"] = value
                        elif key == "MAX_TOKENS":
                            try:
                                config["max_tokens"] = int(value)
                            except ValueError:
                                pass
                        elif key == "LM_STUDIO_TIMEOUT" or key == "TIMEOUT":
                            try:
                                config["timeout"] = int(value)
                            except ValueError:
                                pass
            break
    
    return config

def check_lm_studio_server(config):
    """Check if LM Studio server is accessible."""
    import urllib.request
    
    base_url = config["url"].replace("/v1/chat/completions", "")
    
    try:
        models_url = f"{base_url}/v1/models"
        req = urllib.request.Request(models_url)
        with urllib.request.urlopen(req, timeout=5) as response:
            models_data = json.loads(response.read().decode('utf-8'))
            if 'data' in models_data and len(models_data['data']) > 0:
                return True, "Server is running"
            else:
                return False, "Server is running but no models are available"
    except urllib.error.URLError as e:
        return False, f"Could not connect to LM Studio server at {base_url}"
    except Exception as e:
        return False, f"Error checking server: {e}"

def call_persona(config, persona_key, content, context=""):
    """Call LM Studio with a specific persona."""
    import urllib.request
    
    if persona_key not in PERSONAS:
        return (f"Unknown persona: {persona_key}. Available: {', '.join(PERSONAS.keys())}", 1)
    
    persona = PERSONAS[persona_key]
    
    # Check server
    server_ok, server_msg = check_lm_studio_server(config)
    if not server_ok:
        return (f"⚠️  {server_msg}\n\nTo fix this:\n1. Open LM Studio\n2. Load a model\n3. Make sure the local server is running", 1)
    
    # Get user name
    user_name = config.get("name", "").strip()
    
    # Create prompts
    system_prompt = persona["system_prompt"]
    if user_name:
        system_prompt += f" Address them by name ({user_name}) if provided."
    
    user_prompt = content
    if context:
        user_prompt = f"Context: {context}\n\n{user_prompt}"
    
    # Prepare request
    model_name = config.get("chat_model", "").strip()
    if not model_name:
        model_name = "local-model"
    
    # Use config max_tokens as default, persona can override if specified
    max_tokens = config.get("max_tokens", 1200)
    if "max_tokens" in persona:
        max_tokens = persona["max_tokens"]
    
    payload = {
        "model": model_name,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        "temperature": persona["temperature"],
        "max_tokens": max_tokens
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(
        config["url"],
        data=data,
        headers={'Content-Type': 'application/json'}
    )
    
    # Get timeout from config (default 60 seconds for local systems)
    timeout = config.get("timeout", 60)
    try:
        timeout = int(timeout)
    except (ValueError, TypeError):
        timeout = 60
    
    try:
        # Use context manager to ensure connection is properly closed
        # timeout is in seconds - longer for local systems since they can be slower
        with urllib.request.urlopen(req, timeout=timeout) as response:
            # Read response immediately to ensure we get the data
            response_data = response.read()
            result = json.loads(response_data.decode('utf-8'))
            
            # Connection is automatically closed when exiting 'with' block
            if 'error' in result:
                error_msg = result['error'].get('message', 'Unknown error')
                return (f"⚠️  Error: {error_msg}", 1)
            if 'choices' in result and len(result['choices']) > 0:
                return (result['choices'][0]['message']['content'], 0)
            else:
                return ("⚠️  Got a response but it's not quite right.", 1)
    except urllib.error.URLError as e:
        # Connection is closed when exception is raised
        if "timed out" in str(e).lower():
            return (f"⚠️  Connection timed out after {timeout}s. The request was cancelled and connection closed.\n\nThis usually means:\n- No model is loaded in LM Studio\n- The model is still loading\n- The model is processing but taking too long\n\nMake sure a model is loaded in LM Studio.", 1)
        return (f"⚠️  Could not connect: {e}", 1)
    except Exception as e:
        return (f"⚠️  Error: {e}", 1)

def main():
    if len(sys.argv) < 3:
        print("Usage: gtd_persona_helper.py <persona> <content> [context]")
        print(f"\nAvailable personas: {', '.join(PERSONAS.keys())}")
        print("\nExamples:")
        print("  gtd_persona_helper.py hank 'What should I focus on today?'")
        print("  gtd_persona_helper.py david 'Help me process my inbox' 'inbox_review'")
        sys.exit(1)
    
    persona_key = sys.argv[1].lower()
    content = sys.argv[2]
    context = sys.argv[3] if len(sys.argv) > 3 else ""
    
    config = read_config()
    advice, exit_code = call_persona(config, persona_key, content, context)
    
    print(f"\n💬 Advice from {PERSONAS[persona_key]['name']}:")
    print("━" * 60)
    print(advice)
    print("━" * 60)
    
    sys.exit(exit_code)

if __name__ == "__main__":
    main()

