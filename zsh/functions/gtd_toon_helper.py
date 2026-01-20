#!/usr/bin/env python3
"""
TOON (Token Output Object Notation) Helper Module
Provides utilities for reading/writing TOON format files with JSON fallback.
"""

import json
from pathlib import Path
from typing import Any, Dict, Optional
from datetime import datetime


def load_toon_file(file_path: Path) -> Dict[str, Any]:
    """
    Load a TOON file, with automatic fallback to JSON if TOON parsing fails.
    Also handles migration from .json to .toon files.
    
    Args:
        file_path: Path to the TOON file (.toon extension)
        
    Returns:
        Dictionary containing the parsed data
    """
    # Try TOON file first
    toon_path = file_path
    json_path = file_path.with_suffix('.json')
    
    # If TOON file doesn't exist but JSON does, migrate it
    if not toon_path.exists() and json_path.exists():
        print(f"Migrating {json_path} to TOON format...")
        data = load_json_file(json_path)
        save_toon_file(toon_path, data)
        # Optionally backup the old JSON file
        backup_path = json_path.with_suffix('.json.backup')
        if not backup_path.exists():
            import shutil
            shutil.copy2(json_path, backup_path)
        return data
    
    if toon_path.exists():
        try:
            # Try to import TOON library
            try:
                import toon
                with open(toon_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    return toon.loads(content)
            except ImportError:
                # Fallback: try py-toon-format
                try:
                    from py_toon_format import loads as toon_loads
                    with open(toon_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        return toon_loads(content)
                except ImportError:
                    # Fallback: try python-toon
                    try:
                        from python_toon import loads as toon_loads
                        with open(toon_path, 'r', encoding='utf-8') as f:
                            content = f.read()
                            return toon_loads(content)
                    except ImportError:
                        # No TOON library available, try JSON fallback
                        if json_path.exists():
                            return load_json_file(json_path)
                        raise ImportError(
                            "No TOON library found. Install one with: "
                            "pip install py-toon-format OR pip install python-toon"
                        )
        except Exception as e:
            # If TOON parsing fails, try JSON fallback
            if json_path.exists():
                print(f"Warning: TOON parsing failed ({e}), falling back to JSON")
                return load_json_file(json_path)
            raise
    
    # If neither exists, return empty dict
    return {}


def save_toon_file(file_path: Path, data: Dict[str, Any]) -> None:
    """
    Save data to a TOON file.
    
    Args:
        file_path: Path to save the TOON file (.toon extension)
        data: Dictionary to save
    """
    # Update timestamp if it exists in data
    if isinstance(data, dict):
        data["last_updated"] = datetime.now().isoformat()
    
    try:
        # Try to import TOON library
        try:
            import toon
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(toon.dumps(data))
        except ImportError:
            # Fallback: try py-toon-format
            try:
                from py_toon_format import dumps as toon_dumps
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(toon_dumps(data))
            except ImportError:
                # Fallback: try python-toon
                try:
                    from python_toon import dumps as toon_dumps
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(toon_dumps(data))
                except ImportError:
                    # No TOON library available, fallback to JSON
                    json_path = file_path.with_suffix('.json')
                    print(f"Warning: No TOON library found, saving as JSON: {json_path}")
                    save_json_file(json_path, data)
    except Exception as e:
        # If TOON encoding fails, fallback to JSON
        json_path = file_path.with_suffix('.json')
        print(f"Warning: TOON encoding failed ({e}), saving as JSON: {json_path}")
        save_json_file(json_path, data)


def load_json_file(file_path: Path) -> Dict[str, Any]:
    """
    Load a JSON file (fallback method).
    
    Args:
        file_path: Path to the JSON file
        
    Returns:
        Dictionary containing the parsed data
    """
    if not file_path.exists():
        return {}
    
    with open(file_path, 'r', encoding='utf-8') as f:
        return json.load(f)


def save_json_file(file_path: Path, data: Dict[str, Any]) -> None:
    """
    Save data to a JSON file (fallback method).
    
    Args:
        file_path: Path to save the JSON file
        data: Dictionary to save
    """
    if isinstance(data, dict):
        data["last_updated"] = datetime.now().isoformat()
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def get_personalization_file_path() -> Path:
    """
    Get the path to the personalization file (TOON format).
    
    Returns:
        Path object pointing to ~/.gtd_personalization.toon
    """
    return Path.home() / ".gtd_personalization.toon"


def migrate_json_to_toon(json_path: Optional[Path] = None, toon_path: Optional[Path] = None) -> bool:
    """
    Migrate an existing JSON personalization file to TOON format.
    
    Args:
        json_path: Path to JSON file (defaults to ~/.gtd_personalization.json)
        toon_path: Path to save TOON file (defaults to ~/.gtd_personalization.toon)
        
    Returns:
        True if migration was successful, False otherwise
    """
    if json_path is None:
        json_path = Path.home() / ".gtd_personalization.json"
    if toon_path is None:
        toon_path = Path.home() / ".gtd_personalization.toon"
    
    if not json_path.exists():
        return False
    
    if toon_path.exists():
        print(f"TOON file already exists: {toon_path}")
        return False
    
    try:
        data = load_json_file(json_path)
        save_toon_file(toon_path, data)
        print(f"✓ Migrated {json_path} to {toon_path}")
        return True
    except Exception as e:
        print(f"Error migrating to TOON: {e}")
        return False


if __name__ == "__main__":
    # Test the helper functions
    test_path = Path.home() / ".gtd_personalization.toon"
    test_data = {
        "created": datetime.now().isoformat(),
        "last_updated": datetime.now().isoformat(),
        "test": "value",
        "goals": {
            "career": ["goal1", "goal2"],
            "personal": ["goal3"]
        }
    }
    
    print("Testing TOON helper...")
    save_toon_file(test_path, test_data)
    loaded = load_toon_file(test_path)
    print(f"Saved and loaded: {loaded}")
