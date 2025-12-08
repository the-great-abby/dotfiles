#!/bin/bash
# GTD Wizard Second Brain Functions
# Second Brain wizards for CODE method operations

sync_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🧠 Second Brain Sync Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  show_sync_guide
  echo "What would you like to sync?"
  echo ""
  echo "  1) Full sync (projects, areas, references, daily logs)"
  echo "  2) Projects only"
  echo "  3) Areas only"
  echo "  4) References only"
  echo "  5) Daily logs only"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read sync_choice
  
  case "$sync_choice" in
    1)
      gtd-brain-sync
      ;;
    2)
      gtd-brain-sync projects
      ;;
    3)
      gtd-brain-sync areas
      ;;
    4)
      gtd-brain-sync references
      ;;
    5)
      gtd-brain-sync daily-logs
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

bidirectional_sync_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🔄 Bidirectional Obsidian Sync${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Sync changes made in Obsidian (mobile/other computers) back to your system."
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 🔄 Full bidirectional sync (detect & sync all changes)"
  echo "  2) 📝 Sync daily logs only (pull from Obsidian)"
  echo "  3) 🔍 Detect changes in Obsidian (last 7 days)"
  echo "  4) 📊 Show sync status"
  echo "  5) 🔧 Resolve conflicts"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read sync_choice
  
  case "$sync_choice" in
    1)
      if command -v gtd-brain-bidirectional-sync &>/dev/null; then
        gtd-brain-bidirectional-sync sync
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" sync
      else
        echo "❌ gtd-brain-bidirectional-sync command not found"
      fi
      ;;
    2)
      if command -v gtd-brain-bidirectional-sync &>/dev/null; then
        gtd-brain-bidirectional-sync sync-daily-logs
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" sync-daily-logs
      else
        echo "❌ gtd-brain-bidirectional-sync command not found"
      fi
      ;;
    3)
      echo ""
      echo "How many days back to check?"
      echo -n "Days (default: 7): "
      read days_back
      days_back="${days_back:-7}"
      if command -v gtd-brain-bidirectional-sync &>/dev/null; then
        gtd-brain-bidirectional-sync detect-changes "$days_back"
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" detect-changes "$days_back"
      else
        echo "❌ gtd-brain-bidirectional-sync command not found"
      fi
      ;;
    4)
      if command -v gtd-brain-bidirectional-sync &>/dev/null; then
        gtd-brain-bidirectional-sync status
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" status
      else
        echo "❌ gtd-brain-bidirectional-sync command not found"
      fi
      ;;
    5)
      if command -v gtd-brain-bidirectional-sync &>/dev/null; then
        gtd-brain-bidirectional-sync resolve
      elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" ]]; then
        "$HOME/code/dotfiles/bin/gtd-brain-bidirectional-sync" resolve
      else
        echo "❌ gtd-brain-bidirectional-sync command not found"
      fi
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
  echo "Press Enter to continue..."
  read
}

brain_connect_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_connect_notes_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Create connection between two notes"
    echo "  2) Auto-detect potential connections for a note"
    echo "  3) List all connection notes"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read connect_choice
    
    case "$connect_choice" in
      1)
        echo ""
        echo -n "First note (path or filename): "
        read note1
        echo -n "Second note (path or filename): "
        read note2
        echo -n "Connection title (optional, press Enter to auto-generate): "
        read title
        
        if [[ -z "$note1" || -z "$note2" ]]; then
          echo "❌ Both notes are required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-connect &>/dev/null; then
          if [[ -n "$title" ]]; then
            gtd-brain-connect create "$note1" "$note2" "$title"
          else
            gtd-brain-connect create "$note1" "$note2"
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-connect" ]]; then
          if [[ -n "$title" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-connect" create "$note1" "$note2" "$title"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-connect" create "$note1" "$note2"
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" ]]; then
          if [[ -n "$title" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" create "$note1" "$note2" "$title"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" create "$note1" "$note2"
          fi
        else
          echo "❌ gtd-brain-connect command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        echo -n "Note path or filename to analyze: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-connect &>/dev/null; then
          gtd-brain-connect detect "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-connect" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-connect" detect "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" detect "$note_path"
        else
          echo "❌ gtd-brain-connect command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        echo ""
        if command -v gtd-brain-connect &>/dev/null; then
          gtd-brain-connect list
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-connect" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-connect" list
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-connect" list
        else
          echo "❌ gtd-brain-connect command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_converge_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_converge_notes_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Start convergence from divergence session"
    echo "  2) List all convergence sessions"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read converge_choice
    
    case "$converge_choice" in
      1)
        echo ""
        echo -n "Divergence session file (path or filename): "
        read divergence_file
        
        if [[ -z "$divergence_file" ]]; then
          echo "❌ Divergence file is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-converge &>/dev/null; then
          gtd-brain-converge "$divergence_file"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-converge" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-converge" "$divergence_file"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-converge" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-converge" "$divergence_file"
        else
          echo "❌ gtd-brain-converge command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        if command -v gtd-brain-converge &>/dev/null; then
          gtd-brain-converge list
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-converge" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-converge" list
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-converge" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-converge" list
        else
          echo "❌ gtd-brain-converge command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_discover_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_discover_connections_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Find notes by tag"
    echo "  2) Find orphaned notes (no connections)"
    echo "  3) Find similar notes"
    echo "  4) Find notes by date range"
    echo "  5) Show connection graph for a note"
    echo "  6) Show Second Brain statistics"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read discover_choice
    
    case "$discover_choice" in
      1)
        echo ""
        echo -n "Tag to search for: "
        read tag
        
        if [[ -z "$tag" ]]; then
          echo "❌ Tag is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-discover &>/dev/null; then
          gtd-brain-discover tag "$tag"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-discover" tag "$tag"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" tag "$tag"
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        if command -v gtd-brain-discover &>/dev/null; then
          gtd-brain-discover orphan
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-discover" orphan
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" orphan
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        echo -n "Minimum matching terms (default 3, press Enter for default): "
        read min_terms
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-discover &>/dev/null; then
          if [[ -n "$min_terms" ]]; then
            gtd-brain-discover similar "$note_path" "$min_terms"
          else
            gtd-brain-discover similar "$note_path"
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          if [[ -n "$min_terms" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-discover" similar "$note_path" "$min_terms"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-discover" similar "$note_path"
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          if [[ -n "$min_terms" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" similar "$note_path" "$min_terms"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" similar "$note_path"
          fi
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      4)
        echo ""
        echo -n "Start date (YYYY-MM-DD): "
        read start_date
        echo -n "End date (YYYY-MM-DD, optional, press Enter for today): "
        read end_date
        
        if [[ -z "$start_date" ]]; then
          echo "❌ Start date is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-discover &>/dev/null; then
          if [[ -n "$end_date" ]]; then
            gtd-brain-discover date "$start_date" "$end_date"
          else
            gtd-brain-discover date "$start_date"
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          if [[ -n "$end_date" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-discover" date "$start_date" "$end_date"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-discover" date "$start_date"
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          if [[ -n "$end_date" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" date "$start_date" "$end_date"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" date "$start_date"
          fi
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      5)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-discover &>/dev/null; then
          gtd-brain-discover connections "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-discover" connections "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" connections "$note_path"
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      6)
        echo ""
        if command -v gtd-brain-discover &>/dev/null; then
          gtd-brain-discover stats
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-discover" stats
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-discover" stats
        else
          echo "❌ gtd-brain-discover command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_distill_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_distill_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Start distill workflow for a note"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read distill_choice
    
    case "$distill_choice" in
      1)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-distill &>/dev/null; then
          gtd-brain-distill "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-distill" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-distill" "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-distill" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-distill" "$note_path"
        else
          echo "❌ gtd-brain-distill command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_diverge_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_diverge_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Start divergence session for a topic"
    echo "  2) List all divergence sessions"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read diverge_choice
    
    case "$diverge_choice" in
      1)
        echo ""
        echo -n "Topic to brainstorm: "
        read topic
        
        if [[ -z "$topic" ]]; then
          echo "❌ Topic is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-diverge &>/dev/null; then
          gtd-brain-diverge "$topic"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-diverge" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-diverge" "$topic"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-diverge" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-diverge" "$topic"
        else
          echo "❌ gtd-brain-diverge command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        if command -v gtd-brain-diverge &>/dev/null; then
          gtd-brain-diverge list
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-diverge" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-diverge" list
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-diverge" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-diverge" list
        else
          echo "❌ gtd-brain-diverge command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_evergreen_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_evergreen_notes_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Mark note as evergreen"
    echo "  2) List all evergreen notes"
    echo "  3) Refine an evergreen note"
    echo "  4) Show connections for evergreen note"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read evergreen_choice
    
    case "$evergreen_choice" in
      1)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-evergreen &>/dev/null; then
          gtd-brain-evergreen mark "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-evergreen" mark "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" mark "$note_path"
        else
          echo "❌ gtd-brain-evergreen command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        if command -v gtd-brain-evergreen &>/dev/null; then
          gtd-brain-evergreen list
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-evergreen" list
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" list
        else
          echo "❌ gtd-brain-evergreen command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-evergreen &>/dev/null; then
          gtd-brain-evergreen refine "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-evergreen" refine "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" refine "$note_path"
        else
          echo "❌ gtd-brain-evergreen command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      4)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        
        if [[ -z "$note_path" ]]; then
          echo "❌ Note path is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-evergreen &>/dev/null; then
          gtd-brain-evergreen connections "$note_path"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-evergreen" connections "$note_path"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-evergreen" connections "$note_path"
        else
          echo "❌ gtd-brain-evergreen command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

brain_packet_wizard() {
  push_menu "Main Menu"
  
  while true; do
    clear
    show_breadcrumb
    echo ""
    show_note_packets_guide
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Create packet from note"
    echo "  2) List all packets"
    echo "  3) View a specific packet"
    echo "  4) Use packet (copy to destination)"
    echo "  5) Assemble multiple packets into one"
    echo ""
    echo -e "${YELLOW}0)${NC} Back to Main Menu"
    echo ""
    echo -n "Choose: "
    read packet_choice
    
    case "$packet_choice" in
      1)
        echo ""
        echo -n "Note path or filename: "
        read note_path
        echo -n "Packet name: "
        read packet_name
        echo "Packet types: template, checklist, code-snippet, design-pattern,"
        echo "              meeting-notes, project-kickoff, weekly-review"
        echo -n "Packet type (optional, press Enter to skip): "
        read packet_type
        
        if [[ -z "$note_path" || -z "$packet_name" ]]; then
          echo "❌ Note path and packet name are required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-packet &>/dev/null; then
          if [[ -n "$packet_type" ]]; then
            gtd-brain-packet create "$note_path" "$packet_name" "$packet_type"
          else
            gtd-brain-packet create "$note_path" "$packet_name"
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$packet_type" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-packet" create "$note_path" "$packet_name" "$packet_type"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-packet" create "$note_path" "$packet_name"
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$packet_type" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" create "$note_path" "$packet_name" "$packet_type"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" create "$note_path" "$packet_name"
          fi
        else
          echo "❌ gtd-brain-packet command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      2)
        echo ""
        echo "Filter by type? (optional, press Enter to list all)"
        echo "Types: template, checklist, code-snippet, design-pattern,"
        echo "       meeting-notes, project-kickoff, weekly-review"
        echo -n "Type (or press Enter for all): "
        read filter_type
        
        if command -v gtd-brain-packet &>/dev/null; then
          if [[ -n "$filter_type" ]]; then
            gtd-brain-packet list "$filter_type"
          else
            gtd-brain-packet list
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$filter_type" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-packet" list "$filter_type"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-packet" list
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$filter_type" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" list "$filter_type"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" list
          fi
        else
          echo "❌ gtd-brain-packet command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      3)
        echo ""
        echo -n "Packet name: "
        read packet_name
        
        if [[ -z "$packet_name" ]]; then
          echo "❌ Packet name is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-packet &>/dev/null; then
          gtd-brain-packet view "$packet_name"
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-packet" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-packet" view "$packet_name"
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" view "$packet_name"
        else
          echo "❌ gtd-brain-packet command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      4)
        echo ""
        echo -n "Packet name: "
        read packet_name
        echo -n "Destination path (optional, press Enter to use default): "
        read dest_path
        
        if [[ -z "$packet_name" ]]; then
          echo "❌ Packet name is required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-packet &>/dev/null; then
          if [[ -n "$dest_path" ]]; then
            gtd-brain-packet use "$packet_name" "$dest_path"
          else
            gtd-brain-packet use "$packet_name"
          fi
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$dest_path" ]]; then
            "$HOME/code/dotfiles/bin/gtd-brain-packet" use "$packet_name" "$dest_path"
          else
            "$HOME/code/dotfiles/bin/gtd-brain-packet" use "$packet_name"
          fi
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" ]]; then
          if [[ -n "$dest_path" ]]; then
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" use "$packet_name" "$dest_path"
          else
            "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" use "$packet_name"
          fi
        else
          echo "❌ gtd-brain-packet command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      5)
        echo ""
        echo -n "Assembled packet name: "
        read assembled_name
        echo -n "Packet names to assemble (space-separated): "
        read packet_names
        
        if [[ -z "$assembled_name" || -z "$packet_names" ]]; then
          echo "❌ Assembled name and packet names are required"
          echo ""
          echo "Press Enter to continue..."
          read
          continue
        fi
        
        if command -v gtd-brain-packet &>/dev/null; then
          gtd-brain-packet assemble "$assembled_name" $packet_names
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-brain-packet" ]]; then
          "$HOME/code/dotfiles/bin/gtd-brain-packet" assemble "$assembled_name" $packet_names
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-brain-packet" assemble "$assembled_name" $packet_names
        else
          echo "❌ gtd-brain-packet command not found"
        fi
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
      0|"")
        pop_menu
        return 0
        ;;
      *)
        echo "Invalid choice"
        echo ""
        echo "Press Enter to continue..."
        read
        ;;
    esac
  done
}

