#!/usr/bin/env python3
"""
Agent Skills Management for GTD System

Provides discovery, loading, and execution of Agent Skills compatible with
the Agent Skills specification (agentskills.io).

Each skill is a folder containing:
- SKILL.md: Metadata and instructions in YAML frontmatter + markdown
- Optional: scripts/, templates/, resources/ subdirectories
"""

import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import logging

# Try to import yaml, but make it optional
try:
    import yaml
    YAML_AVAILABLE = True
except ImportError:
    YAML_AVAILABLE = False

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Default skills directory
DEFAULT_SKILLS_DIR = Path(__file__).parent / "skills"
SKILLS_DIR = Path(os.getenv("GTD_SKILLS_DIR", str(DEFAULT_SKILLS_DIR)))

# Ensure skills directory exists
SKILLS_DIR.mkdir(parents=True, exist_ok=True)


class AgentSkill:
    """Represents a single Agent Skill."""
    
    def __init__(self, skill_path: Path):
        self.path = Path(skill_path)
        self.skill_md = self.path / "SKILL.md"
        self.metadata: Dict[str, Any] = {}
        self.instructions: str = ""
        self.scripts_dir = self.path / "scripts"
        self.templates_dir = self.path / "templates"
        self.resources_dir = self.path / "resources"
        
        if self.skill_md.exists():
            self._load_skill()
    
    def _parse_simple_yaml(self, yaml_content: str) -> Dict[str, Any]:
        """Simple YAML-like parser for basic frontmatter without PyYAML."""
        metadata = {}
        for line in yaml_content.split('\n'):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if ':' in line:
                key, value = line.split(':', 1)
                key = key.strip()
                value = value.strip().strip('"').strip("'").strip('[').strip(']')
                # Handle arrays (simple case)
                if value.startswith('[') or ',' in value:
                    # Extract list items
                    items = re.findall(r"['\"]?([^,'\"]+)['\"]?", value)
                    metadata[key] = items
                else:
                    metadata[key] = value
        return metadata
    
    def _load_skill(self):
        """Load SKILL.md file and parse YAML frontmatter + markdown."""
        try:
            with open(self.skill_md, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Parse YAML frontmatter
            frontmatter_match = re.match(r'^---\s*\n(.*?)\n---\s*\n(.*)$', content, re.DOTALL)
            if frontmatter_match:
                yaml_content = frontmatter_match.group(1)
                self.instructions = frontmatter_match.group(2)
                try:
                    if YAML_AVAILABLE:
                        self.metadata = yaml.safe_load(yaml_content) or {}
                    else:
                        # Simple key-value parsing without yaml library
                        self.metadata = self._parse_simple_yaml(yaml_content)
                except Exception as e:
                    logger.warning(f"Error parsing YAML frontmatter in {self.skill_md}: {e}")
                    self.metadata = {}
            else:
                # No frontmatter, treat entire file as instructions
                self.instructions = content
                self.metadata = {
                    "name": self.path.name,
                    "description": "Skill loaded from SKILL.md without frontmatter"
                }
            
            # Ensure required metadata fields
            if "name" not in self.metadata:
                self.metadata["name"] = self.path.name
            if "description" not in self.metadata:
                self.metadata["description"] = self.instructions[:200] if self.instructions else "No description"
            if "version" not in self.metadata:
                self.metadata["version"] = "1.0.0"
            if "tags" not in self.metadata:
                self.metadata["tags"] = []
            
        except Exception as e:
            logger.error(f"Error loading skill from {self.skill_md}: {e}")
            self.metadata = {
                "name": self.path.name,
                "description": f"Error loading skill: {e}",
                "version": "0.0.0",
                "tags": []
            }
            self.instructions = ""
    
    def get_tool_schema(self) -> Optional[Dict[str, Any]]:
        """Convert skill to MCP Tool schema if applicable."""
        # Skills can define their own tool schema in metadata
        if "tool" in self.metadata:
            return self.metadata["tool"]
        
        # Generate a default tool schema from skill metadata
        return {
            "type": "object",
            "properties": {
                "skill_args": {
                    "type": "object",
                    "description": f"Arguments for skill: {self.metadata.get('description', '')}"
                }
            },
            "required": []
        }
    
    def execute_script(self, script_name: str, args: Dict[str, Any] = None) -> Tuple[bool, str]:
        """Execute a script from the skill's scripts directory."""
        if not self.scripts_dir.exists():
            return False, f"Scripts directory not found in skill: {self.path.name}"
        
        script_path = self.scripts_dir / script_name
        if not script_path.exists():
            return False, f"Script not found: {script_name}"
        
        # Make script executable if it's a shell script
        if script_path.suffix in [".sh", ".bash"]:
            os.chmod(script_path, 0o755)
        
        try:
            # Convert args dict to environment variables or command-line args
            env = os.environ.copy()
            if args:
                # Convert args to JSON string for passing to script
                env["SKILL_ARGS"] = json.dumps(args)
                # Also set individual args as env vars
                for key, value in args.items():
                    env[f"SKILL_ARG_{key.upper()}"] = str(value)
            
            # Determine how to run the script
            if script_path.suffix == ".py":
                cmd = ["python3", str(script_path)]
            elif script_path.suffix in [".sh", ".bash"]:
                cmd = ["bash", str(script_path)]
            else:
                # Try to execute directly
                cmd = [str(script_path)]
            
            result = subprocess.run(
                cmd,
                env=env,
                cwd=str(self.path),
                capture_output=True,
                text=True,
                timeout=300  # 5 minute timeout
            )
            
            if result.returncode == 0:
                return True, result.stdout
            else:
                return False, f"Script failed: {result.stderr}"
        
        except subprocess.TimeoutExpired:
            return False, "Script execution timed out"
        except Exception as e:
            return False, f"Error executing script: {str(e)}"
    
    def get_template(self, template_name: str) -> Optional[str]:
        """Load a template from the skill's templates directory."""
        if not self.templates_dir.exists():
            return None
        
        template_path = self.templates_dir / template_name
        if template_path.exists():
            try:
                with open(template_path, 'r', encoding='utf-8') as f:
                    return f.read()
            except Exception as e:
                logger.error(f"Error reading template {template_name}: {e}")
                return None
        return None
    
    def get_resource(self, resource_name: str) -> Optional[bytes]:
        """Load a resource file from the skill's resources directory."""
        if not self.resources_dir.exists():
            return None
        
        resource_path = self.resources_dir / resource_name
        if resource_path.exists():
            try:
                with open(resource_path, 'rb') as f:
                    return f.read()
            except Exception as e:
                logger.error(f"Error reading resource {resource_name}: {e}")
                return None
        return None
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert skill to dictionary for serialization."""
        return {
            "id": self.path.name,
            "path": str(self.path),
            "metadata": self.metadata,
            "instructions_preview": self.instructions[:500] if self.instructions else "",
            "has_scripts": self.scripts_dir.exists() and any(self.scripts_dir.iterdir()),
            "has_templates": self.templates_dir.exists() and any(self.templates_dir.iterdir()),
            "has_resources": self.resources_dir.exists() and any(self.resources_dir.iterdir()),
        }


class SkillsRegistry:
    """Registry for discovering and managing Agent Skills."""
    
    def __init__(self, skills_dir: Path = None):
        self.skills_dir = Path(skills_dir) if skills_dir else SKILLS_DIR
        self.skills: Dict[str, AgentSkill] = {}
        self._discover_skills()
    
    def _discover_skills(self):
        """Discover all skills in the skills directory."""
        self.skills = {}
        
        if not self.skills_dir.exists():
            logger.warning(f"Skills directory does not exist: {self.skills_dir}")
            return
        
        for item in self.skills_dir.iterdir():
            if item.is_dir() and not item.name.startswith('.'):
                skill_md = item / "SKILL.md"
                if skill_md.exists():
                    try:
                        skill = AgentSkill(item)
                        self.skills[skill.metadata["name"]] = skill
                        logger.info(f"Loaded skill: {skill.metadata['name']}")
                    except Exception as e:
                        logger.error(f"Error loading skill from {item}: {e}")
    
    def get_skill(self, skill_name: str) -> Optional[AgentSkill]:
        """Get a skill by name or folder ID."""
        # First try direct lookup by metadata name
        if skill_name in self.skills:
            return self.skills[skill_name]
        
        # Try lookup by folder name (ID)
        for skill in self.skills.values():
            if skill.path.name == skill_name:
                return skill
        
        # Try case-insensitive lookup by metadata name
        skill_name_lower = skill_name.lower()
        for skill in self.skills.values():
            if skill.metadata.get("name", "").lower() == skill_name_lower:
                return skill
        
        # Try partial match on folder name
        for skill in self.skills.values():
            if skill.path.name.lower() == skill_name_lower:
                return skill
        
        return None
    
    def list_skills(self) -> List[Dict[str, Any]]:
        """List all discovered skills."""
        return [skill.to_dict() for skill in self.skills.values()]
    
    def search_skills(self, query: str = None, tags: List[str] = None) -> List[Dict[str, Any]]:
        """Search skills by query string or tags."""
        results = []
        
        for skill in self.skills.values():
            match = True
            
            # Search by query string
            if query:
                query_lower = query.lower()
                match = (
                    query_lower in skill.metadata.get("name", "").lower() or
                    query_lower in skill.metadata.get("description", "").lower() or
                    query_lower in skill.instructions.lower()
                )
            
            # Filter by tags
            if match and tags:
                skill_tags = [tag.lower() for tag in skill.metadata.get("tags", [])]
                match = any(tag.lower() in skill_tags for tag in tags)
            
            if match:
                results.append(skill.to_dict())
        
        return results
    
    def reload_skills(self):
        """Reload all skills from disk."""
        self._discover_skills()
    
    def execute_skill(
        self,
        skill_name: str,
        method: str = "instructions",
        args: Dict[str, Any] = None
    ) -> Tuple[bool, str, Dict[str, Any]]:
        """
        Execute a skill using the specified method.
        
        Args:
            skill_name: Name of the skill to execute
            method: Execution method: "instructions", "script:<script_name>", "template:<template_name>"
            args: Arguments to pass to the skill
        
        Returns:
            Tuple of (success, output, metadata)
        """
        skill = self.get_skill(skill_name)
        if not skill:
            return False, f"Skill not found: {skill_name}", {}
        
        args = args or {}
        metadata = {
            "skill": skill_name,
            "method": method,
            "metadata": skill.metadata
        }
        
        if method == "instructions":
            # Return instructions as output
            return True, skill.instructions, metadata
        
        elif method.startswith("script:"):
            script_name = method.split(":", 1)[1]
            success, output = skill.execute_script(script_name, args)
            return success, output, metadata
        
        elif method.startswith("template:"):
            template_name = method.split(":", 1)[1]
            template_content = skill.get_template(template_name)
            if template_content:
                # Apply simple template substitution
                for key, value in args.items():
                    template_content = template_content.replace(f"{{{{ {key} }}}}", str(value))
                    template_content = template_content.replace(f"{{{key}}}", str(value))
                return True, template_content, metadata
            else:
                return False, f"Template not found: {template_name}", metadata
        
        else:
            return False, f"Unknown execution method: {method}", metadata


# Global registry instance
_registry: Optional[SkillsRegistry] = None


def get_registry() -> SkillsRegistry:
    """Get or create the global skills registry."""
    global _registry
    if _registry is None:
        _registry = SkillsRegistry()
    return _registry
