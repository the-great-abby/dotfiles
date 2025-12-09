#!/usr/bin/env python3
"""
Unit tests for GTD Tool Registry
Tests tool registration, execution, and definitions.
"""

import unittest
from unittest.mock import Mock, patch, MagicMock
import sys
import json
from pathlib import Path

# Add functions directory to path
functions_dir = Path(__file__).parent.parent / "zsh" / "functions"
sys.path.insert(0, str(functions_dir))

from gtd_tool_registry import (
    register_tool,
    get_tool_definitions,
    execute_tool,
    get_available_tools_by_category,
    list_all_tools,
    TOOL_REGISTRY
)


class TestToolRegistry(unittest.TestCase):
    """Test cases for tool registry system"""
    
    def setUp(self):
        """Set up test fixtures - clear registry before each test"""
        # Save original registry
        self.original_registry = TOOL_REGISTRY.copy()
        TOOL_REGISTRY.clear()
    
    def tearDown(self):
        """Restore original registry after each test"""
        TOOL_REGISTRY.clear()
        TOOL_REGISTRY.update(self.original_registry)
    
    def test_register_tool_basic(self):
        """Test basic tool registration"""
        def test_handler(query: str) -> str:
            return f"Result for {query}"
        
        register_tool(
            name="test_tool",
            description="A test tool",
            parameters={
                "type": "object",
                "properties": {
                    "query": {"type": "string"}
                }
            },
            handler=test_handler,
            category="test"
        )
        
        self.assertIn("test_tool", TOOL_REGISTRY)
        tool_info = TOOL_REGISTRY["test_tool"]
        self.assertEqual(tool_info["name"], "test_tool")
        self.assertEqual(tool_info["description"], "A test tool")
        self.assertEqual(tool_info["category"], "test")
        self.assertIsNotNone(tool_info["handler"])
    
    def test_register_tool_without_handler(self):
        """Test registering tool without handler"""
        register_tool(
            name="tool_no_handler",
            description="Tool without handler",
            parameters={"type": "object"},
            handler=None,
            category="test"
        )
        
        self.assertIn("tool_no_handler", TOOL_REGISTRY)
        self.assertIsNone(TOOL_REGISTRY["tool_no_handler"]["handler"])
    
    def test_register_tool_default_category(self):
        """Test that default category is 'general'"""
        register_tool(
            name="default_category_tool",
            description="Tool with default category",
            parameters={"type": "object"}
        )
        
        self.assertEqual(TOOL_REGISTRY["default_category_tool"]["category"], "general")
    
    def test_get_tool_definitions_all(self):
        """Test getting all tool definitions"""
        register_tool(
            name="tool1",
            description="Tool 1",
            parameters={"type": "object"},
            category="cat1"
        )
        register_tool(
            name="tool2",
            description="Tool 2",
            parameters={"type": "object"},
            category="cat2"
        )
        
        definitions = get_tool_definitions()
        
        self.assertIsInstance(definitions, list)
        self.assertEqual(len(definitions), 2)
        
        # Check structure
        for tool_def in definitions:
            self.assertIn("type", tool_def)
            self.assertEqual(tool_def["type"], "function")
            self.assertIn("function", tool_def)
            self.assertIn("name", tool_def["function"])
            self.assertIn("description", tool_def["function"])
            self.assertIn("parameters", tool_def["function"])
    
    def test_get_tool_definitions_filtered(self):
        """Test getting tool definitions filtered by category"""
        register_tool(
            name="web_tool",
            description="Web tool",
            parameters={"type": "object"},
            category="web"
        )
        register_tool(
            name="gtd_tool",
            description="GTD tool",
            parameters={"type": "object"},
            category="gtd"
        )
        
        web_tools = get_tool_definitions(categories=["web"])
        
        self.assertEqual(len(web_tools), 1)
        self.assertEqual(web_tools[0]["function"]["name"], "web_tool")
    
    def test_execute_tool_success(self):
        """Test successful tool execution"""
        def test_handler(query: str) -> str:
            return f"Result: {query}"
        
        register_tool(
            name="executable_tool",
            description="Executable tool",
            parameters={"type": "object"},
            handler=test_handler
        )
        
        result = execute_tool("executable_tool", {"query": "test"})
        
        self.assertEqual(result, "Result: test")
    
    def test_execute_tool_unknown(self):
        """Test executing unknown tool"""
        result = execute_tool("unknown_tool", {})
        
        self.assertIn("Error", result)
        self.assertIn("Unknown tool", result)
    
    def test_execute_tool_no_handler(self):
        """Test executing tool without handler"""
        register_tool(
            name="no_handler_tool",
            description="Tool without handler",
            parameters={"type": "object"},
            handler=None
        )
        
        result = execute_tool("no_handler_tool", {})
        
        self.assertIn("Error", result)
        self.assertIn("no handler", result)
    
    def test_execute_tool_handler_exception(self):
        """Test tool execution when handler raises exception"""
        def failing_handler():
            raise ValueError("Test error")
        
        register_tool(
            name="failing_tool",
            description="Failing tool",
            parameters={"type": "object"},
            handler=failing_handler
        )
        
        result = execute_tool("failing_tool", {})
        
        self.assertIn("Error", result)
        self.assertIn("Test error", result)
    
    def test_execute_tool_returns_dict(self):
        """Test tool execution when handler returns dict (should be JSON-ified)"""
        def dict_handler() -> dict:
            return {"result": "success", "data": [1, 2, 3]}
        
        register_tool(
            name="dict_tool",
            description="Dict returning tool",
            parameters={"type": "object"},
            handler=dict_handler
        )
        
        result = execute_tool("dict_tool", {})
        
        # Should be JSON string
        parsed = json.loads(result)
        self.assertEqual(parsed["result"], "success")
    
    def test_get_available_tools_by_category(self):
        """Test getting tools grouped by category"""
        register_tool(
            name="web1",
            description="Web tool 1",
            parameters={"type": "object"},
            category="web"
        )
        register_tool(
            name="web2",
            description="Web tool 2",
            parameters={"type": "object"},
            category="web"
        )
        register_tool(
            name="gtd1",
            description="GTD tool 1",
            parameters={"type": "object"},
            category="gtd"
        )
        
        categories = get_available_tools_by_category()
        
        self.assertIsInstance(categories, dict)
        self.assertIn("web", categories)
        self.assertIn("gtd", categories)
        self.assertEqual(len(categories["web"]), 2)
        self.assertEqual(len(categories["gtd"]), 1)
    
    def test_list_all_tools(self):
        """Test listing all registered tools"""
        register_tool(
            name="tool1",
            description="Tool 1",
            parameters={"type": "object"}
        )
        register_tool(
            name="tool2",
            description="Tool 2",
            parameters={"type": "object"}
        )
        
        tools = list_all_tools()
        
        self.assertIsInstance(tools, list)
        self.assertIn("tool1", tools)
        self.assertIn("tool2", tools)
        self.assertEqual(len(tools), 2)


class TestRegisteredTools(unittest.TestCase):
    """Test cases for tools that are registered by default"""
    
    def test_perform_web_search_registered(self):
        """Test that perform_web_search tool is registered"""
        self.assertIn("perform_web_search", TOOL_REGISTRY)
        
        tool_info = TOOL_REGISTRY["perform_web_search"]
        self.assertEqual(tool_info["category"], "web")
        self.assertIsNotNone(tool_info["handler"])
    
    def test_gtd_list_tasks_registered(self):
        """Test that gtd_list_tasks tool is registered"""
        self.assertIn("gtd_list_tasks", TOOL_REGISTRY)
        
        tool_info = TOOL_REGISTRY["gtd_list_tasks"]
        self.assertEqual(tool_info["category"], "gtd")
        self.assertIsNotNone(tool_info["handler"])
    
    def test_gtd_create_task_registered(self):
        """Test that gtd_create_task tool is registered"""
        self.assertIn("gtd_create_task", TOOL_REGISTRY)
        
        tool_info = TOOL_REGISTRY["gtd_create_task"]
        self.assertEqual(tool_info["category"], "gtd")
        self.assertIsNotNone(tool_info["handler"])
    
    def test_gtd_list_projects_registered(self):
        """Test that gtd_list_projects tool is registered"""
        self.assertIn("gtd_list_projects", TOOL_REGISTRY)
        
        tool_info = TOOL_REGISTRY["gtd_list_projects"]
        self.assertEqual(tool_info["category"], "gtd")
        self.assertIsNotNone(tool_info["handler"])
    
    def test_gtd_read_daily_log_registered(self):
        """Test that gtd_read_daily_log tool is registered"""
        self.assertIn("gtd_read_daily_log", TOOL_REGISTRY)
        
        tool_info = TOOL_REGISTRY["gtd_read_daily_log"]
        self.assertEqual(tool_info["category"], "gtd")
        self.assertIsNotNone(tool_info["handler"])


if __name__ == '__main__':
    unittest.main()
