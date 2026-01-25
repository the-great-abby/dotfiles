#!/usr/bin/env python3
"""
GTD Wizard TUI - Text User Interface version of the GTD Wizard

A modern TUI built with Textual that provides keyboard navigation,
search/filter, and a better user experience than the traditional menu.
"""

import subprocess
import sys
import os
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass

try:
    from textual.app import App, ComposeResult
    from textual.widgets import (
        Header, Footer, Static, ListView, ListItem, Label,
        Input, Button, Tabs, Tab, DataTable, Markdown
    )
    from textual.containers import Container, Horizontal, Vertical, VerticalScroll
    from textual.binding import Binding
    from textual.message import Message
    from textual.reactive import reactive
    from textual import events
except ImportError as e:
    print("Error: textual library not installed or import failed.")
    print(f"Import error: {e}")
    print(f"Python executable: {sys.executable}")
    print(f"Python version: {sys.version}")
    print("\nInstall with: pip install textual")
    print("Or if using venv: source venv/bin/activate && pip install textual")
    sys.exit(1)


@dataclass
class MenuItem:
    """Represents a menu item in the wizard"""
    number: str
    title: str
    emoji: str
    section: str
    handler: Optional[str] = None  # Bash function or command to call


class MenuSection:
    """Represents a section of the menu"""
    def __init__(self, title: str, emoji: str = ""):
        self.title = title
        self.emoji = emoji
        self.items: List[MenuItem] = []

    def add_item(self, item: MenuItem):
        self.items.append(item)

    def __str__(self):
        return f"{self.emoji} {self.title}"


class GTDWizardTUI(App):
    """Main TUI application for GTD Wizard"""

    CSS = """
    Screen {
        background: $surface;
    }
    
    #menu-list {
        width: 1fr;
        height: 1fr;
    }
    
    #status-panel {
        width: 40;
        height: 1fr;
        border: solid $primary;
        padding: 1;
    }
    
    .status-title {
        text-style: bold;
        color: $accent;
        margin-bottom: 1;
    }
    
    #search-input {
        width: 1fr;
        margin: 1;
    }
    
    .menu-item {
        padding: 1;
    }
    
    .menu-item:hover {
        background: $primary 20%;
    }
    
    .section-header {
        text-style: bold;
        color: $accent;
        padding: 1;
        margin-top: 1;
    }
    
    #main-container {
        layout: horizontal;
    }
    
    #menu-container {
        width: 2fr;
        height: 1fr;
    }
    
    #status-container {
        width: 1fr;
        height: 1fr;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit", priority=True),
        Binding("f", "focus_search", "Search", priority=True),
        Binding("escape", "clear_search", "Clear Search", priority=True),
        Binding("r", "refresh", "Refresh", priority=True),
        Binding("?", "help", "Help", priority=True),
    ]

    def __init__(self):
        super().__init__()
        self.menu_items: List[MenuItem] = []
        self.menu_sections: List[MenuSection] = []
        self.filtered_items: List[MenuItem] = []
        self.current_filter: str = ""
        self.gtd_base_dir = os.environ.get("GTD_BASE_DIR", os.path.expanduser("~/Documents/gtd"))
        self.dotfiles_dir = os.path.expanduser("~/code/dotfiles")
        if not os.path.exists(self.dotfiles_dir):
            self.dotfiles_dir = os.path.expanduser("~/code/personal/dotfiles")

    def compose(self) -> ComposeResult:
        """Create child widgets for the app"""
        yield Header(show_clock=True)
        
        with Container(id="main-container"):
            with VerticalScroll(id="menu-container"):
                yield Input(
                    placeholder="Search menu items... (Press 'f' to focus)",
                    id="search-input"
                )
                yield ListView(id="menu-list")
            
            with VerticalScroll(id="status-container"):
                with Container(id="status-panel", classes="status-panel"):
                    yield Label("📊 System Status", classes="status-title")
                    yield Static("Loading status...", id="status-content")
        
        yield Footer()

    async def on_mount(self) -> None:
        """Called when app starts"""
        self.load_menu_structure()
        await self.update_menu_display()
        self.refresh_status()
        # Focus the menu list
        self.query_one("#menu-list", ListView).focus()

    def load_menu_structure(self):
        """Load menu structure from the bash wizard"""
        # Define menu sections based on the bash wizard structure
        sections = [
            MenuSection("⭐ FOCUS - Favorited Items", "⭐"),
            MenuSection("📥 INPUTS - Capture & Process", "📥"),
            MenuSection("🗂️ ORGANIZATION - Manage Your System", "🗂️"),
            MenuSection("🧠 SECOND BRAIN - Advanced Operations", "🧠"),
            MenuSection("📤 OUTPUTS - Reviews & Creation", "📤"),
            MenuSection("📚 LEARNING - Guides & Discovery", "📚"),
            MenuSection("🔍 ANALYSIS - Insights & Tracking", "🔍"),
            MenuSection("🛠️ TOOLS & SUPPORT", "🛠️"),
            MenuSection("⚙️ SETTINGS", "⚙️"),
            MenuSection("🔧 INFRASTRUCTURE - External Services", "🔧"),
        ]

        # Load favorited items
        focus_section = sections[0]
        try:
            favorited = self.get_favorited_items()
            for idx, item in enumerate(favorited[:5]):  # Limit to 5
                menu_num = 900 + idx
                focus_section.add_item(MenuItem(
                    number=str(menu_num),
                    title=item.get("title", "Unknown"),
                    emoji="⭐",
                    section="FOCUS",
                    handler=f"favorite_{item.get('type', 'item')}_{item.get('id', '')}"
                ))
        except Exception:
            pass

        # Core menu items (matching the bash wizard)
        inputs = sections[1]
        inputs.add_item(MenuItem("1", "Capture something to inbox", "📥", "INPUTS", "capture_wizard"))
        inputs.add_item(MenuItem("2", "Process inbox items", "📋", "INPUTS", "process_wizard"))
        inputs.add_item(MenuItem("15", "Log to daily log", "📝", "INPUTS", "daily_log_wizard"))
        inputs.add_item(MenuItem("31", "View daily log", "👁️", "INPUTS", "view_daily_log"))
        inputs.add_item(MenuItem("19", "Morning/Evening Check-In", "🌅", "INPUTS", "checkin_wizard"))

        org = sections[2]
        org.add_item(MenuItem("3", "Manage tasks", "✅", "ORGANIZATION", "task_wizard"))
        org.add_item(MenuItem("4", "Manage projects", "📁", "ORGANIZATION", "project_wizard"))
        org.add_item(MenuItem("5", "Manage areas of responsibility", "🎯", "ORGANIZATION", "area_wizard"))
        org.add_item(MenuItem("8", "Manage MOCs (Maps of Content)", "🗺️", "ORGANIZATION", "moc_wizard"))
        org.add_item(MenuItem("23", "Zettelkasten (atomic notes)", "🔗", "ORGANIZATION", "zettelkasten_wizard"))
        org.add_item(MenuItem("55", "Prioritization Review", "🎯", "ORGANIZATION", "prioritization_review"))

        brain = sections[3]
        brain.add_item(MenuItem("48", "Connect notes", "🔗", "SECOND_BRAIN", "connect_notes_wizard"))
        brain.add_item(MenuItem("49", "Converge/consolidate notes", "📊", "SECOND_BRAIN", "converge_notes_wizard"))
        brain.add_item(MenuItem("50", "Discover connections", "🔍", "SECOND_BRAIN", "discover_connections_wizard"))
        brain.add_item(MenuItem("51", "Distill (progressive summarization)", "📝", "SECOND_BRAIN", "distill_wizard"))
        brain.add_item(MenuItem("52", "Diverge (expand ideas)", "💡", "SECOND_BRAIN", "diverge_wizard"))
        brain.add_item(MenuItem("53", "Evergreen notes", "🌲", "SECOND_BRAIN", "evergreen_notes_wizard"))
        brain.add_item(MenuItem("54", "Note packets", "📦", "SECOND_BRAIN", "note_packets_wizard"))

        outputs = sections[4]
        outputs.add_item(MenuItem("6", "Review (daily/weekly/monthly)", "📊", "OUTPUTS", "review_wizard"))
        outputs.add_item(MenuItem("7", "Sync with Second Brain", "🧠", "OUTPUTS", "sync_wizard"))
        outputs.add_item(MenuItem("57", "Bidirectional Obsidian Sync", "🔄", "OUTPUTS", "bidirectional_sync_wizard"))
        outputs.add_item(MenuItem("59", "Enhanced Review System", "📊", "OUTPUTS", "enhanced_review_wizard"))
        outputs.add_item(MenuItem("62", "Review Draft Notes", "📝", "OUTPUTS", "review_drafts_wizard"))
        outputs.add_item(MenuItem("66", "Agent Skills (workflows & processes)", "🎯", "OUTPUTS", "agent_skills_wizard"))
        outputs.add_item(MenuItem("9", "Express Phase (create content)", "✍️", "OUTPUTS", "express_wizard"))
        outputs.add_item(MenuItem("10", "Use Templates", "📋", "OUTPUTS", "template_wizard"))
        outputs.add_item(MenuItem("22", "Create diagrams & mindmaps", "🎨", "OUTPUTS", "diagram_wizard"))

        learning = sections[5]
        learning.add_item(MenuItem("12", "Learn Organization System", "📚", "LEARNING", "organization_guide"))
        learning.add_item(MenuItem("13", "Learn Second Brain", "🧠", "LEARNING", "second_brain_guide"))
        learning.add_item(MenuItem("14", "Discover Life Vision", "🎯", "LEARNING", "life_vision_guide"))
        learning.add_item(MenuItem("20", "Learn Kubernetes/CKA", "☸️", "LEARNING", "kubernetes_guide"))
        learning.add_item(MenuItem("21", "Learn Greek (Language)", "🇬🇷", "LEARNING", "greek_guide"))

        analysis = sections[6]
        analysis.add_item(MenuItem("16", "Search GTD system", "🔍", "ANALYSIS", "search_wizard"))
        analysis.add_item(MenuItem("17", "System status", "📊", "ANALYSIS", "system_status"))
        analysis.add_item(MenuItem("25", "Goal Tracking & Progress", "🎯", "ANALYSIS", "goal_tracking_wizard"))
        analysis.add_item(MenuItem("26", "Energy Audit", "⚡", "ANALYSIS", "energy_audit_wizard"))
        analysis.add_item(MenuItem("30", "HealthKit & Health Data", "💪", "ANALYSIS", "healthkit_wizard"))
        analysis.add_item(MenuItem("34", "Log statistics & streaks", "📈", "ANALYSIS", "log_stats_wizard"))
        analysis.add_item(MenuItem("35", "Metric correlations", "🔗", "ANALYSIS", "metric_correlations_wizard"))
        analysis.add_item(MenuItem("36", "Pattern recognition", "🔍", "ANALYSIS", "pattern_recognition_wizard"))
        analysis.add_item(MenuItem("37", "Weekly progress report", "📊", "ANALYSIS", "weekly_progress_wizard"))
        analysis.add_item(MenuItem("38", "Second Brain metrics", "🧠", "ANALYSIS", "second_brain_metrics_wizard"))
        analysis.add_item(MenuItem("56", "Success metrics", "📊", "ANALYSIS", "success_metrics_wizard"))
        analysis.add_item(MenuItem("58", "Learning System Preferences", "📚", "ANALYSIS", "learning_preferences_wizard"))
        analysis.add_item(MenuItem("67", "Personalization Setup", "👤", "ANALYSIS", "personalization_wizard"))

        tools = sections[7]
        tools.add_item(MenuItem("11", "Get advice from personas", "🤖", "TOOLS", "advice_wizard"))
        tools.add_item(MenuItem("18", "Manage habits & recurring tasks", "🔁", "TOOLS", "habits_wizard"))
        tools.add_item(MenuItem("24", "AI Suggestions & MCP Tools", "🤖", "TOOLS", "ai_suggestions_wizard"))
        tools.add_item(MenuItem("29", "Calendar (view, sync tasks)", "📅", "TOOLS", "calendar_wizard"))
        tools.add_item(MenuItem("39", "Energy-aware scheduling", "⚡", "TOOLS", "energy_scheduling_wizard"))
        tools.add_item(MenuItem("40", "What should I do now?", "🎯", "TOOLS", "what_now_wizard"))
        tools.add_item(MenuItem("41", "Find items (advanced search)", "🔍", "TOOLS", "find_items_wizard"))
        tools.add_item(MenuItem("42", "Celebrate milestones", "🎉", "TOOLS", "celebrate_milestones_wizard"))

        settings = sections[8]
        settings.add_item(MenuItem("27", "Configuration & Setup", "⚙️", "SETTINGS", "config_wizard"))
        settings.add_item(MenuItem("28", "Gamification & Habitica", "🎮", "SETTINGS", "gamification_wizard"))
        settings.add_item(MenuItem("60", "Switch Computer Mode", "💻", "SETTINGS", "switch_mode_wizard"))
        settings.add_item(MenuItem("61", "Run Unit Tests", "🧪", "SETTINGS", "run_tests_wizard"))

        infra = sections[9]
        infra.add_item(MenuItem("63", "Database Infrastructure Wizard", "🗄️", "INFRASTRUCTURE", "database_wizard"))
        infra.add_item(MenuItem("64", "RabbitMQ Management Wizard", "🐰", "INFRASTRUCTURE", "rabbitmq_wizard"))
        infra.add_item(MenuItem("65", "Ollama Controller Configuration", "🤖", "INFRASTRUCTURE", "ollama_wizard"))

        # Flatten all items for the main list
        self.menu_sections = sections
        self.menu_items = []
        for section in sections:
            self.menu_items.extend(section.items)
        
        self.filtered_items = self.menu_items.copy()

    def get_favorited_items(self) -> List[Dict]:
        """Get favorited tasks and projects"""
        favorited = []
        try:
            cache_file = Path(self.gtd_base_dir) / ".dashboard_cache.json"
            if cache_file.exists():
                import json
                with open(cache_file) as f:
                    cache = json.load(f)
                    # Get favorited tasks
                    for task_path in cache.get("favorited_tasks", [])[:3]:
                        if task_path and os.path.exists(task_path):
                            task_id = Path(task_path).stem
                            favorited.append({
                                "type": "task",
                                "id": task_id,
                                "title": f"Task: {task_id[:30]}",
                                "path": task_path
                            })
                    # Get favorited projects
                    for project_path in cache.get("favorited_projects", [])[:2]:
                        if project_path and os.path.exists(project_path):
                            project_name = Path(project_path).name
                            favorited.append({
                                "type": "project",
                                "id": project_name,
                                "title": f"Project: {project_name}",
                                "path": project_path
                            })
        except Exception:
            pass
        return favorited

    async def update_menu_display(self):
        """Update the menu list display"""
        list_view = self.query_one("#menu-list", ListView)
        
        # Clear all existing items first (await the async clear)
        await list_view.clear()
        
        current_section = None
        for item in self.filtered_items:
            # Add section header if section changed
            if item.section != current_section:
                # Find matching section
                section = None
                for s in self.menu_sections:
                    # Check if section title contains the section name
                    if item.section in s.title or any(item.section.startswith(word) for word in s.title.split()):
                        section = s
                        break
                if section:
                    # Section headers don't need IDs (they're not selectable)
                    await list_view.append(ListItem(Label(f"\n[bold cyan]{section.emoji} {section.title}[/bold cyan]", classes="section-header")))
                current_section = item.section
            
            # Add menu item with unique ID
            display_text = f"[green]{item.number:>3})[/green] {item.emoji} {item.title}"
            await list_view.append(ListItem(Label(display_text, classes="menu-item"), id=f"item-{item.number}"))

    def refresh_status(self):
        """Refresh the status panel"""
        try:
            # Call the bash wizard's show_dashboard function
            wizard_script = Path(self.dotfiles_dir) / "bin" / "gtd-wizard"
            if wizard_script.exists():
                result = subprocess.run(
                    ["bash", "-c", f"source {wizard_script.parent / 'gtd-common.sh'}; source {wizard_script.parent / 'gtd-wizard-core.sh'}; show_dashboard"],
                    capture_output=True,
                    text=True,
                    timeout=3,
                    cwd=self.dotfiles_dir
                )
                status_text = result.stdout
            else:
                status_text = "Status unavailable"
        except Exception as e:
            status_text = f"Error loading status: {str(e)}"
        
        status_content = self.query_one("#status-content", Static)
        status_content.update(status_text)

    def on_list_view_selected(self, event: ListView.Selected) -> None:
        """Handle menu item selection"""
        if not event.item or not event.item.id:
            return
        
        # Extract item number from ID
        item_id = event.item.id
        if item_id.startswith("item-"):
            item_num = item_id.replace("item-", "")
            self.execute_menu_item(item_num)

    def execute_menu_item(self, item_number: str):
        """Execute the selected menu item"""
        item = next((i for i in self.menu_items if i.number == item_number), None)
        if not item:
            return
        
        # Exit if item is 0
        if item_number == "0":
            self.exit()
            return
        
        # Map item numbers to bash wizard functions
        # This matches the case statement in gtd-wizard-core.sh
        function_map = {
            "1": "capture_wizard",
            "2": "process_wizard",
            "3": "task_wizard",
            "4": "project_wizard",
            "5": "area_wizard",
            "6": "review_wizard",
            "7": "sync_wizard",
            "8": "moc_wizard",
            "9": "express_wizard",
            "10": "template_wizard",
            "11": "advice_wizard",
            "12": "tips_wizard",
            "13": "learn_second_brain_wizard",
            "14": "life_vision_wizard",
            "15": "log_wizard",
            "16": "search_wizard",
            "17": "status_wizard",
            "18": "habit_wizard",
            "19": "checkin_wizard",
            "20": "k8s_wizard",
            "21": "greek_wizard",
            "22": "diagram_wizard",
            "23": "zettelkasten_wizard",
            "24": "ai_suggestions_wizard",
            "25": "goal_tracking_wizard",
            "26": "energy_audit_wizard",
            "27": "config_wizard",
            "28": "gamification_wizard",
            "29": "calendar_wizard",
            "30": "healthkit_wizard",
            # "31": handled specially - calls gtd-log directly
            "34": "log_stats_wizard",
            "35": "metric_correlations_wizard",
            "36": "pattern_recognition_wizard",
            "37": "weekly_progress_wizard",
            "38": "brain_metrics_wizard",
            "39": "energy_schedule_wizard",
            "40": "now_wizard",
            "41": "find_wizard",
            "42": "milestone_wizard",
            "48": "brain_connect_wizard",
            "49": "brain_converge_wizard",
            "50": "brain_discover_wizard",
            "51": "brain_distill_wizard",
            "52": "brain_diverge_wizard",
            "53": "brain_evergreen_wizard",
            "54": "brain_packet_wizard",
            "55": "prioritization_wizard",
            "56": "success_metrics_wizard",
            "57": "bidirectional_sync_wizard",
            "58": "preferences_learning_wizard",
            "59": "enhanced_review_wizard",
            "60": "computer_mode_wizard",
            "61": "test_execution_wizard",
            "62": "review_drafts_wizard",
            "63": "external_database_wizard",
            "64": "external_rabbitmq_wizard",
            "65": "external_ollama_controller_wizard",
            "66": "skills_wizard",
            "67": "personalization_wizard",
        }
        
        # Handle special cases that don't use functions
        if item_number == "31":
            # View daily log - calls gtd-log directly
            self.execute_special_command("31", "gtd-log today")
            return
        
        function_name = function_map.get(item_number)
        
        if not function_name:
            # Handle favorited items (900+)
            if item_number.startswith("90"):
                self.notify("Favorited items require special handling", title="GTD Wizard")
                return
            self.notify(f"Handler not found for item {item_number}", severity="error")
            return
        
    def execute_special_command(self, item_number: str, command: str):
        """Execute a special command that doesn't use a wizard function"""
        try:
            wizard_script = Path(self.dotfiles_dir) / "bin" / "gtd-wizard"
            tui_script = Path(self.dotfiles_dir) / "bin" / "gtd-wizard-tui.py"
            
            if not wizard_script.exists():
                self.notify("Wizard script not found", severity="error")
                return
            
            # Create a wrapper script for special commands
            import tempfile
            temp_script = tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False)
            temp_script.write(f"""#!/bin/bash
set -e
cd "{self.dotfiles_dir}"
export GTD_BASE_DIR="{self.gtd_base_dir}"

# Source common functions
source bin/gtd-common.sh 2>/dev/null || true

# Award XP (matching bash wizard behavior)
if command -v gtd-gamify-award &>/dev/null; then
    gtd-gamify-award "wizard_productive" "" "Used wizard: View Daily Log" 2>/dev/null || true
fi

# Execute the command
{command}

# Pause before returning
echo ""
gtd_quick_pause 2>/dev/null || sleep 2

# Restart TUI
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Returning to TUI..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 1
exec python3 "{tui_script}"
""")
            temp_script.close()
            os.chmod(temp_script.name, 0o755)
            
            self.notify("Launching command...", title="GTD Wizard", timeout=1)
            os.execv("/bin/bash", ["/bin/bash", temp_script.name])
        except Exception as e:
            self.notify(f"Error: {str(e)}", severity="error")
    
    def execute_menu_item(self, item_number: str):
        """Execute the selected menu item"""
        item = next((i for i in self.menu_items if i.number == item_number), None)
        if not item:
            return
        
        # Exit if item is 0
        if item_number == "0":
            self.exit()
            return
        
        # Map item numbers to bash wizard functions
        # This matches the case statement in gtd-wizard-core.sh
        function_map = {
            "1": "capture_wizard",
            "2": "process_wizard",
            "3": "task_wizard",
            "4": "project_wizard",
            "5": "area_wizard",
            "6": "review_wizard",
            "7": "sync_wizard",
            "8": "moc_wizard",
            "9": "express_wizard",
            "10": "template_wizard",
            "11": "advice_wizard",
            "12": "tips_wizard",
            "13": "learn_second_brain_wizard",
            "14": "life_vision_wizard",
            "15": "log_wizard",
            "16": "search_wizard",
            "17": "status_wizard",
            "18": "habit_wizard",
            "19": "checkin_wizard",
            "20": "k8s_wizard",
            "21": "greek_wizard",
            "22": "diagram_wizard",
            "23": "zettelkasten_wizard",
            "24": "ai_suggestions_wizard",
            "25": "goal_tracking_wizard",
            "26": "energy_audit_wizard",
            "27": "config_wizard",
            "28": "gamification_wizard",
            "29": "calendar_wizard",
            "30": "healthkit_wizard",
            # "31": handled specially - calls gtd-log directly
            "34": "log_stats_wizard",
            "35": "metric_correlations_wizard",
            "36": "pattern_recognition_wizard",
            "37": "weekly_progress_wizard",
            "38": "brain_metrics_wizard",
            "39": "energy_schedule_wizard",
            "40": "now_wizard",
            "41": "find_wizard",
            "42": "milestone_wizard",
            "48": "brain_connect_wizard",
            "49": "brain_converge_wizard",
            "50": "brain_discover_wizard",
            "51": "brain_distill_wizard",
            "52": "brain_diverge_wizard",
            "53": "brain_evergreen_wizard",
            "54": "brain_packet_wizard",
            "55": "prioritization_wizard",
            "56": "success_metrics_wizard",
            "57": "bidirectional_sync_wizard",
            "58": "preferences_learning_wizard",
            "59": "enhanced_review_wizard",
            "60": "computer_mode_wizard",
            "61": "test_execution_wizard",
            "62": "review_drafts_wizard",
            "63": "external_database_wizard",
            "64": "external_rabbitmq_wizard",
            "65": "external_ollama_controller_wizard",
            "66": "skills_wizard",
            "67": "personalization_wizard",
        }
        
        # Handle special cases that don't use functions
        if item_number == "31":
            # View daily log - calls gtd-log directly
            self.execute_special_command("31", """if command -v gtd-log &>/dev/null; then
  gtd-log today
elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
  "$HOME/code/dotfiles/bin/gtd-log" today
elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
  "$HOME/code/personal/dotfiles/bin/gtd-log" today
else
  echo "Error: gtd-log command not found"
  exit 1
fi""")
            return
        
        function_name = function_map.get(item_number)
        
        if not function_name:
            # Handle favorited items (900+)
            if item_number.startswith("90"):
                self.notify("Favorited items require special handling", title="GTD Wizard")
                return
            self.notify(f"Handler not found for item {item_number}", severity="error")
            return
        
        # Execute the bash function
        # Since bash wizard functions are interactive, we need to:
        # 1. Exit TUI to give bash full terminal control
        # 2. Run the function
        # 3. Automatically restart the TUI when done
        try:
            wizard_script = Path(self.dotfiles_dir) / "bin" / "gtd-wizard"
            tui_script = Path(self.dotfiles_dir) / "bin" / "gtd-wizard-tui.py"
            
            if not wizard_script.exists():
                self.notify("Wizard script not found", severity="error")
                return
            
            # Create a wrapper script that runs the function and then restarts TUI
            import tempfile
            temp_script = tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False)
            temp_script.write(f"""#!/bin/bash
set -e
cd "{self.dotfiles_dir}"
export GTD_BASE_DIR="{self.gtd_base_dir}"

# Source all wizard scripts (matching gtd-wizard sourcing order)
source bin/gtd-common.sh 2>/dev/null || true
source bin/gtd-guides.sh 2>/dev/null || true
source bin/gtd-wizard-core.sh 2>/dev/null || true
source bin/gtd-select-helper.sh 2>/dev/null || true
source bin/gtd-wizard-inputs.sh 2>/dev/null || true
source bin/gtd-wizard-org.sh 2>/dev/null || true
source bin/gtd-wizard-brain.sh 2>/dev/null || true
source bin/gtd-wizard-outputs.sh 2>/dev/null || true
source bin/gtd-wizard-analysis.sh 2>/dev/null || true
source bin/gtd-wizard-tools.sh 2>/dev/null || true
source bin/gtd-wizard-preferences.sh 2>/dev/null || true
source bin/gtd-wizard-enhanced-review.sh 2>/dev/null || true
source bin/gtd-wizard-personalization.sh 2>/dev/null || true
# Note: gtd-wizard-claude-integration.sh is optional and may not exist
source bin/gtd-wizard-claude-integration.sh 2>/dev/null || true

# Define wrapper functions (like gtd-wizard does)
# These ensure functions are available even if aliases fail
show_breadcrumb() {{
  gtd_show_breadcrumb "$@"
}}

push_menu() {{
  gtd_push_menu "$@"
}}

pop_menu() {{
  gtd_pop_menu "$@"
}}

# Guide function wrappers (aliases don't work in subshells)
show_areas_guide() {{ gtd_show_areas_guide "$@"; }}
show_projects_guide() {{ gtd_show_projects_guide "$@"; }}
show_tasks_guide() {{ gtd_show_tasks_guide "$@"; }}
show_express_guide() {{ gtd_show_express_guide "$@"; }}
show_moc_guide() {{ gtd_show_moc_guide "$@"; }}
show_templates_guide() {{ gtd_show_templates_guide "$@"; }}
show_zettelkasten_guide() {{ gtd_show_zettelkasten_guide "$@"; }}
show_checkin_guide() {{ gtd_show_checkin_guide "$@"; }}
show_organization_guide() {{ gtd_show_organization_guide "$@"; }}
show_review_guide() {{ gtd_show_review_guide "$@"; }}
show_capture_guide() {{ gtd_show_capture_guide "$@"; }}
show_oncall_guide() {{ gtd_show_oncall_guide "$@"; }}
show_process_guide() {{ gtd_show_process_guide "$@"; }}
show_sync_guide() {{ gtd_show_sync_guide "$@"; }}
show_advice_guide() {{ gtd_show_advice_guide "$@"; }}
show_daily_log_guide() {{ gtd_show_daily_log_guide "$@"; }}
show_search_guide() {{ gtd_show_search_guide "$@"; }}
show_status_guide() {{ gtd_show_status_guide "$@"; }}
show_config_guide() {{ gtd_show_config_guide "$@"; }}
show_second_brain_learning_guide() {{ gtd_show_second_brain_learning_guide "$@"; }}
show_life_vision_guide() {{ gtd_show_life_vision_guide "$@"; }}
show_diagram_guide() {{ gtd_show_diagram_guide "$@"; }}
show_habits_guide() {{ gtd_show_habits_guide "$@"; }}
show_learning_guide() {{ gtd_show_learning_guide "$@"; }}
show_ai_suggestions_guide() {{ gtd_show_ai_suggestions_guide "$@"; }}
show_goal_tracking_guide() {{ gtd_show_goal_tracking_guide "$@"; }}
show_energy_audit_guide() {{ gtd_show_energy_audit_guide "$@"; }}
show_gamification_guide() {{ gtd_show_gamification_guide "$@"; }}
show_healthkit_guide() {{ gtd_show_healthkit_guide "$@"; }}
show_calendar_guide() {{ gtd_show_calendar_guide "$@"; }}
show_mood_tracking_guide() {{ gtd_show_mood_tracking_guide "$@"; }}
show_metric_correlations_guide() {{ gtd_show_metric_correlations_guide "$@"; }}
show_pattern_recognition_guide() {{ gtd_show_pattern_recognition_guide "$@"; }}
show_energy_schedule_guide() {{ gtd_show_energy_schedule_guide "$@"; }}
show_note_packets_guide() {{ gtd_show_note_packets_guide "$@"; }}
show_connect_notes_guide() {{ gtd_show_connect_notes_guide "$@"; }}
show_converge_notes_guide() {{ gtd_show_converge_notes_guide "$@"; }}
show_discover_connections_guide() {{ gtd_show_discover_connections_guide "$@"; }}
show_distill_guide() {{ gtd_show_distill_guide "$@"; }}
show_diverge_guide() {{ gtd_show_diverge_guide "$@"; }}
show_evergreen_notes_guide() {{ gtd_show_evergreen_notes_guide "$@"; }}

# Execute the function
{function_name}

# After completion, automatically restart TUI
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Returning to TUI..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 1

# Restart the TUI
exec python3 "{tui_script}"
""")
            temp_script.close()
            os.chmod(temp_script.name, 0o755)
            
            # Show brief message before exiting
            self.notify(
                f"Launching: {item.title}",
                title="GTD Wizard",
                timeout=1
            )
            
            # Exit and run the script
            # The script will automatically restart the TUI when done
            os.execv("/bin/bash", ["/bin/bash", temp_script.name])
                
        except Exception as e:
            self.notify(f"Error executing {item.title}: {str(e)}", severity="error")

    def on_input_changed(self, event: Input.Changed) -> None:
        """Handle search input changes"""
        self.current_filter = event.value.lower()
        self.filter_menu()

    def filter_menu(self):
        """Filter menu items based on search"""
        if not self.current_filter:
            self.filtered_items = self.menu_items.copy()
        else:
            self.filtered_items = [
                item for item in self.menu_items
                if self.current_filter in item.title.lower() or
                   self.current_filter in item.number or
                   self.current_filter in item.emoji
            ]
        # Schedule the async update after refresh
        self.call_after_refresh(self._do_update_menu_display)
    
    async def _do_update_menu_display(self):
        """Internal async wrapper for update_menu_display"""
        await self.update_menu_display()

    def action_focus_search(self):
        """Focus the search input"""
        self.query_one("#search-input", Input).focus()

    def action_clear_search(self):
        """Clear the search"""
        search_input = self.query_one("#search-input", Input)
        search_input.value = ""
        self.current_filter = ""
        self.filter_menu()
        self.query_one("#menu-list", ListView).focus()

    def action_refresh(self):
        """Refresh the status and menu"""
        self.refresh_status()
        self.load_menu_structure()
        self.filter_menu()
        self.notify("Refreshed", title="GTD Wizard")

    def action_help(self):
        """Show help"""
        help_text = """
[bold]GTD Wizard TUI - Keyboard Shortcuts[/bold]

[cyan]Navigation:[/cyan]
  ↑/↓     - Navigate menu
  Enter   - Select item
  q       - Quit
  f       - Focus search
  Esc     - Clear search
  r       - Refresh
  ?       - Show this help

[cyan]Search:[/cyan]
  Type to filter menu items
  Search matches title, number, and emoji
        """
        self.notify(help_text, title="Help", timeout=10)

    def action_quit(self):
        """Quit the application"""
        self.exit()


def main():
    """Main entry point"""
    app = GTDWizardTUI()
    app.run()


if __name__ == "__main__":
    main()
