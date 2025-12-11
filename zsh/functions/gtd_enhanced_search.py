#!/usr/bin/env python3
"""
GTD Enhanced Search System - Intelligent query generation and result synthesis
Integrates with existing web search functionality to improve search quality.
"""

import json
import sys
import urllib.request
import urllib.error
from typing import List, Dict, Any, Optional
from pathlib import Path


class EnhancedSearchSystem:
    """
    Enhanced search system that adds intelligent query generation and result synthesis.
    Uses LM Studio/Ollama models to enhance vague search phrases and synthesize results.
    """
    
    def __init__(self, config: Dict[str, Any]):
        """
        Initialize the enhanced search system.
        
        Args:
            config: Configuration dict with 'url', 'chat_model', 'backend', etc.
                   (same format as gtd_persona_helper config)
        """
        self.config = config
        self.url = config.get("url", "http://localhost:1234/v1/chat/completions")
        self.quick_model = config.get("chat_model", "")
        self.deep_model = config.get("deep_model_name", "") or config.get("chat_model", "")
        self.timeout = config.get("timeout", 60)
        self.max_tokens = config.get("max_tokens", 1200)
        
        # If no deep model specified, use the same as quick model
        if not self.deep_model:
            self.deep_model = self.quick_model
    
    def _call_llm(self, prompt: str, model: Optional[str] = None, max_tokens: Optional[int] = None, 
                   temperature: float = 0.5, stop: Optional[List[str]] = None) -> str:
        """
        Call the LLM (LM Studio/Ollama) with a prompt.
        
        Args:
            prompt: The prompt to send
            model: Model name (defaults to deep_model)
            max_tokens: Max tokens (defaults to self.max_tokens)
            temperature: Temperature for generation
            stop: Stop sequences
        
        Returns:
            Generated text
        """
        model_name = model or self.deep_model
        if not model_name:
            model_name = "local-model"
        
        max_tokens_val = max_tokens or self.max_tokens
        
        payload = {
            "model": model_name,
            "messages": [
                {"role": "user", "content": prompt}
            ],
            "temperature": temperature,
            "max_tokens": max_tokens_val
        }
        
        if stop:
            payload["stop"] = stop
        
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            self.url,
            data=data,
            headers={'Content-Type': 'application/json'}
        )
        
        try:
            with urllib.request.urlopen(req, timeout=self.timeout) as response:
                response_data = response.read()
                result = json.loads(response_data.decode('utf-8'))
                
                if 'error' in result:
                    error_msg = result['error'].get('message', 'Unknown error')
                    raise Exception(f"LLM error: {error_msg}")
                
                if 'choices' in result and len(result['choices']) > 0:
                    content = result['choices'][0].get('message', {}).get('content', '')
                    return content.strip()
                else:
                    raise Exception("No response from LLM")
        except urllib.error.URLError as e:
            raise Exception(f"Could not connect to LLM: {e}")
        except Exception as e:
            raise Exception(f"Error calling LLM: {e}")
    
    def should_enhance_query(self, user_phrase: str) -> bool:
        """
        Decide if phrase needs enhancement or is already good.
        Uses quick model (1.7B) for speed.
        
        Args:
            user_phrase: The user's search phrase
        
        Returns:
            True if query needs enhancement, False if it's already good
        """
        # Quick heuristic check first (no LLM call needed)
        indicators_of_good_query = [
            len(user_phrase.split()) >= 4,  # Reasonably specific
            any(word in user_phrase.lower() for word in ['how to', 'what is', 'best way', 'who won', 'when did']),
            user_phrase.endswith('?')  # Formed as question
        ]
        
        if sum(indicators_of_good_query) >= 2:
            return False  # Query is already decent
        
        # If we have a quick model and want to be more precise, we could call it here
        # For now, use the heuristic
        return True  # Needs enhancement
    
    def generate_queries(self, user_phrase: str, context: Optional[Dict[str, Any]] = None) -> List[str]:
        """
        Transform vague phrase into 2-3 specific search queries.
        Uses deep model (4B) for quality.
        
        Args:
            user_phrase: The user's original search phrase
            context: Optional context dict with 'work_type', 'current_projects', 'recent_patterns'
        
        Returns:
            List of optimized search queries
        """
        if not context:
            context = {}
        
        # Build context string
        context_parts = []
        if context.get('work_type'):
            context_parts.append(f"Work: {context['work_type']}")
        if context.get('current_projects'):
            projects = context['current_projects'][:2]  # Limit to 2
            context_parts.append(f"Focus: {', '.join(projects)}")
        if context.get('recent_patterns'):
            patterns = context['recent_patterns'][:2]  # Limit to 2
            context_parts.append(f"Challenges: {', '.join(patterns)}")
        
        context_str = "\n".join(context_parts) if context_parts else "General knowledge worker"
        
        prompt = f"""You are a search query optimizer. Transform this phrase into effective search queries.

User's phrase: "{user_phrase}"
Context:
{context_str}

Generate 2-3 specific search queries. Make them:
- Concrete and actionable
- Include relevant context when helpful
- Natural language (not keyword-stuffed)
- Each query should explore a different angle

Return ONLY the queries, one per line. No numbering, no explanations.

Queries:"""
        
        try:
            response = self._call_llm(
                prompt=prompt,
                model=self.deep_model,
                max_tokens=150,
                temperature=0.3,
                stop=["\n\n", "---"]
            )
            
            # Parse queries from response
            queries = [q.strip() for q in response.strip().split('\n') if q.strip()]
            
            # Clean up queries (remove numbering, bullets, etc.)
            cleaned_queries = []
            for q in queries:
                # Remove leading numbers, bullets, dashes
                q = q.lstrip('0123456789.-* ').strip()
                if q and len(q) > 5:  # Only keep substantial queries
                    cleaned_queries.append(q)
            
            # Fallback to original if generation fails
            if not cleaned_queries:
                cleaned_queries = [user_phrase]
            
            return cleaned_queries[:3]  # Max 3 queries
        except Exception as e:
            # If LLM call fails, return original phrase
            print(f"Warning: Query generation failed: {e}", file=sys.stderr)
            return [user_phrase]
    
    def synthesize_results(self, user_phrase: str, search_results: str, 
                          context: Optional[Dict[str, Any]] = None) -> str:
        """
        Synthesize search results into helpful response.
        Uses deep model (4B) for quality.
        
        Args:
            user_phrase: The original user question/phrase
            search_results: Formatted search results string
            context: Optional context dict
        
        Returns:
            Synthesized response
        """
        if not context:
            context = {}
        
        # Build context string
        context_parts = []
        if context.get('work_type'):
            context_parts.append(context['work_type'])
        if context.get('current_projects'):
            projects = context['current_projects'][:2]
            context_parts.append(f"working on {', '.join(projects)}")
        
        context_str = " ".join(context_parts) if context_parts else "knowledge worker"
        
        prompt = f"""Synthesize these search results into a helpful response.

User asked: "{user_phrase}"
Their context: {context_str}

Search results:
{search_results}

Provide a clear, actionable response that:
1. Answers their question directly
2. Relates to their situation when relevant
3. Suggests concrete next steps if applicable
4. Cites 1-2 key sources when helpful

Keep it concise but complete. Be factual and helpful.

Response:"""
        
        try:
            response = self._call_llm(
                prompt=prompt,
                model=self.deep_model,
                max_tokens=400,
                temperature=0.5
            )
            return response.strip()
        except Exception as e:
            # If synthesis fails, return the raw search results
            print(f"Warning: Result synthesis failed: {e}", file=sys.stderr)
            return search_results
    
    def get_user_context(self) -> Dict[str, Any]:
        """
        Extract context from user's journals/tasks.
        This is a placeholder - can be enhanced to actually read from GTD system.
        
        Returns:
            Context dict with work_type, current_projects, recent_patterns
        """
        # For now, return minimal context
        # In the future, this could:
        # - Read recent daily logs
        # - Extract active projects
        # - Identify recent patterns
        # - Get work type from config
        
        context = {
            'work_type': 'knowledge worker',
            'current_projects': [],
            'recent_patterns': []
        }
        
        # Try to get name from config (might indicate work type)
        config = self.config
        name = config.get("name", "")
        if name:
            # Could infer work type from name or other sources
            pass
        
        return context


def enhance_search_query(query: str, config: Dict[str, Any], 
                         context: Optional[Dict[str, Any]] = None,
                         execute_search_func=None,
                         enabled: bool = True) -> Dict[str, Any]:
    """
    Enhanced search wrapper that generates queries, executes searches, and synthesizes results.
    
    Args:
        query: Original user search query
        config: LM Studio/Ollama config dict
        context: Optional user context
        execute_search_func: Function to execute search (takes query, returns results string)
        enabled: Whether enhanced search is enabled (default: True)
    
    Returns:
        Dict with:
            - success: bool
            - original_query: str
            - queries_used: List[str]
            - num_results: int
            - synthesis: str (synthesized response)
            - raw_results: str (raw search results)
    """
    # Check if enhanced search is disabled via config or environment
    if not enabled:
        if execute_search_func:
            raw_results = execute_search_func(query)
            return {
                'success': bool(raw_results),
                'original_query': query,
                'queries_used': [query],
                'num_results': 1 if raw_results else 0,
                'synthesis': raw_results or "",
                'raw_results': raw_results or ""
            }
        else:
            return {
                'success': False,
                'original_query': query,
                'queries_used': [query],
                'num_results': 0,
                'synthesis': "",
                'raw_results': ""
            }
    
    search_system = EnhancedSearchSystem(config)
    
    # Get context if not provided
    if not context:
        context = search_system.get_user_context()
    
    # Step 1: Decide if we need to enhance the query
    needs_enhancement = search_system.should_enhance_query(query)
    
    if needs_enhancement:
        # Step 2: Generate better queries
        queries = search_system.generate_queries(query, context)
    else:
        # Use original query if it's already good
        queries = [query]
    
    # Step 3: Execute searches (if execute_search_func provided)
    all_results = []
    if execute_search_func:
        for q in queries[:2]:  # Max 2 searches
            try:
                results = execute_search_func(q)
                if results:
                    all_results.append({
                        'query': q,
                        'results': results
                    })
            except Exception as e:
                print(f"Warning: Search failed for '{q}': {e}", file=__import__('sys').stderr)
    
    # Step 4: Format results for synthesis
    if all_results:
        formatted_results = ""
        for i, result_data in enumerate(all_results, 1):
            formatted_results += f"Search Query {i}: {result_data['query']}\n"
            formatted_results += f"Results:\n{result_data['results']}\n\n"
        
        # Step 5: Synthesize results
        synthesis = search_system.synthesize_results(query, formatted_results, context)
        
        return {
            'success': True,
            'original_query': query,
            'queries_used': queries,
            'num_results': len(all_results),
            'synthesis': synthesis,
            'raw_results': formatted_results
        }
    else:
        # No results or no search function provided
        return {
            'success': False,
            'original_query': query,
            'queries_used': queries,
            'num_results': 0,
            'synthesis': "",
            'raw_results': ""
        }
