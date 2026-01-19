#!/bin/bash
# GTD Wizard Core Functions
# Core dashboard, menu, and navigation functions for the wizard

# ============================================================================
# Computer Mode Functions
# ============================================================================

# Get current computer mode (work/home)
get_computer_mode() {
  # Load config if not already loaded
  if [[ -z "${GTD_COMPUTER_MODE:-}" ]]; then
    local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    if [[ ! -f "$gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      source "$gtd_config" 2>/dev/null || true
    fi
  fi
  
  echo "${GTD_COMPUTER_MODE:-home}"
}

# Apply mode-specific settings (directories and feature flags)
apply_mode_settings() {
  local mode="$1"
  local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
  
  # Load configs
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  local daily_log_config="$HOME/code/dotfiles/zsh/.daily_log_config"
  if [[ ! -f "$daily_log_config" ]]; then
    daily_log_config="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  
  local db_config="$HOME/code/dotfiles/zsh/.gtd_config_database"
  if [[ ! -f "$db_config" ]]; then
    db_config="$HOME/code/personal/dotfiles/zsh/.gtd_config_database"
  fi
  
  if [[ -f "$gtd_config" ]]; then
    source "$gtd_config" 2>/dev/null || true
  fi
  if [[ -f "$daily_log_config" ]]; then
    source "$daily_log_config" 2>/dev/null || true
  fi
  if [[ -f "$db_config" ]]; then
    source "$db_config" 2>/dev/null || true
  fi
  
  local is_macos=""
  if [[ "$(uname)" == "Darwin" ]]; then
    is_macos="true"
  fi
  
  # Apply mode-specific DAILY_LOG_DIR if it exists
  # Read directly from config file to preserve $HOME variable (don't use sourced value which expands it)
  local mode_daily_log_var="DAILY_LOG_DIR_${mode_upper}"
  local mode_daily_log_value=$(grep "^${mode_daily_log_var}=" "$daily_log_config" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
  if [[ -n "$mode_daily_log_value" ]]; then
    # Update active DAILY_LOG_DIR in daily_log_config (preserve $HOME if present)
    if grep -q "^DAILY_LOG_DIR=" "$daily_log_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"$mode_daily_log_value\"|" "$daily_log_config"
      else
        sed -i "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"$mode_daily_log_value\"|" "$daily_log_config"
      fi
    else
      # Add it
      echo "DAILY_LOG_DIR=\"$mode_daily_log_value\"" >> "$daily_log_config"
    fi
    # Expand for export (bash will expand $HOME when exporting)
    local expanded_value=$(echo "$mode_daily_log_value" | sed "s|\$HOME|$HOME|g")
    export DAILY_LOG_DIR="$expanded_value"
  fi
  
  # Apply mode-specific GTD_BASE_DIR if it exists
  # Read directly from config file to preserve $HOME variable (don't use sourced value which expands it)
  local mode_gtd_base_var="GTD_BASE_DIR_${mode_upper}"
  local mode_gtd_base_value=$(grep "^${mode_gtd_base_var}=" "$gtd_config" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
  if [[ -n "$mode_gtd_base_value" ]]; then
    # Update active GTD_BASE_DIR in gtd_config (preserve $HOME if present)
    if grep -q "^GTD_BASE_DIR=" "$gtd_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"$mode_gtd_base_value\"|" "$gtd_config"
      else
        sed -i "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"$mode_gtd_base_value\"|" "$gtd_config"
      fi
    else
      # Add it after Directory Structure comment
      if grep -q "^# Directory Structure" "$gtd_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "/^# Directory Structure/a\\
GTD_BASE_DIR=\"$mode_gtd_base_value\"
" "$gtd_config"
        else
          sed -i "/^# Directory Structure/a GTD_BASE_DIR=\"$mode_gtd_base_value\"" "$gtd_config"
        fi
      else
        echo "GTD_BASE_DIR=\"$mode_gtd_base_value\"" >> "$gtd_config"
      fi
    fi
    # Expand for export (bash will expand $HOME when exporting)
    local expanded_value=$(echo "$mode_gtd_base_value" | sed "s|\$HOME|$HOME|g")
    export GTD_BASE_DIR="$expanded_value"
  fi
  
  # Apply mode-specific SECOND_BRAIN if it exists
  # Read directly from config file to preserve $HOME variable (don't use sourced value which expands it)
  local mode_second_brain_var="SECOND_BRAIN_${mode_upper}"
  local mode_second_brain_value=$(grep "^${mode_second_brain_var}=" "$gtd_config" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | xargs)
  if [[ -n "$mode_second_brain_value" ]]; then
    # Update active SECOND_BRAIN in gtd_config (preserve $HOME if present)
    if grep -q "^SECOND_BRAIN=" "$gtd_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"$mode_second_brain_value\"|" "$gtd_config"
      else
        sed -i "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"$mode_second_brain_value\"|" "$gtd_config"
      fi
    else
      # Add it after Second Brain Integration comment
      if grep -q "^# Second Brain Integration" "$gtd_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "/^# Second Brain Integration/a\\
SECOND_BRAIN=\"$mode_second_brain_value\"
" "$gtd_config"
        else
          sed -i "/^# Second Brain Integration/a SECOND_BRAIN=\"$mode_second_brain_value\"" "$gtd_config"
        fi
      else
        echo "SECOND_BRAIN=\"$mode_second_brain_value\"" >> "$gtd_config"
      fi
    fi
    # Expand for export (bash will expand $HOME when exporting)
    local expanded_value=$(echo "$mode_second_brain_value" | sed "s|\$HOME|$HOME|g")
    export SECOND_BRAIN="$expanded_value"
  fi
  
  # Note: Mode-specific settings (GTD_VECTORIZATION_ENABLED_WORK, etc.) are now read
  # dynamically from .gtd_config by the Python and bash scripts based on GTD_COMPUTER_MODE.
  # We no longer write them to .gtd_config_database to avoid sync conflicts.
  # The read_database_config() function in Python and bash scripts check for mode-specific
  # variables first, then fall back to .gtd_config_database values.
  
  # Apply mode-specific Vector Database and RabbitMQ connection settings to .gtd_config_database
  # if the file exists (these are connection settings, not feature flags)
  local db_config="$HOME/code/dotfiles/zsh/.gtd_config_database"
  if [[ ! -f "$db_config" ]]; then
    db_config="$HOME/code/personal/dotfiles/zsh/.gtd_config_database"
  fi
  
  if [[ -f "$db_config" ]]; then
    # Apply mode-specific Vector Database connection settings
    local vector_db_settings=(
      "VECTOR_DB_HOST"
      "VECTOR_DB_PORT"
      "VECTOR_DB_NAME"
      "VECTOR_DB_USER"
      "VECTOR_DB_PASSWORD"
    )
    
    for setting in "${vector_db_settings[@]}"; do
      local mode_setting="${setting}_${mode_upper}"
      if [[ -n "${!mode_setting:-}" ]]; then
        local setting_value="${!mode_setting}"
        # Update or add the setting
        if grep -q "^${setting}=" "$db_config" 2>/dev/null; then
          # Use perl for safer replacement that handles special characters
          if command -v perl &>/dev/null; then
            perl -i -pe "s|^${setting}=.*|${setting}=\"${setting_value}\"|" "$db_config" 2>/dev/null
          else
            # Fallback to sed with pipe delimiter and basic escaping
            local escaped_value=$(echo "$setting_value" | sed 's/|/\\|/g')
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s|^${setting}=.*|${setting}=\"${escaped_value}\"|" "$db_config"
            else
              sed -i "s|^${setting}=.*|${setting}=\"${escaped_value}\"|" "$db_config"
            fi
          fi
        else
          # Add it after Vector Database Configuration comment if found
          if grep -q "^# Vector Database Configuration" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "/^# Vector Database Configuration/a\\
${setting}=\"${setting_value}\"
" "$db_config"
            else
              sed -i "/^# Vector Database Configuration/a ${setting}=\"${setting_value}\"" "$db_config"
            fi
          else
            echo "${setting}=\"${setting_value}\"" >> "$db_config"
          fi
        fi
      fi
    done
    
    # Apply mode-specific RabbitMQ connection settings
    local rabbitmq_settings=(
      "RABBITMQ_URL"
      "RABBITMQ_USER"
      "RABBITMQ_PASS"
    )
    
    for setting in "${rabbitmq_settings[@]}"; do
      local mode_setting="${setting}_${mode_upper}"
      if [[ -n "${!mode_setting:-}" ]]; then
        local setting_value="${!mode_setting}"
        # Update or add the setting
        if grep -q "^${setting}=" "$db_config" 2>/dev/null; then
          # Use perl for safer replacement that handles special characters
          if command -v perl &>/dev/null; then
            perl -i -pe "s|^${setting}=.*|${setting}=\"${setting_value}\"|" "$db_config" 2>/dev/null
          else
            # Fallback to sed with pipe delimiter and basic escaping
            local escaped_value=$(echo "$setting_value" | sed 's/|/\\|/g')
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s|^${setting}=.*|${setting}=\"${escaped_value}\"|" "$db_config"
            else
              sed -i "s|^${setting}=.*|${setting}=\"${escaped_value}\"|" "$db_config"
            fi
          fi
        else
          # Add it after RabbitMQ Configuration comment if found
          if grep -q "^# RabbitMQ Configuration" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "/^# RabbitMQ Configuration/a\\
${setting}=\"${setting_value}\"
" "$db_config"
            else
              sed -i "/^# RabbitMQ Configuration/a ${setting}=\"${setting_value}\"" "$db_config"
            fi
          else
            echo "${setting}=\"${setting_value}\"" >> "$db_config"
          fi
        fi
      fi
    done
  fi
}

# Legacy function name for backward compatibility
apply_mode_directories() {
  apply_mode_settings "$@"
}

# Set computer mode (work/home)
set_computer_mode() {
  local mode="${1:-}"
  
  if [[ -z "$mode" ]]; then
    echo "Usage: set_computer_mode <work|home>" >&2
    return 1
  fi
  
  if [[ "$mode" != "work" && "$mode" != "home" ]]; then
    gtd_feedback error "Mode must be 'work' or 'home'"
    return 1
  fi
  
  # Update config file
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  if [[ -f "$gtd_config" ]]; then
    # Update or add the setting
    if grep -q "^GTD_COMPUTER_MODE=" "$gtd_config" 2>/dev/null; then
      # Update existing line
      if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$mode\"/" "$gtd_config"
      else
        sed -i "s/^GTD_COMPUTER_MODE=.*/GTD_COMPUTER_MODE=\"$mode\"/" "$gtd_config"
      fi
    else
      # Add new line after GTD_USER_NAME
      if grep -q "^GTD_USER_NAME=" "$gtd_config" 2>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
          sed -i '' "/^GTD_USER_NAME=.*/a\\
GTD_COMPUTER_MODE=\"$mode\"
" "$gtd_config"
        else
          sed -i "/^GTD_USER_NAME=.*/a GTD_COMPUTER_MODE=\"$mode\"" "$gtd_config"
        fi
      else
        # Just append to file
        echo "GTD_COMPUTER_MODE=\"$mode\"" >> "$gtd_config"
      fi
    fi
    
    # Update current session
    export GTD_COMPUTER_MODE="$mode"
    echo "Computer mode set to: $mode"
    
    # Apply mode-specific settings (directories and feature flags)
    # This will check for mode-specific variables first (e.g., GTD_VECTORIZATION_ENABLED_WORK)
    # and apply them, otherwise fall back to defaults
    apply_mode_settings "$mode"
    
    # Update RabbitMQ and background processing settings in .gtd_config_database
    # Only if mode-specific variables don't exist (fallback to hardcoded defaults)
    local db_config="$HOME/code/dotfiles/zsh/.gtd_config_database"
    if [[ ! -f "$db_config" ]]; then
      db_config="$HOME/code/personal/dotfiles/zsh/.gtd_config_database"
    fi
    
    if [[ -f "$db_config" ]]; then
      local is_macos=""
      if [[ "$(uname)" == "Darwin" ]]; then
        is_macos="true"
      fi
      
      # Check if mode-specific variables exist - if so, they were already applied by apply_mode_settings
      # Otherwise, use hardcoded defaults
      local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
      local mode_vectorization="GTD_VECTORIZATION_ENABLED_${mode_upper}"
      local mode_rabbitmq="RABBITMQ_ENABLED_${mode_upper}"
      
      # Load config to check for mode-specific variables
      source "$gtd_config" 2>/dev/null || true
      if [[ -f "$db_config" ]]; then
        source "$db_config" 2>/dev/null || true
      fi
      
      # Only apply defaults if mode-specific variables don't exist
      if [[ -z "${!mode_vectorization:-}" && -z "${!mode_rabbitmq:-}" ]]; then
        if [[ "$mode" == "work" ]]; then
          # Work mode: Disable RabbitMQ and AI/background processing features (default)
          echo "  Disabling RabbitMQ and background processing for work mode..."
          
          # Disable RabbitMQ
          if grep -q "^RABBITMQ_ENABLED=" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=false/" "$db_config"
            else
              sed -i "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=false/" "$db_config"
            fi
          else
            # Add after RABBITMQ_URL line if found, otherwise append
            if grep -q "^RABBITMQ_URL=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "/^RABBITMQ_URL=/a\\
RABBITMQ_ENABLED=false
" "$db_config"
              else
                sed -i "/^RABBITMQ_URL=/a RABBITMQ_ENABLED=false" "$db_config"
              fi
            else
              echo "RABBITMQ_ENABLED=false" >> "$db_config"
            fi
          fi
          
          # Disable vectorization
          if grep -q "^GTD_VECTORIZATION_ENABLED=" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=false/" "$db_config"
            else
              sed -i "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=false/" "$db_config"
            fi
          fi
        
        # Disable auto-vectorization
        if grep -q "^VECTORIZE_ON_CREATE=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^VECTORIZE_ON_CREATE=.*/VECTORIZE_ON_CREATE=false/" "$db_config"
          else
            sed -i "s/^VECTORIZE_ON_CREATE=.*/VECTORIZE_ON_CREATE=false/" "$db_config"
          fi
        fi
        if grep -q "^VECTORIZE_ON_UPDATE=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^VECTORIZE_ON_UPDATE=.*/VECTORIZE_ON_UPDATE=false/" "$db_config"
          else
            sed -i "s/^VECTORIZE_ON_UPDATE=.*/VECTORIZE_ON_UPDATE=false/" "$db_config"
          fi
        fi
        
        # Disable filewatcher
        if grep -q "^VECTOR_FILEWATCHER_ENABLED=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=false/" "$db_config"
          else
            sed -i "s/^VECTOR_FILEWATCHER_ENABLED=.*/VECTOR_FILEWATCHER_ENABLED=false/" "$db_config"
          fi
        fi
        
        # Disable deep analysis triggers
        if grep -q "^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=.*/DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=false/" "$db_config"
          else
            sed -i "s/^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=.*/DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=false/" "$db_config"
          fi
        fi
        if grep -q "^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=.*/DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=false/" "$db_config"
          else
            sed -i "s/^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=.*/DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=false/" "$db_config"
          fi
        fi
        if grep -q "^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=.*/DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=false/" "$db_config"
          else
            sed -i "s/^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=.*/DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=false/" "$db_config"
          fi
        fi
        
        # Disable auto deep analysis scheduling
        if grep -q "^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=.*/DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=false/" "$db_config"
          else
            sed -i "s/^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=.*/DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=false/" "$db_config"
          fi
        fi
        if grep -q "^DEEP_ANALYSIS_AUTO_ENERGY=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "s/^DEEP_ANALYSIS_AUTO_ENERGY=.*/DEEP_ANALYSIS_AUTO_ENERGY=false/" "$db_config"
          else
            sed -i "s/^DEEP_ANALYSIS_AUTO_ENERGY=.*/DEEP_ANALYSIS_AUTO_ENERGY=false/" "$db_config"
          fi
        fi
        
        echo "  ✓ RabbitMQ and background processing disabled"
      else
          # Home mode: Enable RabbitMQ and AI/background processing features (default)
          echo "  Enabling RabbitMQ and background processing for home mode..."
          
          # Enable RabbitMQ
          if grep -q "^RABBITMQ_ENABLED=" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=true/" "$db_config"
            else
              sed -i "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=true/" "$db_config"
            fi
          else
            # Add after RABBITMQ_URL line if found, otherwise append
            if grep -q "^RABBITMQ_URL=" "$db_config" 2>/dev/null; then
              if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/^RABBITMQ_URL=/a\\
RABBITMQ_ENABLED=true
" "$db_config"
              else
                sed -i "/^RABBITMQ_URL=/a RABBITMQ_ENABLED=true" "$db_config"
              fi
            else
              echo "RABBITMQ_ENABLED=true" >> "$db_config"
            fi
          fi
          
          # Enable vectorization
          if grep -q "^GTD_VECTORIZATION_ENABLED=" "$db_config" 2>/dev/null; then
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=true/" "$db_config"
            else
              sed -i "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=true/" "$db_config"
            fi
          fi
          
          # Enable auto-vectorization (only if mode-specific variables don't exist)
          if [[ -z "${!mode_vectorization:-}" ]]; then
            if grep -q "^VECTORIZE_ON_CREATE=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^VECTORIZE_ON_CREATE=.*/VECTORIZE_ON_CREATE=true/" "$db_config"
              else
                sed -i "s/^VECTORIZE_ON_CREATE=.*/VECTORIZE_ON_CREATE=true/" "$db_config"
              fi
            fi
            if grep -q "^VECTORIZE_ON_UPDATE=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^VECTORIZE_ON_UPDATE=.*/VECTORIZE_ON_UPDATE=true/" "$db_config"
              else
                sed -i "s/^VECTORIZE_ON_UPDATE=.*/VECTORIZE_ON_UPDATE=true/" "$db_config"
              fi
            fi
          fi
          
          # Enable filewatcher (optional, keep current setting)
          # VECTOR_FILEWATCHER_ENABLED is typically false by default, so we won't force enable it
          
          # Enable deep analysis triggers (only if mode-specific variables don't exist)
          if [[ -z "${!mode_vectorization:-}" ]]; then
            if grep -q "^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=.*/DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=true/" "$db_config"
              else
                sed -i "s/^DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=.*/DEEP_ANALYSIS_TRIGGER_ENERGY_ON_LOG=true/" "$db_config"
              fi
            fi
            if grep -q "^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=.*/DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=true/" "$db_config"
              else
                sed -i "s/^DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=.*/DEEP_ANALYSIS_TRIGGER_INSIGHTS_ON_CONTENT=true/" "$db_config"
              fi
            fi
            if grep -q "^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=.*/DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=true/" "$db_config"
              else
                sed -i "s/^DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=.*/DEEP_ANALYSIS_TRIGGER_CONNECTIONS_ON_TASK=true/" "$db_config"
              fi
            fi
            
            # Enable auto deep analysis scheduling
            if grep -q "^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=.*/DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=true/" "$db_config"
              else
                sed -i "s/^DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=.*/DEEP_ANALYSIS_AUTO_WEEKLY_REVIEW=true/" "$db_config"
              fi
            fi
            if grep -q "^DEEP_ANALYSIS_AUTO_ENERGY=" "$db_config" 2>/dev/null; then
              if [[ -n "$is_macos" ]]; then
                sed -i '' "s/^DEEP_ANALYSIS_AUTO_ENERGY=.*/DEEP_ANALYSIS_AUTO_ENERGY=true/" "$db_config"
              else
                sed -i "s/^DEEP_ANALYSIS_AUTO_ENERGY=.*/DEEP_ANALYSIS_AUTO_ENERGY=true/" "$db_config"
              fi
            fi
          fi
          
          echo "  ✓ RabbitMQ and background processing enabled"
        fi
      fi
    else
      echo "  Note: .gtd_config_database not found, skipping RabbitMQ/background processing updates"
    fi
    
    return 0
  else
    gtd_feedback error "Config file not found: $gtd_config"
    return 1
  fi
}

# ============================================================================
# Smart Defaults Functions
# ============================================================================

# Auto-detect time of day (morning/afternoon/evening)
get_time_of_day() {
  local hour=$(date +"%H" 2>/dev/null || echo "12")
  hour=$((10#$hour))  # Force base 10 interpretation
  
  if [[ $hour -ge 5 && $hour -lt 12 ]]; then
    echo "morning"
  elif [[ $hour -ge 12 && $hour -lt 17 ]]; then
    echo "afternoon"
  elif [[ $hour -ge 17 && $hour -lt 21 ]]; then
    echo "evening"
  else
    echo "evening"  # Default to evening for late night
  fi
}

# Check if morning check-in was done today
checkin_done_today() {
  local checkin_type="${1:-morning}"  # morning or evening
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  
  if [[ ! -f "$today_log" ]]; then
    return 1  # No log file = no check-in
  fi
  
  # Check for check-in markers in daily log
  if [[ "$checkin_type" == "morning" ]]; then
    # Look for morning check-in patterns
    if grep -qiE "(morning check-in|morning checkin|🌅|morning intentions|top 3 priorities for today)" "$today_log" 2>/dev/null; then
      return 0
    fi
  else
    # Look for evening check-in patterns
    if grep -qiE "(evening check-in|evening checkin|🌙|evening reflection|what did i accomplish)" "$today_log" 2>/dev/null; then
      return 0
    fi
  fi
  
  return 1
}

# Get day of week (0=Sunday, 1=Monday, etc.)
get_day_of_week() {
  date +"%w" 2>/dev/null || echo "0"
}

# Get day name (Monday, Tuesday, etc.)
get_day_name() {
  date +"%A" 2>/dev/null || echo ""
}

# Check if weekly review was done this week
weekly_review_done_this_week() {
  # Ensure GTD_BASE_DIR is set
  if [[ -z "${GTD_BASE_DIR:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    fi
  fi
  
  local weekly_reviews_dir="${GTD_BASE_DIR}/weekly-reviews"
  local this_week_start=$(date -v-monday +"%Y-%m-%d" 2>/dev/null || date -d "last monday" +"%Y-%m-%d" 2>/dev/null || date +"%Y-%m-%d")
  
  # Check if there's a review file created this week
  if [[ -d "$weekly_reviews_dir" ]]; then
    if find "$weekly_reviews_dir" -name "*.md" -newermt "$this_week_start" 2>/dev/null | grep -q .; then
      return 0  # Review found
    fi
  fi
  
  return 1  # No review found
}

# Count tasks completed today
tasks_completed_today() {
  # Ensure paths are initialized
  if [[ -z "${TASKS_PATH:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
      TASKS_PATH="${GTD_BASE_DIR}/tasks"
    fi
  fi
  
  local today=$(gtd_get_today)
  local tasks_path="${TASKS_PATH}"
  local count=0
  
  if [[ -d "$tasks_path" ]]; then
    # Look for tasks marked done/completed today
    while IFS= read -r task_file; do
      if [[ -f "$task_file" ]]; then
        # Check if task has completion date today
        if grep -qiE "(completed|done|finished).*${today}" "$task_file" 2>/dev/null; then
          ((count++))
        fi
      fi
    done < <(find "$tasks_path" -name "*.md" -type f 2>/dev/null)
  fi
  
  echo "$count"
}

# Check if feature is rarely used (should stop suggesting)
feature_rarely_used() {
  local feature_option="$1"
  local preferences_file="${HOME}/.gtd_preferences.json"
  
  if [[ ! -f "$preferences_file" ]]; then
    return 1  # No data = can't determine, so suggest it
  fi
  
  # Get usage count for this wizard option
  local usage_count=$(python3 2>/dev/null <<EOF
import json
from pathlib import Path

prefs_file = Path("$preferences_file")
if not prefs_file.exists():
    print("0")
    exit(0)

with open(prefs_file) as f:
    prefs = json.load(f)

option = "$feature_option"
wizard_options = prefs.get("feature_usage", {}).get("wizard_options", {})
count = wizard_options.get(option, 0)
print(count)
EOF
)
  
  # If used less than 3 times total, consider it rarely used
  if [[ "${usage_count:-0}" -lt 3 ]]; then
    return 0  # Rarely used
  fi
  
  return 1  # Used enough
}

# Check if feature is commonly used together with another
features_used_together() {
  local feature1="$1"
  local feature2="$2"
  
  # This would require more sophisticated tracking
  # For now, return false (not implemented yet)
  return 1
}

# Get smart default suggestions based on context
get_smart_defaults() {
  local time_of_day=$(get_time_of_day)
  local computer_mode=$(get_computer_mode)
  
  # Ensure paths are initialized
  if [[ -z "${INBOX_PATH:-}" ]]; then
    if command -v init_gtd_paths &>/dev/null; then
      init_gtd_paths
    else
      # Fallback initialization
      GTD_BASE_DIR="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
      INBOX_PATH="${GTD_BASE_DIR}/${GTD_INBOX_DIR:-0-inbox}"
    fi
  fi
  
  local inbox_count=0
  if [[ -d "${INBOX_PATH}" ]]; then
    inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  local today_entries=0
  if [[ -f "$today_log" ]]; then
    today_entries=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
  fi
  
  local suggestions=()
  local priorities=()
  
  # Get additional context
  local day_name=$(get_day_name)
  local day_of_week=$(get_day_of_week)
  local morning_checkin_done=false
  local evening_checkin_done=false
  local weekly_review_done=false
  local tasks_completed=0
  
  if checkin_done_today "morning"; then
    morning_checkin_done=true
  fi
  
  if checkin_done_today "evening"; then
    evening_checkin_done=true
  fi
  
  if weekly_review_done_this_week; then
    weekly_review_done=true
  fi
  
  tasks_completed=$(tasks_completed_today)
  
  # ============================================================================
  # Morning Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "morning" ]]; then
    # Haven't done check-in yet today → Suggest 19
    if [[ "$morning_checkin_done" == false ]]; then
      priorities+=("19|Morning Check-In|Start your day with intention")
    fi
    
    # Inbox not empty → Suggest 2 (process)
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|${inbox_count} item(s) waiting")
    fi
    
    # No log entries today → Suggest 15
    if [[ $today_entries -eq 0 ]]; then
      suggestions+=("15|Log to daily log|Start tracking your day")
    fi
    
    # Monday/Friday → Suggest 6 (weekly review prep/wrap)
    if [[ "$day_name" == "Monday" ]]; then
      if [[ "$weekly_review_done" == false ]]; then
        suggestions+=("6|Weekly Review|Plan your week")
      fi
    elif [[ "$day_name" == "Friday" ]]; then
      if [[ "$weekly_review_done" == false ]]; then
        suggestions+=("6|Weekly Review|Wrap up your week")
      fi
    fi
    
    # Always suggest capture in morning
    suggestions+=("1|Capture to inbox|Capture thoughts and ideas")
  fi
  
  # ============================================================================
  # Afternoon Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "afternoon" ]]; then
    suggestions+=("1|Capture to inbox|Capture thoughts and ideas")
    
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|${inbox_count} item(s) waiting")
    fi
    
    suggestions+=("40|What should I do now?|Get context-aware suggestions")
  fi
  
  # ============================================================================
  # Evening Context Logic
  # ============================================================================
  if [[ "$time_of_day" == "evening" ]]; then
    # Logged today but no evening check-in → Suggest 19
    if [[ $today_entries -gt 0 && "$evening_checkin_done" == false ]]; then
      priorities+=("19|Evening Check-In|Reflect on your day")
    elif [[ "$evening_checkin_done" == false ]]; then
      suggestions+=("19|Evening Check-In|Reflect on your day")
    fi
    
    # Tasks marked done today → Suggest 42 (celebrate)
    if [[ $tasks_completed -gt 0 ]]; then
      suggestions+=("42|Celebrate milestones|You completed ${tasks_completed} task(s) today!")
    fi
    
    # No weekly review this week → Remind gently
    if [[ "$weekly_review_done" == false ]]; then
      suggestions+=("6|Weekly Review|Haven't done weekly review yet this week")
    fi
    
    suggestions+=("6|Daily Review|Review accomplishments and plan tomorrow")
    
    if [[ $inbox_count -gt 0 ]]; then
      priorities+=("2|Process inbox|Clear ${inbox_count} item(s) before tomorrow")
    fi
  fi
  
  # ============================================================================
  # Background Jobs Ready for Review
  # ============================================================================
  # Check for pending suggestions (from option 24 - AI Suggestions & MCP Tools)
  local pending_suggestions_count=0
  local suggestions_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions"
  if [[ -d "$suggestions_dir" ]]; then
    # Count JSON files with status "pending"
    pending_suggestions_count=$(find "$suggestions_dir" -name "*.json" -type f 2>/dev/null | while read -r file; do
      if grep -q '"status":\s*"pending"' "$file" 2>/dev/null; then
        echo "1"
      fi
    done | wc -l | tr -d ' ')
  fi
  
  # Check for completed advice responses (from option 11 - Get advice)
  local completed_advice_count=0
  local advice_results_dir="$HOME/Documents/gtd/advice_results"
  if [[ -d "$advice_results_dir" ]]; then
    # Count JSON files with status "completed" (not error), excluding archived directory
    completed_advice_count=$(find "$advice_results_dir" -name "*.json" -type f -not -path "*/archived/*" 2>/dev/null | while read -r file; do
      if grep -q '"status":\s*"completed"' "$file" 2>/dev/null; then
        echo "1"
      fi
    done | wc -l | tr -d ' ')
  fi
  
  # Check for project suggestion results (from option 8 - Task Organization)
  local project_suggestions_count=0
  local task_org_results_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/task_organization_results"
  if [[ -d "$task_org_results_dir" ]]; then
    project_suggestions_count=$(find "$task_org_results_dir" -name "project_suggestions_*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  # Check for knowledge organization results (MoC/Area suggestions)
  local knowledge_org_count=0
  local knowledge_org_results_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/knowledge_organization_results"
  if [[ -d "$knowledge_org_results_dir" ]]; then
    knowledge_org_count=$(find "$knowledge_org_results_dir" -name "knowledge_org_*.json" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  # Add suggestions for background jobs ready for review (as priorities since they're actionable)
  if [[ $pending_suggestions_count -gt 0 ]]; then
    priorities+=("24|Review AI Suggestions|${pending_suggestions_count} pending suggestion(s) ready for review")
  fi
  
  if [[ $completed_advice_count -gt 0 ]]; then
    priorities+=("11|Review Advice Results|${completed_advice_count} advice response(s) ready for review")
  fi
  
  if [[ $project_suggestions_count -gt 0 ]]; then
    # Task organizer is accessed via option 3 (tasks) → option 10 (organize)
    # But we'll add a direct shortcut message in the priorities
    priorities+=("3|Review Project Suggestions|${project_suggestions_count} project suggestion result(s) ready (Tasks → Organize)")
  fi
  
  if [[ $knowledge_org_count -gt 0 ]]; then
    priorities+=("24|Review MoC/Area Suggestions|${knowledge_org_count} knowledge organization result(s) ready (AI Tools → Option 17)")
  fi
  
  # ============================================================================
  # Work Computer Mode Logic
  # ============================================================================
  if [[ "$computer_mode" == "work" ]]; then
    # Suggest capture (1) and log (15) heavily
    if [[ ! " ${suggestions[@]} " =~ " 1|" ]]; then
      suggestions+=("1|Capture to inbox|Capture work thoughts")
    fi
    if [[ ! " ${suggestions[@]} " =~ " 15|" && $today_entries -lt 3 ]]; then
      suggestions+=("15|Log to daily log|Track your work day")
    fi
    
    # Show calendar (29) prominently
    suggestions+=("29|Calendar|View schedule and check conflicts")
    
    # Don't suggest AI-heavy features (unless rarely used check passes)
    # Only suggest AI features if they're actually used
    if ! feature_rarely_used "11"; then
      suggestions+=("11|Get advice|Get personalized guidance")
    fi
    
    # Work-focused tasks
    if [[ ! " ${suggestions[@]} " =~ " 3|" ]]; then
      suggestions+=("3|Manage tasks|Review work tasks")
    fi
    if [[ ! " ${suggestions[@]} " =~ " 4|" ]]; then
      suggestions+=("4|Manage projects|Check active projects")
    fi
    
    if [[ $inbox_count -gt 0 && ! " ${priorities[@]} " =~ " 2|" ]]; then
      priorities+=("2|Process inbox|Clear work items")
    fi
  fi
  
  # ============================================================================
  # Home Computer Mode Logic
  # ============================================================================
  if [[ "$computer_mode" == "home" ]]; then
    # More flexible, personal tasks
    if [[ $today_entries -eq 0 && ! " ${suggestions[@]} " =~ " 15|" ]]; then
      suggestions+=("15|Log to daily log|Capture thoughts and activities")
    fi
    
    # AI features are fine at home
    if [[ ! " ${suggestions[@]} " =~ " 11|" ]]; then
      suggestions+=("11|Get advice|Get personalized guidance")
    fi
  fi
  
  # ============================================================================
  # Usage Pattern Learning
  # ============================================================================
  # Remove suggestions for rarely used features (unless they're priorities)
  local filtered_suggestions=()
  for suggestion in "${suggestions[@]}"; do
    if [[ -n "$suggestion" ]]; then
      IFS='|' read -r option title reason <<< "$suggestion"
      # Skip if feature is rarely used (but keep priorities and essential features)
      if feature_rarely_used "$option"; then
        # Skip rarely used features (except essential ones like 1, 2, 15, 19)
        if [[ "$option" =~ ^(1|2|15|19)$ ]]; then
          filtered_suggestions+=("$suggestion")  # Keep essential features
        fi
        # Skip others
      else
        filtered_suggestions+=("$suggestion")
      fi
    fi
  done
  suggestions=("${filtered_suggestions[@]}")
  
  # ============================================================================
  # System State Based Suggestions
  # ============================================================================
  if [[ $inbox_count -gt 0 && ! " ${priorities[@]} " =~ " 2|" ]]; then
    priorities+=("2|Process inbox|${inbox_count} item(s) need attention")
  fi
  
  # Output suggestions
  echo "SUGGESTIONS_START"
  for suggestion in "${suggestions[@]}"; do
    echo "$suggestion"
  done
  echo "SUGGESTIONS_END"
  
  echo "PRIORITIES_START"
  for priority in "${priorities[@]}"; do
    echo "$priority"
  done
  echo "PRIORITIES_END"
}

# Show smart tips based on usage patterns
show_smart_tips() {
  # Only show tips occasionally (not every time) - 20% chance
  if [[ $((RANDOM % 5)) -ne 0 ]]; then
    return 0
  fi
  
  # Check if preferences learning is available
  if ! command -v gtd-preferences-learn &>/dev/null; then
    return 0
  fi
  
  # Get usage statistics
  local prefs_file="$HOME/.gtd_preferences.json"
  if [[ ! -f "$prefs_file" ]]; then
    return 0
  fi
  
  # Analyze usage patterns and generate tips
  local prefs_file="$HOME/.gtd_preferences.json"
  local tips_output=""
  tips_output=$(python3 <<PYTHON_EOF
import json
import sys
import os
from datetime import datetime, timedelta

prefs_file = "$prefs_file"

try:
    if not os.path.exists(prefs_file):
        sys.exit(0)
    
    with open(prefs_file, "r") as f:
        prefs = json.load(f)
    
    tips = []
    
    # Check feature usage
    feature_usage = prefs.get("feature_usage", {})
    wizard_options = feature_usage.get("wizard_options", {})
    
    # Find frequently used options (used 5+ times)
    frequent_options = []
    for option, data in wizard_options.items():
        if isinstance(data, dict):
            count = data.get("usage_count", 0)
        else:
            count = data if isinstance(data, int) else 0
        
        if count >= 5:
            frequent_options.append((option, count))
    
    # Generate tips based on frequent actions
    if frequent_options:
        # Sort by usage count
        frequent_options.sort(key=lambda x: x[1], reverse=True)
        top_option, count = frequent_options[0]
        
        # Map option numbers to feature names and tips
        option_tips = {
            "1": ("Capture", "💡 Tip: Use 'gtd-wizard --fuzzy' to enable fuzzy search when selecting tasks/projects!"),
            "2": ("Process Inbox", "💡 Tip: Use 'gtd-wizard --fuzzy' for faster inbox processing with fuzzy search!"),
            "3": ("Manage Tasks", "💡 Tip: Try 'gtd-wizard --fuzzy' to quickly find tasks with fuzzy search!"),
            "4": ("Manage Projects", "💡 Tip: Use 'gtd-wizard --fuzzy' to quickly find projects by typing partial names!"),
            "5": ("Manage Areas", "💡 Tip: Enable fuzzy search with 'gtd-wizard --fuzzy' for faster area selection!"),
            "6": ("Review", "💡 Tip: Use command line options like '--fuzzy' to speed up your workflow!"),
        }
        
        if top_option in option_tips:
            feature_name, tip = option_tips[top_option]
            tips.append({
                "type": "command_line",
                "message": tip,
                "feature": feature_name,
                "usage_count": count
            })
    
    # Check if fuzzy search is being used
    # (We can't easily detect this, but we can suggest it if they use selection features a lot)
    if len(frequent_options) >= 2:
        tips.append({
            "type": "fuzzy_search",
            "message": "💡 Tip: Enable fuzzy search with 'gtd-wizard --fuzzy' to make finding tasks/projects/areas faster!",
            "feature": "Fuzzy Search"
        })
    
    # Check for favorited projects that need attention
    import subprocess
    import os
    projects_path = os.path.expanduser("~/Documents/gtd/projects")
    if os.path.isdir(projects_path):
        favorited_projects = []
        for project_dir in os.listdir(projects_path):
            project_readme = os.path.join(projects_path, project_dir, "README.md")
            if os.path.isfile(project_readme):
                try:
                    with open(project_readme, "r") as f:
                        content = f.read()
                        # Check if favorite: true in frontmatter
                        if "favorite: true" in content or "favorite:true" in content:
                            # Get project name
                            project_name = project_dir.replace("-", " ").title()
                            # Count active tasks in project
                            project_dir_path = os.path.join(projects_path, project_dir)
                            active_tasks = 0
                            if os.path.isdir(project_dir_path):
                                for task_file in os.listdir(project_dir_path):
                                    if task_file.endswith(".md") and task_file != "README.md":
                                        task_path = os.path.join(project_dir_path, task_file)
                                        try:
                                            with open(task_path, "r") as tf:
                                                task_content = tf.read()
                                                if "status: active" in task_content:
                                                    active_tasks += 1
                                        except:
                                            pass
                            
                            if active_tasks > 0:
                                favorited_projects.append({
                                    "name": project_name,
                                    "tasks": active_tasks
                                })
                except:
                    pass
        
        # Add reminder about favorited projects
        if favorited_projects:
            project = favorited_projects[0]  # Show one at a time
            tips.append({
                "type": "favorited_project",
                "message": f"⭐ Focus Reminder: '{project['name']}' has {project['tasks']} active task(s). This is a favorited project - consider working on it!",
                "feature": "Favorited Project",
                "project": project["name"],
                "task_count": project["tasks"]
            })
    
    # Output tips as JSON
    if tips:
        print(json.dumps(tips[0]))  # Show one tip at a time
except Exception:
    # Silently fail
    sys.exit(0)
PYTHON_EOF
)
  
  # Display tip if we got one
  if [[ -n "$tips_output" ]]; then
    local tip_message=$(echo "$tips_output" | python3 -c "import json, sys; d=json.load(sys.stdin); print(d.get('message', ''))" 2>/dev/null)
    if [[ -n "$tip_message" ]]; then
      echo ""
      echo -e "${YELLOW}${tip_message}${NC}"
      echo ""
    fi
  fi
}

# Show smart defaults section in dashboard
show_smart_defaults() {
  local time_of_day=$(get_time_of_day)
  local computer_mode=$(get_computer_mode)
  
  # Get suggestions with error handling
  local suggestions_output=""
  set +e
  suggestions_output=$(get_smart_defaults 2>/dev/null || echo "")
  set -e
  
  # If get_smart_defaults failed or returned empty, show default message
  if [[ -z "$suggestions_output" ]]; then
    echo -e "${BOLD}🎯 Smart Suggestions${NC}"
    echo ""
    local time_emoji=""
    case "$time_of_day" in
      morning) time_emoji="🌅" ;;
      afternoon) time_emoji="☀️" ;;
      evening) time_emoji="🌙" ;;
      *) time_emoji="🕐" ;;
    esac
    
    local mode_emoji=""
    case "$computer_mode" in
      work) mode_emoji="💼" ;;
      home) mode_emoji="🏠" ;;
      *) mode_emoji="💻" ;;
    esac
    
    local time_first="${time_of_day:0:1}"
    local time_rest="${time_of_day:1}"
    local time_display="$(echo "$time_first" | tr '[:lower:]' '[:upper:]')$time_rest"
    
    local mode_first="${computer_mode:0:1}"
    local mode_rest="${computer_mode:1}"
    local mode_display="$(echo "$mode_first" | tr '[:lower:]' '[:upper:]')$mode_rest"
    
    echo -e "  ${CYAN}Context: ${time_emoji} ${time_display} | ${mode_emoji} ${mode_display}${NC}"
    echo "  No specific suggestions at this time. Check your inbox and tasks!"
    echo ""
    return 0
  fi
  
  local suggestions=()
  local priorities=()
  
  local in_suggestions=false
  local in_priorities=false
  
  while IFS= read -r line; do
    if [[ "$line" == "SUGGESTIONS_START" ]]; then
      in_suggestions=true
      in_priorities=false
      continue
    elif [[ "$line" == "SUGGESTIONS_END" ]]; then
      in_suggestions=false
      continue
    elif [[ "$line" == "PRIORITIES_START" ]]; then
      in_priorities=true
      in_suggestions=false
      continue
    elif [[ "$line" == "PRIORITIES_END" ]]; then
      in_priorities=false
      continue
    fi
    
    if [[ "$in_suggestions" == true && -n "$line" ]]; then
      suggestions+=("$line")
    elif [[ "$in_priorities" == true && -n "$line" ]]; then
      priorities+=("$line")
    fi
  done <<< "$suggestions_output"
  
  # Display smart defaults section
  echo -e "${BOLD}🎯 Smart Suggestions${NC}"
  echo ""
  
  # Show context
  local time_emoji=""
  case "$time_of_day" in
    morning) time_emoji="🌅" ;;
    afternoon) time_emoji="☀️" ;;
    evening) time_emoji="🌙" ;;
    *) time_emoji="🕐" ;;
  esac
  
  local mode_emoji=""
  case "$computer_mode" in
    work) mode_emoji="💼" ;;
    home) mode_emoji="🏠" ;;
    *) mode_emoji="💻" ;;
  esac
  
  # Capitalize first letter (compatible with all bash versions)
  # Simple approach: get first char, uppercase it, append rest
  local time_first="${time_of_day:0:1}"
  local time_rest="${time_of_day:1}"
  local time_display="$(echo "$time_first" | tr '[:lower:]' '[:upper:]')$time_rest"
  
  local mode_first="${computer_mode:0:1}"
  local mode_rest="${computer_mode:1}"
  local mode_display="$(echo "$mode_first" | tr '[:lower:]' '[:upper:]')$mode_rest"
  
  echo -e "  ${CYAN}Context: ${time_emoji} ${time_display} | ${mode_emoji} ${mode_display}${NC}"
  echo ""
  
  # Show priorities first (if any)
  if [[ ${#priorities[@]} -gt 0 ]]; then
    echo -e "  ${BOLD}${RED}⚠️  Priority Actions:${NC}"
    for priority in "${priorities[@]}"; do
      if [[ -n "$priority" ]]; then
        IFS='|' read -r option title reason <<< "$priority"
        echo -e "    ${BOLD}${RED}→${NC} Press ${BOLD}${GREEN}${option}${NC} to ${title}"
        if [[ -n "$reason" ]]; then
          echo -e "      ${YELLOW}${reason}${NC}"
        fi
      fi
    done
    echo ""
  fi
  
  # Show suggestions
  if [[ ${#suggestions[@]} -gt 0 ]]; then
    echo -e "  ${BOLD}💡 Suggested Actions:${NC}"
    for suggestion in "${suggestions[@]}"; do
      if [[ -n "$suggestion" ]]; then
        IFS='|' read -r option title reason <<< "$suggestion"
        echo -e "    ${CYAN}→${NC} Press ${BOLD}${GREEN}${option}${NC} to ${title}"
        if [[ -n "$reason" ]]; then
          echo -e "      ${GRAY}${reason}${NC}"
        fi
      fi
    done
    echo ""
  fi
  
  # If no suggestions or priorities, show a helpful message
  if [[ ${#priorities[@]} -eq 0 && ${#suggestions[@]} -eq 0 ]]; then
    echo -e "  ${GRAY}No specific suggestions at this time. Check your inbox and tasks!${NC}"
    echo ""
  fi
}

# Get mode-specific directory config
get_mode_directory() {
  local mode="$1"
  local dir_type="$2"  # daily_log, gtd_base, second_brain
  local config_file="$3"
  
  # Look for mode-specific config (e.g., DAILY_LOG_DIR_WORK, DAILY_LOG_DIR_HOME)
  local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
  local key="${dir_type}_${mode_upper}"
  
  # Try to find the key in config
  if grep -q "^${key}=" "$config_file" 2>/dev/null; then
    grep "^${key}=" "$config_file" | head -1 | cut -d'=' -f2 | tr -d '"' | tr -d "'"
  else
    echo ""
  fi
}

# Update mode-specific directory config
update_mode_directory() {
  local mode="$1"
  local dir_type="$2"  # daily_log, gtd_base, second_brain
  local new_path="$3"
  local config_file="$4"
  
  local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
  local key="${dir_type}_${mode_upper}"
  
  # Map dir_type to actual config key
  case "$dir_type" in
    daily_log)
      key="DAILY_LOG_DIR_${mode_upper}"
      ;;
    gtd_base)
      key="GTD_BASE_DIR_${mode_upper}"
      ;;
    second_brain)
      key="SECOND_BRAIN_${mode_upper}"
      ;;
  esac
  
  local is_macos=""
  if [[ "$(uname)" == "Darwin" ]]; then
    is_macos="true"
  fi
  
  if grep -q "^${key}=" "$config_file" 2>/dev/null; then
    # Update existing
    if [[ -n "$is_macos" ]]; then
      sed -i '' "s|^${key}=.*|${key}=\"${new_path}\"|" "$config_file"
    else
      sed -i "s|^${key}=.*|${key}=\"${new_path}\"|" "$config_file"
    fi
  else
    # Add new - find a good place to insert
    if grep -q "^# Directory Structure" "$config_file" 2>/dev/null; then
      # Insert after Directory Structure section
      if [[ -n "$is_macos" ]]; then
        sed -i '' "/^# Directory Structure/a\\
# Mode-specific directories (${mode} mode)\\
${key}=\"${new_path}\"
" "$config_file"
      else
        sed -i "/^# Directory Structure/a # Mode-specific directories (${mode} mode)\n${key}=\"${new_path}\"" "$config_file"
      fi
    else
      # Just append
      echo "${key}=\"${new_path}\"" >> "$config_file"
    fi
  fi
}

# Computer Mode Wizard
computer_mode_wizard() {
  # Set error handling - don't exit on errors in this function
  set +e
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}💻 Switch Computer Mode${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local current_mode=$(get_computer_mode)
  local mode_emoji=""
  local mode_desc=""
  
  case "$current_mode" in
    work)
      mode_emoji="💼"
      mode_desc="Work computer - Focus on work tasks and projects"
      ;;
    home)
      mode_emoji="🏠"
      mode_desc="Home computer - Personal tasks and flexible activities"
      ;;
  esac
  
  # Capitalize first character (portable method)
  local mode_capitalized="$(echo "${current_mode:0:1}" | tr '[:lower:]' '[:upper:]')${current_mode:1}"
  
  echo -e "Current mode: ${BOLD}${mode_emoji} ${mode_capitalized}${NC}"
  echo -e "  ${GRAY}${mode_desc}${NC}"
  echo ""
  
  # Show current directory paths
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  local daily_log_config="$HOME/code/dotfiles/zsh/.daily_log_config"
  if [[ ! -f "$daily_log_config" ]]; then
    daily_log_config="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  
  # Load current configs
  if [[ -f "$gtd_config" ]]; then
    source "$gtd_config" 2>/dev/null || true
  fi
  if [[ -f "$daily_log_config" ]]; then
    source "$daily_log_config" 2>/dev/null || true
  fi
  
  # Get current directories (check for mode-specific first, then fallback to general)
  local current_daily_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
  local current_gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
  local current_second_brain="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  
  # Check for mode-specific overrides (use indirect variable expansion)
  local mode_upper=$(echo "$current_mode" | tr '[:lower:]' '[:upper:]')
  local mode_daily_log="DAILY_LOG_DIR_${mode_upper}"
  local mode_gtd_base="GTD_BASE_DIR_${mode_upper}"
  local mode_second_brain="SECOND_BRAIN_${mode_upper}"
  
  if [[ -n "${!mode_daily_log:-}" ]]; then
    current_daily_log="${!mode_daily_log}"
  fi
  if [[ -n "${!mode_gtd_base:-}" ]]; then
    current_gtd_base="${!mode_gtd_base}"
  fi
  if [[ -n "${!mode_second_brain:-}" ]]; then
    current_second_brain="${!mode_second_brain}"
  fi
  
  echo -e "${BOLD}Current Directory Paths:${NC}"
  echo -e "  📝 Daily Logs: ${CYAN}${current_daily_log}${NC}"
  echo -e "  📁 GTD Base:   ${CYAN}${current_gtd_base}${NC}"
  echo -e "  🧠 Second Brain: ${CYAN}${current_second_brain}${NC}"
  echo ""
  echo "Switch to:"
  echo ""
  if [[ "$current_mode" == "work" ]]; then
    echo -e "  ${GREEN}1)${NC} 🏠 Home mode"
    echo -e "     Personal tasks, flexible activities, learning"
  else
    echo -e "  ${GREEN}1)${NC} 💼 Work mode"
    echo -e "     Work tasks, projects, professional focus"
  fi
  echo ""
  echo -e "  ${GREEN}2)${NC} ⚙️  Configure directories for current mode"
  echo -e "     Set where daily logs, GTD files, and Second Brain are stored"
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      local new_mode="home"
      if [[ "$current_mode" == "work" ]]; then
        new_mode="home"
      else
        new_mode="work"
      fi
      
      set_computer_mode "$new_mode"
      
      # After switching, ask if they want to configure directories
      echo ""
      echo -e "${YELLOW}💡 Tip:${NC} Make sure your directory paths are configured correctly"
      echo "   for ${new_mode} mode so sync systems can find your files."
      echo ""
      echo -n "Configure directories for ${new_mode} mode now? (y/n): "
      read configure_now
      
      if [[ "$configure_now" =~ ^[Yy] ]]; then
        configure_mode_directories "$new_mode"
      fi
      
      echo ""
      gtd_quick_pause
      ;;
    2)
      configure_mode_directories "$current_mode"
      ;;
    0|"")
      set -e  # Restore error handling
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
      ;;
  esac
  
  # Restore error handling before returning
  set -e
  
  return 0
}

# Configure directories for a specific mode
configure_mode_directories() {
  local mode="$1"
  local mode_upper=$(echo "$mode" | tr '[:lower:]' '[:upper:]')
  local mode_display="$(echo "${mode:0:1}" | tr '[:lower:]' '[:upper:]')${mode:1}"
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}⚙️  Configure Directories for ${mode_display} Mode${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Set where files are stored for ${mode} mode."
  echo "These paths should point to locations that sync between computers."
  echo ""
  
  # Load configs
  local gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
  if [[ ! -f "$gtd_config" ]]; then
    gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
  fi
  
  local daily_log_config="$HOME/code/dotfiles/zsh/.daily_log_config"
  if [[ ! -f "$daily_log_config" ]]; then
    daily_log_config="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
  fi
  
  if [[ -f "$gtd_config" ]]; then
    source "$gtd_config" 2>/dev/null || true
  fi
  if [[ -f "$daily_log_config" ]]; then
    source "$daily_log_config" 2>/dev/null || true
  fi
  
  # Get current values (mode-specific or fallback to general)
  # Use indirect variable expansion (mode_upper already defined above)
  local mode_daily_log="DAILY_LOG_DIR_${mode_upper}"
  local mode_gtd_base="GTD_BASE_DIR_${mode_upper}"
  local mode_second_brain="SECOND_BRAIN_${mode_upper}"
  
  local current_daily_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
  local current_gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
  local current_second_brain="${SECOND_BRAIN:-$HOME/Documents/obsidian/Second Brain}"
  
  # Check for mode-specific overrides
  if [[ -n "${!mode_daily_log:-}" ]]; then
    current_daily_log="${!mode_daily_log}"
  fi
  if [[ -n "${!mode_gtd_base:-}" ]]; then
    current_gtd_base="${!mode_gtd_base}"
  fi
  if [[ -n "${!mode_second_brain:-}" ]]; then
    current_second_brain="${!mode_second_brain}"
  fi
  
  echo -e "${BOLD}Current paths:${NC}"
  echo -e "  1) Daily Logs:    ${CYAN}${current_daily_log}${NC}"
  echo -e "  2) GTD Base:      ${CYAN}${current_gtd_base}${NC}"
  echo -e "  3) Second Brain:  ${CYAN}${current_second_brain}${NC}"
  echo ""
  echo "Options:"
  echo ""
  echo -e "  ${GREEN}1)${NC} Set Daily Log directory"
  echo -e "  ${GREEN}2)${NC} Set GTD Base directory"
  echo -e "  ${GREEN}3)${NC} Set Second Brain directory"
  echo -e "  ${GREEN}4)${NC} Use defaults (recommended for syncing)"
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back"
  echo ""
  echo -n "Choose: "
  read choice
  
  case "$choice" in
    1)
      echo ""
      echo "Enter Daily Log directory path for ${mode} mode:"
      echo "  (This is where daily log files are stored)"
      echo "  Current: ${current_daily_log}"
      echo ""
      echo -n "Path (or press Enter to keep current): "
      read new_path
      
      if [[ -n "$new_path" ]]; then
        # Expand ~ and $HOME
        new_path="${new_path/#\~/$HOME}"
        new_path="${new_path//\$HOME/$HOME}"
        
        # Update in daily_log_config
        update_mode_directory "$mode" "daily_log" "$new_path" "$daily_log_config"
        
        # Also update DAILY_LOG_DIR if it's the active mode
        if [[ "$mode" == "$(get_computer_mode)" ]]; then
          if grep -q "^DAILY_LOG_DIR=" "$daily_log_config" 2>/dev/null; then
            local is_macos=""
            if [[ "$(uname)" == "Darwin" ]]; then
              is_macos="true"
            fi
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"${new_path}\"|" "$daily_log_config"
            else
              sed -i "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"${new_path}\"|" "$daily_log_config"
            fi
          fi
        fi
        
        echo ""
        echo -e "${GREEN}✓${NC} Daily Log directory set to: ${new_path}"
      fi
      ;;
    2)
      echo ""
      echo "Enter GTD Base directory path for ${mode} mode:"
      echo "  (This is where GTD projects, tasks, areas are stored)"
      echo "  Current: ${current_gtd_base}"
      echo ""
      echo -n "Path (or press Enter to keep current): "
      read new_path
      
      if [[ -n "$new_path" ]]; then
        # Expand ~ and $HOME
        new_path="${new_path/#\~/$HOME}"
        new_path="${new_path//\$HOME/$HOME}"
        
        # Update in gtd_config
        update_mode_directory "$mode" "gtd_base" "$new_path" "$gtd_config"
        
        # Also update GTD_BASE_DIR if it's the active mode
        if [[ "$mode" == "$(get_computer_mode)" ]]; then
          if grep -q "^GTD_BASE_DIR=" "$gtd_config" 2>/dev/null; then
            local is_macos=""
            if [[ "$(uname)" == "Darwin" ]]; then
              is_macos="true"
            fi
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"${new_path}\"|" "$gtd_config"
            else
              sed -i "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"${new_path}\"|" "$gtd_config"
            fi
          fi
        fi
        
        echo ""
        echo -e "${GREEN}✓${NC} GTD Base directory set to: ${new_path}"
      fi
      ;;
    3)
      echo ""
      echo "Enter Second Brain directory path for ${mode} mode:"
      echo "  (This is your Obsidian vault location)"
      echo "  Current: ${current_second_brain}"
      echo ""
      echo -n "Path (or press Enter to keep current): "
      read new_path
      
      if [[ -n "$new_path" ]]; then
        # Expand ~ and $HOME
        new_path="${new_path/#\~/$HOME}"
        new_path="${new_path//\$HOME/$HOME}"
        
        # Update in gtd_config
        update_mode_directory "$mode" "second_brain" "$new_path" "$gtd_config"
        
        # Also update SECOND_BRAIN if it's the active mode
        if [[ "$mode" == "$(get_computer_mode)" ]]; then
          if grep -q "^SECOND_BRAIN=" "$gtd_config" 2>/dev/null; then
            local is_macos=""
            if [[ "$(uname)" == "Darwin" ]]; then
              is_macos="true"
            fi
            if [[ -n "$is_macos" ]]; then
              sed -i '' "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"${new_path}\"|" "$gtd_config"
            else
              sed -i "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"${new_path}\"|" "$gtd_config"
            fi
          fi
        fi
        
        echo ""
        echo -e "${GREEN}✓${NC} Second Brain directory set to: ${new_path}"
      fi
      ;;
    4)
      # Use defaults - these should be in synced locations
      local default_daily_log="$HOME/Documents/daily_logs"
      local default_gtd_base="$HOME/Documents/gtd"
      local default_second_brain="$HOME/Documents/obsidian/Second Brain"
      
      update_mode_directory "$mode" "daily_log" "$default_daily_log" "$daily_log_config"
      update_mode_directory "$mode" "gtd_base" "$default_gtd_base" "$gtd_config"
      update_mode_directory "$mode" "second_brain" "$default_second_brain" "$gtd_config"
      
      echo ""
      echo -e "${GREEN}✓${NC} Set to default paths (recommended for syncing)"
      echo "  Daily Logs: ${default_daily_log}"
      echo "  GTD Base: ${default_gtd_base}"
      echo "  Second Brain: ${default_second_brain}"
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
  
  echo ""
  gtd_quick_pause
}

# Check if we're in a non-interactive environment (e.g., running tests)
# Returns 0 (true) if interactive, 1 (false) if non-interactive
is_interactive() {
  # Check for explicit non-interactive flags first
  if [[ -n "${CI:-}" ]] || [[ -n "${TEST_MODE:-}" ]] || [[ -n "${NON_INTERACTIVE:-}" ]] || [[ -n "${BATS_TEST_FILENAME:-}" ]]; then
    return 1  # Non-interactive
  fi
  
  # Check if any BASH_SOURCE contains "test" (we're being sourced/called from a test file)
  local i=0
  while [[ $i -lt ${#BASH_SOURCE[@]} ]]; do
    if [[ -n "${BASH_SOURCE[$i]:-}" ]] && [[ "${BASH_SOURCE[$i]}" =~ /test.*\.sh$ ]] || [[ "${BASH_SOURCE[$i]}" =~ test_ ]]; then
      return 1  # Non-interactive (sourced from test file)
    fi
    ((i++))
  done
  
  # Check if stdin is a TTY (terminal)
  # This catches most non-interactive scenarios (pipes, redirects, etc.)
  if [[ -t 0 ]]; then
    return 0  # Interactive
  else
    return 1  # Non-interactive (no TTY)
  fi
}

# Test execution wizard
test_execution_wizard() {
  # Check if non-interactive (e.g., running in tests) - exit early
  if ! is_interactive; then
    echo "Skipping interactive wizard in non-interactive mode"
    return 0
  fi
  
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🧪 Run Unit Tests${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "Run unit tests to verify the GTD system is working correctly."
  echo ""
  echo "Available test suites:"
  echo ""
  echo -e "${BOLD}${CYAN}Bash Tests:${NC}"
  echo -e "  ${GREEN}1)${NC} Run all bash tests"
  echo -e "  ${GREEN}2)${NC} Test gtd-common.sh helpers"
  echo -e "  ${GREEN}3)${NC} Test gtd-guides.sh guides"
  echo -e "  ${GREEN}4)${NC} Test wizard functions"
  echo -e "  ${GREEN}5)${NC} Test wizard core functions"
  echo -e "  ${GREEN}6)${NC} Test zettelkasten wizard"
  echo ""
  echo -e "${BOLD}${CYAN}Python Tests:${NC}"
  echo -e "  ${GREEN}7)${NC} Run all Python tests"
  echo -e "  ${GREEN}8)${NC} Test enhanced search system"
  echo -e "  ${GREEN}9)${NC} Test persona helper"
  echo -e "  ${GREEN}10)${NC} Test tool registry"
  echo -e "  ${GREEN}11)${NC} Test LM Studio helper"
  echo ""
  echo -e "${BOLD}${CYAN}Vectorization Tests (split by memory usage):${NC}"
  echo -e "  ${GREEN}13)${NC} Test vectorization basics (no dependencies)"
  echo -e "  ${GREEN}14)${NC} Test vectorization config (lightweight)"
  echo -e "  ${GREEN}15)${NC} Test vectorization database (memory-intensive)"
  echo ""
  echo -e "${BOLD}${CYAN}All Tests:${NC}"
  echo -e "  ${GREEN}12)${NC} Run complete test suite (all bash + Python)"
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  # Use timeout on read to prevent hanging in non-interactive environments
  if ! is_interactive; then
    echo ""
    echo "Non-interactive mode detected, exiting..."
    return 0
  fi
  read choice || {
    # If read fails (EOF, broken pipe, etc.), exit gracefully
    echo ""
    echo "Input read failed, exiting..."
    return 0
  }
  
  # Get test directory
  local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local tests_dir="$script_dir/../tests"
  if [[ ! -d "$tests_dir" && -d "$HOME/code/personal/dotfiles/tests" ]]; then
    tests_dir="$HOME/code/personal/dotfiles/tests"
  fi
  
  case "$choice" in
    1)
      echo ""
      echo -e "${CYAN}Running all bash tests...${NC}"
      echo ""
      if [[ -f "$tests_dir/run_tests.sh" ]]; then
        # Run tests but don't exit on failure - allow wizard to continue
        set +e  # Don't exit on error
        (bash "$tests_dir/run_tests.sh" 2>&1 | grep -E "(test_|Running:|Test|PASS|FAIL|Summary)") || bash "$tests_dir/run_tests.sh"
        local test_exit_code=$?
        set -e  # Re-enable exit on error
        if [[ $test_exit_code -ne 0 ]]; then
          echo ""
          echo -e "${YELLOW}Note: Some tests failed, but continuing wizard...${NC}"
        fi
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    2)
      echo ""
      echo -e "${CYAN}Testing gtd-common.sh...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_common.sh" ]]; then
        bash "$tests_dir/test_gtd_common.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_common.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    3)
      echo ""
      echo -e "${CYAN}Testing gtd-guides.sh...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_guides.sh" ]]; then
        bash "$tests_dir/test_gtd_guides.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_guides.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    4)
      echo ""
      echo -e "${CYAN}Testing wizard functions...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_wizard_functions.sh" ]]; then
        bash "$tests_dir/test_wizard_functions.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_wizard_functions.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    5)
      echo ""
      echo -e "${CYAN}Testing wizard core functions...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_wizard_core_functions.sh" ]]; then
        bash "$tests_dir/test_wizard_core_functions.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_wizard_core_functions.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    6)
      echo ""
      echo -e "${CYAN}Testing zettelkasten wizard...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_zettelkasten_wizard.sh" ]]; then
        bash "$tests_dir/test_zettelkasten_wizard.sh"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_zettelkasten_wizard.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    7)
      echo ""
      echo -e "${CYAN}Running all Python tests...${NC}"
      echo ""
      for test_file in "$tests_dir"/test_*.py; do
        if [[ -f "$test_file" ]]; then
          echo -e "${YELLOW}Running: $(basename "$test_file")${NC}"
          python3 "$test_file" 2>&1 | head -50
          echo ""
        fi
      done
      gtd_enter_to_continue
      ;;
    8)
      echo ""
      echo -e "${CYAN}Testing enhanced search system...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_enhanced_search.py" ]]; then
        python3 "$tests_dir/test_enhanced_search.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_enhanced_search.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    9)
      echo ""
      echo -e "${CYAN}Testing persona helper...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_persona_helper.py" ]]; then
        python3 "$tests_dir/test_gtd_persona_helper.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_persona_helper.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    10)
      echo ""
      echo -e "${CYAN}Testing tool registry...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_tool_registry.py" ]]; then
        python3 "$tests_dir/test_gtd_tool_registry.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_tool_registry.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    11)
      echo ""
      echo -e "${CYAN}Testing LM Studio helper...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_lmstudio_helper.py" ]]; then
        python3 "$tests_dir/test_lmstudio_helper.py"
      else
        echo -e "${RED}Test file not found: $tests_dir/test_lmstudio_helper.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    12)
      echo ""
      echo -e "${CYAN}Running complete test suite...${NC}"
      echo ""
      if [[ -f "$tests_dir/run_tests.sh" ]]; then
        # Run tests but don't exit on failure - allow wizard to continue
        set +e  # Don't exit on error
        bash "$tests_dir/run_tests.sh"
        local test_exit_code=$?
        set -e  # Re-enable exit on error
        if [[ $test_exit_code -ne 0 ]]; then
          echo ""
          echo -e "${YELLOW}Note: Some tests failed, but continuing wizard...${NC}"
        fi
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    13)
      echo ""
      echo -e "${CYAN}Testing vectorization basics (no dependencies)...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_vectorization_basic.py" ]]; then
        set +e  # Don't exit on error
        python3 "$tests_dir/test_gtd_vectorization_basic.py" -v 2>&1
        local test_exit_code=$?
        set -e  # Re-enable exit on error
        if [[ $test_exit_code -ne 0 ]]; then
          echo ""
          echo -e "${YELLOW}Note: Some tests failed, but continuing wizard...${NC}"
        fi
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_vectorization_basic.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    14)
      echo ""
      echo -e "${CYAN}Testing vectorization config (lightweight)...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_vectorization_config.py" ]]; then
        set +e  # Don't exit on error
        python3 "$tests_dir/test_gtd_vectorization_config.py" -v 2>&1
        local test_exit_code=$?
        set -e  # Re-enable exit on error
        if [[ $test_exit_code -ne 0 ]]; then
          echo ""
          echo -e "${YELLOW}Note: Some tests failed, but continuing wizard...${NC}"
        fi
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_vectorization_config.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    15)
      echo ""
      echo -e "${CYAN}Testing vectorization database (memory-intensive)...${NC}"
      echo ""
      if [[ -f "$tests_dir/test_gtd_vectorization_db.py" ]]; then
        set +e  # Don't exit on error
        python3 "$tests_dir/test_gtd_vectorization_db.py" -v 2>&1
        local test_exit_code=$?
        set -e  # Re-enable exit on error
        if [[ $test_exit_code -ne 0 ]]; then
          echo ""
          echo -e "${YELLOW}Note: Some tests failed, but continuing wizard...${NC}"
        fi
      else
        echo -e "${RED}Test file not found: $tests_dir/test_gtd_vectorization_db.py${NC}"
      fi
      echo ""
      gtd_enter_to_continue
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
      ;;
  esac
}

# Show organization techniques guide
show_organization_guide() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${YELLOW}📚 Organization Techniques & Quick Guides${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}🎯 GTD (Getting Things Done):${NC}"
  echo "  • Capture → Process → Organize → Review → Do"
  echo "  • 5 Horizons: Runway → 10k → 20k → 30k → 40k"
  echo "  • 2-Minute Rule: Do it now if < 2 minutes"
  echo "  • Weekly Review: Critical for system health"
  echo ""
  echo -e "${BOLD}📁 PARA Method:${NC}"
  echo "  • Projects: Multi-step outcomes with deadlines"
  echo "  • Areas: Ongoing responsibilities to maintain"
  echo "  • Resources: Topics of ongoing interest"
  echo "  • Archives: Inactive items from other categories"
  echo ""
  echo -e "${BOLD}🧠 Second Brain (CODE):${NC}"
  echo "  • Capture: Keep what resonates"
  echo "  • Organize: Save by actionability (PARA)"
  echo "  • Distill: Progressive summarization (3 levels)"
  echo "  • Express: Create content from notes"
  echo ""
  echo -e "${BOLD}🔗 Zettelkasten:${NC}"
  echo "  • Atomic Notes: One idea per note"
  echo "  • Permanent Notes: Core insights"
  echo "  • Literature Notes: From external sources"
  echo "  • Link Everything: Build knowledge graph"
  echo ""
  echo -e "${BOLD}🗺️  Maps of Content (MOCs):${NC}"
  echo "  • Organize notes by topic/theme"
  echo "  • Dynamic indexes that evolve"
  echo "  • Create when you have 3+ related notes"
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Show process reminders and frequencies
show_process_reminders() {
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${YELLOW}📋 Quick Reference: How Often to Visit Each Section${NC}"
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo -e "${BOLD}🔄 Daily (Multiple times):${NC}"
  echo -e "  ${GREEN}1)${NC} Capture to inbox - As needed (whenever something comes to mind)"
  echo -e "  ${GREEN}15)${NC} Log to daily log - Multiple times throughout the day"
  echo ""
  echo -e "${BOLD}📅 Daily (1-2 times):${NC}"
  echo -e "  ${GREEN}2)${NC} Process inbox - Morning & evening (keep it empty!)"
  echo -e "  ${GREEN}19)${NC} Morning/Evening Check-In - Start & end of day (5-10 min)"
  echo -e "  ${GREEN}6)${NC} Daily review - Morning or evening (5-10 min)"
  echo ""
  echo -e "${BOLD}⚡ Daily (As needed):${NC}"
  echo -e "  ${GREEN}3)${NC} Manage tasks - When selecting what to work on"
  echo -e "  ${GREEN}4)${NC} Manage projects - When working on active projects"
  echo -e "  ${GREEN}16)${NC} Search GTD system - When looking for something"
  echo -e "  ${GREEN}11)${NC} Get advice from personas - When stuck or need perspective"
  echo ""
  echo -e "${BOLD}📆 Weekly (Once):${NC}"
  echo -e "  ${GREEN}6)${NC} Weekly review - Sunday morning or Friday afternoon (1-2 hours) ⚠️  CRITICAL"
  echo -e "  ${GREEN}7)${NC} Sync with Second Brain - After weekly review"
  echo -e "  ${GREEN}25)${NC} Goal Tracking & Progress - Weekly goal check-in"
  echo ""
  echo -e "${BOLD}📅 Monthly (Once):${NC}"
  echo -e "  ${GREEN}6)${NC} Monthly review - Last/first weekend (2-3 hours)"
  echo -e "  ${GREEN}5)${NC} Review areas - Monthly area review"
  echo ""
  echo -e "${BOLD}🔄 Quarterly/Yearly:${NC}"
  echo -e "  ${GREEN}6)${NC} Quarterly review - Every 3 months (3-4 hours)"
  echo -e "  ${GREEN}6)${NC} Yearly review - Once per year (4-6 hours)"
  echo ""
  echo -e "${BOLD}💡 As Needed / Ongoing:${NC}"
  echo -e "  ${GREEN}17)${NC} System status - Check health periodically"
  echo -e "  ${GREEN}18)${NC} Manage habits - Track daily/weekly habits"
  echo -e "  ${GREEN}8)${NC} Manage MOCs - When organizing knowledge"
  echo -e "  ${GREEN}9)${NC} Express Phase - When creating from notes"
  
  # Web Interface Hint
  check_web_service_status_reminder() {
    local web_running=false
    local web_installed=false
    
    # Check if backend API is accessible (quick check with 1 second timeout)
    if command -v curl &>/dev/null; then
      if curl -s --max-time 1 http://localhost:8000/api/health >/dev/null 2>&1; then
        web_running=true
      fi
    fi
    
    # Check if service is installed
    if [[ "$(uname)" == "Darwin" ]]; then
      if [[ -f "${HOME}/Library/LaunchAgents/com.gtd.wizard-api.plist" ]]; then
        web_installed=true
      fi
    else
      if [[ -f "/etc/systemd/system/gtd-wizard-api.service" ]]; then
        web_installed=true
      fi
    fi
    
    # Show hint based on status (only if running or installed)
    if [[ "$web_running" == "true" ]]; then
      echo ""
      echo -e "${BOLD}🌐 Web Interface:${NC}"
      echo -e "  ${GREEN}✓ Running${NC} → http://localhost:8000 (or http://localhost if nginx configured)"
      echo -e "  ${CYAN}💡${NC} Access the web UI in your browser for a modern interface"
    elif [[ "$web_installed" == "true" ]]; then
      echo ""
      echo -e "${BOLD}🌐 Web Interface:${NC}"
      echo -e "  ${YELLOW}⚠ Installed but not running${NC} → Start via ${BOLD}27${NC} → ${BOLD}16${NC}"
    fi
  }
  
  # Add web service hint (with error handling)
  set +e
  check_web_service_status_reminder 2>/dev/null || true
  set -e
  
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Dashboard - Show system status and quick stats (polished version)
# Read dashboard cache file
read_dashboard_cache() {
  local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
  local cache_age=0
  
  if [[ -f "$cache_file" ]]; then
    # Check cache age (in seconds)
    if command -v stat &>/dev/null; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
      else
        cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
      fi
    fi
    
    # Cache is valid if less than 30 seconds old
    if [[ $cache_age -lt 30 ]]; then
      # Use Python to parse JSON (more reliable than jq which might not be installed)
      python3 <<PYTHON_EOF 2>/dev/null
import json
import sys
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    # Output as shell-friendly format
    print(f"INBOX_COUNT={cache.get('inbox_count', 0)}")
    print(f"TASKS_COUNT={cache.get('tasks_count', 0)}")
    print(f"ACTIVE_TASKS_COUNT={cache.get('active_tasks_count', 0)}")
    print(f"PROJECT_TASKS_COUNT={cache.get('project_tasks_count', 0)}")
    print(f"TOTAL_ACTIVE_TASKS={cache.get('total_active_tasks', 0)}")
    print(f"PROJECTS_COUNT={cache.get('projects_count', 0)}")
    print(f"AREAS_COUNT={cache.get('areas_count', 0)}")
    print(f"WAITING_COUNT={cache.get('waiting_count', 0)}")
    print(f"SOMEDAY_COUNT={cache.get('someday_count', 0)}")
    print(f"SUGGESTIONS_TOTAL={cache.get('suggestions', {}).get('total', 0)}")
    print(f"SUGGESTIONS_HIGH={cache.get('suggestions', {}).get('high', 0)}")
    print(f"SUGGESTIONS_MEDIUM={cache.get('suggestions', {}).get('medium', 0)}")
    print(f"SUGGESTIONS_LOW={cache.get('suggestions', {}).get('low', 0)}")
    print(f"TODAY_ENTRIES={cache.get('today_entries', 0)}")
    print(f"STREAK={cache.get('streak', 0)}")
    # Favorited items as newline-separated
    favorited_tasks = cache.get('favorited_tasks', [])
    for task in favorited_tasks[:3]:
        print(f"FAVORITED_TASK={task}")
    favorited_projects = cache.get('favorited_projects', [])
    for project in favorited_projects[:2]:
        print(f"FAVORITED_PROJECT={project}")
except Exception as e:
    pass
PYTHON_EOF
      return 0
    fi
  fi
  
  return 1
}

# Made robust for different environments (work/home) with comprehensive error handling
show_dashboard() {
  # Enable error handling that doesn't exit on failures
  set +e
  
  # Initialize paths safely with error suppression
  # This prevents bad substitution errors from crashing the dashboard
  if command -v init_gtd_paths &>/dev/null; then
    init_gtd_paths 2>/dev/null || true
  fi
  
  # Try to read from cache first
  local cache_data=""
  local inbox_count=0
  local tasks_count=0
  local active_tasks_count=0
  local project_tasks_count=0
  local total_active_tasks=0
  local projects_count=0
  local areas_count=0
  local waiting_count=0
  local someday_count=0
  local suggestions_total=0
  local suggestions_high=0
  local suggestions_medium=0
  local suggestions_low=0
  local today_entries=0
  local streak=0
  local favorited_tasks=()
  local favorited_projects=()
  local cache_used=false
  
  if cache_data=$(read_dashboard_cache 2>/dev/null); then
    cache_used=true
    # Parse cache data
    while IFS='=' read -r key value; do
      case "$key" in
        INBOX_COUNT) inbox_count="$value" ;;
        TASKS_COUNT) tasks_count="$value" ;;
        ACTIVE_TASKS_COUNT) active_tasks_count="$value" ;;
        PROJECT_TASKS_COUNT) project_tasks_count="$value" ;;
        TOTAL_ACTIVE_TASKS) total_active_tasks="$value" ;;
        PROJECTS_COUNT) projects_count="$value" ;;
        AREAS_COUNT) areas_count="$value" ;;
        WAITING_COUNT) waiting_count="$value" ;;
        SOMEDAY_COUNT) someday_count="$value" ;;
        SUGGESTIONS_TOTAL) suggestions_total="$value" ;;
        SUGGESTIONS_HIGH) suggestions_high="$value" ;;
        SUGGESTIONS_MEDIUM) suggestions_medium="$value" ;;
        SUGGESTIONS_LOW) suggestions_low="$value" ;;
        TODAY_ENTRIES) today_entries="$value" ;;
        STREAK) streak="$value" ;;
        FAVORITED_TASK) favorited_tasks+=("$value") ;;
        FAVORITED_PROJECT) favorited_projects+=("$value") ;;
      esac
    done <<< "$cache_data"
  fi
  
  # Get current date/time with error handling
  local current_date=""
  local current_time=""
  local day_name=""
  
  if command -v date &>/dev/null; then
    current_date=$(gtd_get_today 2>/dev/null || echo "$(date +%Y-%m-%d 2>/dev/null || echo 'N/A')")
    current_time=$(gtd_get_current_time 2>/dev/null || echo "$(date +%H:%M 2>/dev/null || echo 'N/A')")
    day_name=$(date +"%A" 2>/dev/null || echo "")
  else
    current_date="N/A"
    current_time="N/A"
  fi
  
  echo ""
  gtd_section_divider "$CYAN" 2>/dev/null || echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "${BOLD}${CYAN}🎯 GTD Command Center${NC}" 2>/dev/null || echo "🎯 GTD Command Center"
  if [[ -n "$day_name" ]]; then
    echo -e "${CYAN}   ${day_name}, ${current_date} ${current_time}${NC}" 2>/dev/null || echo "   ${day_name}, ${current_date} ${current_time}"
  else
    echo -e "${CYAN}   ${current_date} ${current_time}${NC}" 2>/dev/null || echo "   ${current_date} ${current_time}"
  fi
  gtd_section_divider "$CYAN" 2>/dev/null || echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # System Status Section - Compact format
  echo -e "${BOLD}📊 System Status${NC}" 2>/dev/null || echo "📊 System Status"
  
  # Inbox count - use cache if available, otherwise calculate
  if [[ "$cache_used" != "true" ]]; then
    inbox_count=0
    if [[ -n "${INBOX_PATH:-}" ]] && [[ -d "${INBOX_PATH:-}" ]]; then
      # Use timeout if available to prevent hanging
      if command -v timeout &>/dev/null; then
        inbox_count=$(timeout 2 bash -c "gtd_get_cached_count 'inbox' '${INBOX_PATH}' '*.md' 5" 2>/dev/null || echo "0")
      else
        inbox_count=$(gtd_get_cached_count "inbox" "${INBOX_PATH}" "*.md" 5 2>/dev/null || echo "0")
      fi
      # Ensure it's numeric
      [[ "$inbox_count" =~ ^[0-9]+$ ]] || inbox_count=0
    fi
  fi
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${RED}📥${NC} ${BOLD}Inbox:${NC} ${inbox_count} ${YELLOW}→ Process first! (2)${NC}" 2>/dev/null || echo "  📥 Inbox: ${inbox_count} → Process first! (2)"
  else
    echo -e "  ${GREEN}✓${NC} ${BOLD}Inbox:${NC} Empty" 2>/dev/null || echo "  ✓ Inbox: Empty"
  fi
  
  # Active tasks count - use cache if available, otherwise calculate
  if [[ "$cache_used" != "true" ]]; then
    tasks_count=0
    if [[ -n "${TASKS_PATH:-}" ]] && [[ -d "${TASKS_PATH:-}" ]]; then
      if command -v timeout &>/dev/null; then
        tasks_count=$(timeout 2 bash -c "gtd_get_cached_count 'tasks' '${TASKS_PATH}' '*.md' 5" 2>/dev/null || echo "0")
      else
        tasks_count=$(gtd_get_cached_count "tasks" "${TASKS_PATH}" "*.md" 5 2>/dev/null || echo "0")
      fi
      [[ "$tasks_count" =~ ^[0-9]+$ ]] || tasks_count=0
    fi
    
    # Count active tasks (simplified - only if cache not available)
    active_tasks_count=0
    project_tasks_count=0
    if [[ -n "${TASKS_PATH:-}" ]] && [[ -d "${TASKS_PATH:-}" ]]; then
      # Quick count - limit to prevent hanging
      local count=0
      while IFS= read -r task_file && [[ $count -lt 100 ]]; do
        [[ ! -f "$task_file" ]] && continue
        local status=$(gtd_get_frontmatter_value "$task_file" "status" 2>/dev/null || echo "")
        if [[ "$status" == "active" ]]; then
          ((active_tasks_count++))
        fi
        ((count++))
      done < <(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | head -100)
    fi
    if [[ -n "${PROJECTS_PATH:-}" ]] && [[ -d "${PROJECTS_PATH:-}" ]]; then
      local count=0
      while IFS= read -r task_file && [[ $count -lt 100 ]]; do
        [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
        local status=$(gtd_get_frontmatter_value "$task_file" "status" 2>/dev/null || echo "")
        if [[ "$status" == "active" ]]; then
          ((project_tasks_count++))
        fi
        ((count++))
      done < <(find "${PROJECTS_PATH}" -name "*.md" -type f 2>/dev/null | head -100)
    fi
    total_active_tasks=$((active_tasks_count + project_tasks_count))
  fi
  
  echo -e "  ${CYAN}✅${NC} ${BOLD}Tasks:${NC} ${tasks_count}" 2>/dev/null || echo "  ✅ Tasks: ${tasks_count}"
  echo -e "  ${YELLOW}📋${NC} ${BOLD}Uncompleted tasks:${NC} ${total_active_tasks}" 2>/dev/null || echo "  📋 Uncompleted tasks: ${total_active_tasks}"
  
  # Project-related tasks (same as project_tasks_count from cache)
  local project_related_tasks=$project_tasks_count
  if [[ $project_related_tasks -gt 0 ]]; then
    echo -e "  ${CYAN}📁${NC} ${BOLD}Project-related tasks:${NC} ${project_related_tasks}" 2>/dev/null || echo "  📁 Project-related tasks: ${project_related_tasks}"
  fi
  
  # Projects and Areas count - use cache if available
  if [[ "$cache_used" != "true" ]]; then
    projects_count=0
    if [[ -n "${PROJECTS_PATH:-}" ]] && [[ -d "${PROJECTS_PATH:-}" ]]; then
      if command -v timeout &>/dev/null; then
        projects_count=$(timeout 2 bash -c "gtd_get_cached_count 'projects' '${PROJECTS_PATH}' 'projects' 5" 2>/dev/null || echo "0")
      else
        projects_count=$(gtd_get_cached_count "projects" "${PROJECTS_PATH}" "projects" 5 2>/dev/null || echo "0")
      fi
      [[ "$projects_count" =~ ^[0-9]+$ ]] || projects_count=0
    fi
    
    areas_count=0
    if [[ -n "${AREAS_PATH:-}" ]] && [[ -d "${AREAS_PATH:-}" ]]; then
      if command -v timeout &>/dev/null; then
        areas_count=$(timeout 2 bash -c "gtd_get_cached_count 'areas' '${AREAS_PATH}' '*.md' 5" 2>/dev/null || echo "0")
      else
        areas_count=$(gtd_get_cached_count "areas" "${AREAS_PATH}" "*.md" 5 2>/dev/null || echo "0")
      fi
      [[ "$areas_count" =~ ^[0-9]+$ ]] || areas_count=0
    fi
  fi
  echo -e "  ${CYAN}📁${NC} ${BOLD}Projects:${NC} ${projects_count}" 2>/dev/null || echo "  📁 Projects: ${projects_count}"
  echo -e "  ${CYAN}🎯${NC} ${BOLD}Areas:${NC} ${areas_count}" 2>/dev/null || echo "  🎯 Areas: ${areas_count}"
  
  # Smart Suggestions count - use cache if available
  if [[ "$cache_used" != "true" ]]; then
    suggestions_total=0
    suggestions_high=0
    suggestions_medium=0
    suggestions_low=0
    local suggestions_dir="${GTD_BASE_DIR:-$HOME/Documents/gtd}/suggestions"
    if [[ -d "$suggestions_dir" ]] && [[ -r "$suggestions_dir" ]]; then
      set +e
      suggestions_total=$(grep -l '"status"[[:space:]]*:[[:space:]]*"pending"' "$suggestions_dir"/*.json 2>/dev/null | wc -l | tr -d ' ' || echo "0")
      set -e
      [[ "$suggestions_total" =~ ^[0-9]+$ ]] || suggestions_total=0
    fi
  fi
  
  # Display suggestions with confidence breakdown
  if [[ $suggestions_total -gt 0 ]]; then
    local suggestion_details=""
    [[ $suggestions_high -gt 0 ]] && suggestion_details+="${GREEN}⭐${suggestions_high}${NC} "
    [[ $suggestions_medium -gt 0 ]] && suggestion_details+="${YELLOW}●${suggestions_medium}${NC} "
    [[ $suggestions_low -gt 0 ]] && suggestion_details+="${CYAN}○${suggestions_low}${NC}"
    echo -e "  ${CYAN}💡${NC} ${BOLD}Suggestions:${NC} ${suggestions_total} ${suggestion_details} ${YELLOW}→ (9)${NC}"
  fi
  
  echo ""
  
  # Quick Stats Section - Compact format
  # Wrap entire section in error handling to prevent crashes
  set +e  # Don't exit on errors in this section
  echo -e "${BOLD}📈 Quick Stats${NC}" 2>/dev/null || echo "📈 Quick Stats"
  
  # Logging streak (with aggressive timeout protection and error isolation)
  # Ensure DAILY_LOG_DIR is set before calling streak script
  if [[ -z "${DAILY_LOG_DIR:-}" ]]; then
    # Try to load from config file
    local daily_log_config="$HOME/code/dotfiles/zsh/.daily_log_config"
    if [[ ! -f "$daily_log_config" ]]; then
      daily_log_config="$HOME/code/personal/dotfiles/zsh/.daily_log_config"
    fi
    if [[ -f "$daily_log_config" ]]; then
      # Read DAILY_LOG_DIR from config file (handle both quoted and unquoted values)
      local log_dir=$(grep "^DAILY_LOG_DIR=" "$daily_log_config" 2>/dev/null | head -1 | cut -d'=' -f2- | tr -d '"' | tr -d "'" | sed "s|\$HOME|$HOME|g" | xargs)
      if [[ -n "$log_dir" ]]; then
        DAILY_LOG_DIR="$log_dir"
        export DAILY_LOG_DIR
      fi
    fi
    # Validate that DAILY_LOG_DIR exists and is accessible, fallback to default if not
    if [[ -n "${DAILY_LOG_DIR:-}" ]] && [[ ! -d "${DAILY_LOG_DIR:-}" ]]; then
      # Config directory doesn't exist, use default
      DAILY_LOG_DIR="$HOME/Documents/daily_logs"
      export DAILY_LOG_DIR
    fi
    # Final fallback to default if still not set
    DAILY_LOG_DIR="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}"
    export DAILY_LOG_DIR
  fi
  
  local streak_script=""
  if command -v gtd-log-stats &>/dev/null; then
    streak_script="gtd-log-stats"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  fi
  
  # Streak and Today's entries - use cache if available
  if [[ "$cache_used" != "true" ]]; then
    streak=0
    if [[ -n "$streak_script" ]]; then
      if command -v timeout &>/dev/null; then
        streak=$(timeout 5 bash -c "export DAILY_LOG_DIR=\"$DAILY_LOG_DIR\"; '$streak_script' streak 2>/dev/null" 2>/dev/null || echo "0")
      else
        streak=$("$streak_script" streak 2>/dev/null || echo "0")
      fi
      streak=$(echo "$streak" | tr -d '[:space:]' | head -c 10)
      [[ ! "$streak" =~ ^[0-9]+$ ]] && streak=0
    fi
    
    today_entries=0
    if command -v date &>/dev/null; then
      local today=""
      if command -v timeout &>/dev/null; then
        today=$(timeout 1 bash -c "gtd_get_today 2>/dev/null || date +%Y-%m-%d 2>/dev/null" 2>/dev/null || echo "")
      else
        today=$(gtd_get_today 2>/dev/null || date +%Y-%m-%d 2>/dev/null || echo "")
      fi
      if [[ -n "$today" ]] && [[ -n "${DAILY_LOG_DIR:-}" ]] && [[ -d "${DAILY_LOG_DIR:-}" ]]; then
        local today_log="${DAILY_LOG_DIR}/${today}.md"
        if [[ -f "$today_log" ]] && [[ -r "$today_log" ]]; then
          if command -v timeout &>/dev/null; then
            today_entries=$(timeout 1 grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
          else
            today_entries=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
          fi
          [[ "$today_entries" =~ ^[0-9]+$ ]] || today_entries=0
        fi
      fi
    fi
  fi
  
  # Display streak
  if [[ $streak -gt 0 ]]; then
    echo -e "  ${GREEN}🔥${NC} ${BOLD}Streak:${NC} ${streak} day(s)" 2>/dev/null || echo "  🔥 Streak: ${streak} day(s)"
  else
    echo -e "  ${YELLOW}📝${NC} ${BOLD}Streak:${NC} Start logging!" 2>/dev/null || echo "  📝 Streak: Start logging!"
  fi
  echo -e "  ${CYAN}📝${NC} ${BOLD}Today:${NC} ${today_entries} entries" 2>/dev/null || echo "  📝 Today: ${today_entries} entries"
  
  # Waiting for items (cached) - with aggressive error handling
  local waiting_count=0
  if [[ -n "${WAITING_PATH:-}" ]] && [[ -d "${WAITING_PATH:-}" ]] && [[ -r "${WAITING_PATH:-}" ]]; then
    if command -v timeout &>/dev/null; then
      waiting_count=$(timeout 1 bash -c "gtd_get_cached_count 'waiting' '${WAITING_PATH}' '*.md' 5" 2>/dev/null || echo "0")
    else
      waiting_count=$(gtd_get_cached_count "waiting" "${WAITING_PATH}" "*.md" 5 2>/dev/null || echo "0")
    fi
    # Ensure it's numeric
    [[ "$waiting_count" =~ ^[0-9]+$ ]] || waiting_count=0
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳${NC} ${BOLD}Waiting:${NC} ${waiting_count}" 2>/dev/null || echo "  ⏳ Waiting: ${waiting_count}"
  fi
  
  # Someday/Maybe items (cached) - with aggressive error handling
  local someday_count=0
  if [[ -n "${SOMEDAY_PATH:-}" ]] && [[ -d "${SOMEDAY_PATH:-}" ]] && [[ -r "${SOMEDAY_PATH:-}" ]]; then
    if command -v timeout &>/dev/null; then
      someday_count=$(timeout 1 bash -c "gtd_get_cached_count 'someday' '${SOMEDAY_PATH}' '*.md' 5" 2>/dev/null || echo "0")
    else
      someday_count=$(gtd_get_cached_count "someday" "${SOMEDAY_PATH}" "*.md" 5 2>/dev/null || echo "0")
    fi
    # Ensure it's numeric
    [[ "$someday_count" =~ ^[0-9]+$ ]] || someday_count=0
  fi
  if [[ $someday_count -gt 0 ]]; then
    echo -e "  ${MAGENTA}💭${NC} ${BOLD}Someday:${NC} ${someday_count}" 2>/dev/null || echo "  💭 Someday: ${someday_count}"
  fi
  set -e  # Re-enable error handling
  
  echo ""
  
  # Smart Defaults Section - with aggressive error handling and timeout
  # Only show if function exists and directories are available
  if declare -f show_smart_defaults &>/dev/null; then
    set +e
    # Check if required paths exist before calling
    if [[ -n "${GTD_BASE_DIR:-}" ]] && [[ -d "${GTD_BASE_DIR:-}" ]] && [[ -r "${GTD_BASE_DIR:-}" ]]; then
      # Use timeout if available to prevent hanging
      if command -v timeout &>/dev/null; then
        timeout 2 bash -c "show_smart_defaults" 2>/dev/null || true
      else
        show_smart_defaults 2>/dev/null || true
      fi
      
      # Show smart tips (occasionally, based on usage patterns)
      if declare -f show_smart_tips &>/dev/null; then
        if command -v timeout &>/dev/null; then
          timeout 2 bash -c "show_smart_tips" 2>/dev/null || true
        else
          show_smart_tips 2>/dev/null || true
        fi
      fi
    fi
    set -e
  fi
  
  # Quick Actions Section - Compact format
  echo -e "${BOLD}⚡ Quick Actions${NC}" 2>/dev/null || echo "⚡ Quick Actions"
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⚠️${NC} ${BOLD}${inbox_count}${NC} inbox → Press ${BOLD}2${NC}" 2>/dev/null || echo "  ⚠️ ${inbox_count} inbox → Press 2"
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳${NC} ${waiting_count} waiting → Review (6)" 2>/dev/null || echo "  ⏳ ${waiting_count} waiting → Review (6)"
  fi
  echo -e "  ${CYAN}💡${NC} 'What now?' → ${BOLD}40${NC}" 2>/dev/null || echo "  💡 'What now?' → 40"
  echo -e "  ${CYAN}📝${NC} Daily log → ${BOLD}15${NC}" 2>/dev/null || echo "  📝 Daily log → 15"
  echo -e "  ${CYAN}📊${NC} Full status → ${BOLD}17${NC}" 2>/dev/null || echo "  📊 Full status → 17"
  
  # Favorited Items Section - use cache if available
  # Use timeout to prevent blocking if these operations are slow
  if [[ "$cache_used" != "true" ]]; then
    favorited_tasks=()
    favorited_projects=()
    # Get favorited tasks (limit to 3 for display)
    if declare -f get_favorited_tasks &>/dev/null; then
      local task_count=0
      if command -v timeout &>/dev/null; then
        while IFS= read -r task_file && [[ $task_count -lt 3 ]]; do
          [[ -n "$task_file" ]] && favorited_tasks+=("$task_file") && ((task_count++))
        done < <(timeout 2 get_favorited_tasks 2>/dev/null || true)
      else
        while IFS= read -r task_file && [[ $task_count -lt 3 ]]; do
          [[ -n "$task_file" ]] && favorited_tasks+=("$task_file") && ((task_count++))
        done < <(get_favorited_tasks 2>/dev/null || true)
      fi
    fi
    
    # Get favorited projects (limit to 2 for display)
    if declare -f get_favorited_projects &>/dev/null; then
      local project_count=0
      if command -v timeout &>/dev/null; then
        while IFS= read -r project_dir && [[ $project_count -lt 2 ]]; do
          [[ -n "$project_dir" ]] && favorited_projects+=("$project_dir") && ((project_count++))
        done < <(timeout 2 get_favorited_projects 2>/dev/null || true)
      else
        while IFS= read -r project_dir && [[ $project_count -lt 2 ]]; do
          [[ -n "$project_dir" ]] && favorited_projects+=("$project_dir") && ((project_count++))
        done < <(get_favorited_projects 2>/dev/null || true)
      fi
    fi
  fi
  
  # Display favorited items with quick access numbers
  # Use safe array access to avoid unbound variable errors
  local favorited_tasks_count=${#favorited_tasks[@]:-0}
  local favorited_projects_count=${#favorited_projects[@]:-0}
  if [[ $favorited_tasks_count -gt 0 ]] || [[ $favorited_projects_count -gt 0 ]]; then
    echo ""
    echo -e "  ${BOLD}${YELLOW}⭐ Favorited Items${NC}" 2>/dev/null || echo "  ⭐ Favorited Items"
    
    # Show favorited tasks (up to 3, matching main menu)
    local task_index=0
    # Safely iterate over array (handle empty arrays)
    if [[ $favorited_tasks_count -gt 0 ]]; then
      for task_file in "${favorited_tasks[@]}"; do
        [[ ! -f "$task_file" ]] && continue
      local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
      if [[ ${#task_name} -gt 35 ]]; then
        task_name="${task_name:0:32}..."
      fi
      local menu_num=$((900 + task_index))  # Start at 900 to avoid conflicts and allow growth
      echo -e "    ${GREEN}${menu_num})${NC} ⭐ ${task_name}" 2>/dev/null || echo "    ${menu_num}) ⭐ ${task_name}"
        ((task_index++))
        if [[ $task_index -ge 3 ]]; then
          break
        fi
      done
    fi
    
    # Show favorited projects (up to 2, matching main menu)
    local project_index=0
    # Safely iterate over array (handle empty arrays)
    if [[ $favorited_projects_count -gt 0 ]]; then
      for project_dir in "${favorited_projects[@]}"; do
      [[ ! -d "$project_dir" ]] && continue
      local project_slug=$(basename "$project_dir")
      local project_readme="${project_dir}/README.md"
      local project_name=""
      
      if [[ -f "$project_readme" ]]; then
        # Try to get name from frontmatter first
        project_name=$(gtd_get_frontmatter_value "$project_readme" "name" 2>/dev/null || echo "")
        [[ -z "$project_name" ]] && project_name=$(gtd_get_frontmatter_value "$project_readme" "project" 2>/dev/null || echo "")
        
        # If still no name, try to get from H1 heading
        if [[ -z "$project_name" ]]; then
          project_name=$(head -20 "$project_readme" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")
        fi
      fi
      
      # Final fallback: format the slug nicely
      if [[ -z "$project_name" ]]; then
        project_name=$(echo "$project_slug" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
      fi
      
      if [[ ${#project_name} -gt 35 ]]; then
        project_name="${project_name:0:32}..."
      fi
        local menu_num=$((903 + project_index))  # Start at 903 to avoid conflicts and allow growth
        echo -e "    ${GREEN}${menu_num})${NC} ⭐ ${project_name}" 2>/dev/null || echo "    ${menu_num}) ⭐ ${project_name}"
        ((project_index++))
        if [[ $project_index -ge 2 ]]; then
          break
        fi
      done
    fi
  fi
  
  echo ""
  
  # Web Interface Hint - Check if web service is running
  check_web_service_hint() {
    local web_status=""
    local web_running=false
    local web_installed=false
    
    # Check if backend API is accessible
    if curl -s --max-time 1 http://localhost:8000/api/health >/dev/null 2>&1; then
      web_running=true
    fi
    
    # Check if service is installed
    if [[ "$(uname)" == "Darwin" ]]; then
      if [[ -f "${HOME}/Library/LaunchAgents/com.gtd.wizard-api.plist" ]]; then
        web_installed=true
      fi
    else
      if [[ -f "/etc/systemd/system/gtd-wizard-api.service" ]]; then
        web_installed=true
      fi
    fi
    
    # Show hint based on status
    if [[ "$web_running" == "true" ]]; then
      echo -e "  ${GREEN}🌐${NC} Web Interface: ${GREEN}Running${NC} → http://localhost:8000" 2>/dev/null || echo "  🌐 Web Interface: Running → http://localhost:8000"
    elif [[ "$web_installed" == "true" ]]; then
      echo -e "  ${YELLOW}🌐${NC} Web Interface: ${YELLOW}Installed but not running${NC} → Start via ${BOLD}27${NC} → ${BOLD}16${NC}" 2>/dev/null || echo "  🌐 Web Interface: Installed but not running → Start via 27 → 16"
    else
      # Only show hint occasionally to avoid being annoying
      # Show hint ~20% of the time (using seconds as random seed)
      local seconds=$(date +%S | sed 's/^0//')
      if [[ $((seconds % 5)) -eq 0 ]]; then
        echo -e "  ${CYAN}💡${NC} Web Interface available → Install via ${BOLD}27${NC} → ${BOLD}16${NC}" 2>/dev/null || echo "  💡 Web Interface available → Install via 27 → 16"
      fi
    fi
  }
  
  # Add web service hint (with error handling)
  set +e
  check_web_service_hint 2>/dev/null || true
  set -e
  
  # Background Worker Status - Check all workers with icons (uses cache if available)
  check_background_worker_hint() {
    local running_count=0
    local not_running_count=0
    local wrong_version_count=0
    local workers_status=()
    local wrong_version_workers=()
    local use_cache=false
    
    # Try to read from cache first
    local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
    if [[ -f "$cache_file" ]]; then
      local cache_age=0
      if command -v stat &>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        else
          cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        fi
      fi
      
      # Cache is valid if less than 30 seconds old
      if [[ $cache_age -lt 30 ]]; then
        # Try to read worker status from cache
        local cache_workers=$(python3 <<PYTHON_EOF 2>/dev/null
import json
import sys
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    workers = cache.get("background_workers", {})
    if workers:
        workers_data = workers.get("workers", {})
        summary = workers.get("summary", {})
        # Output as shell-friendly format
        for name, status_info in workers_data.items():
            status = status_info.get("status", "stopped")
            is_wrong = status_info.get("is_wrong_version", False)
            print(f"{name}|{status}|{is_wrong}")
        print(f"SUMMARY|{summary.get('running', 0)}|{summary.get('stopped', 0)}|{summary.get('wrong_version', 0)}")
except Exception:
    pass
PYTHON_EOF
        )
        
        if [[ -n "$cache_workers" ]]; then
          use_cache=true
          # Parse summary line first
          local summary_line=$(echo "$cache_workers" | grep "^SUMMARY|")
          if [[ -n "$summary_line" ]]; then
            running_count=$(echo "$summary_line" | cut -d'|' -f2)
            not_running_count=$(echo "$summary_line" | cut -d'|' -f3)
            wrong_version_count=$(echo "$summary_line" | cut -d'|' -f4)
          fi
          
          # Parse cache data (skip summary line)
          while IFS='|' read -r name status is_wrong_str; do
            if [[ "$name" == "SUMMARY" ]]; then
              continue
            fi
            
            # Map worker names to icons
            local worker_icon=""
            case "$name" in
              "Deep Analysis") worker_icon="🔍" ;;
              "Vector") worker_icon="📊" ;;
              "Advice") worker_icon="💬" ;;
              "Task Org") worker_icon="✅" ;;
              "Badge") worker_icon="🏅" ;;
              "Brain Sync") worker_icon="🧠" ;;
              "Dashboard Cache") worker_icon="📈" ;;
              *) worker_icon="⚙️" ;;
            esac
            
            local status_icon=""
            local status_color=""
            if [[ "$status" == "running" ]]; then
              status_icon="✅"
              status_color="${GREEN}"
            elif [[ "$status" == "wrong_version" ]]; then
              status_icon="⚠️"
              status_color="${YELLOW}"
              wrong_version_workers+=("$name")
            else
              status_icon="❌"
              status_color="${CYAN}"
            fi
            
            local worker_line="${worker_icon} ${name}: ${status_color}${status_icon}${NC}"
            workers_status+=("$worker_line")
          done <<< "$cache_workers"
        fi
      fi
    fi
    
    # Fallback to direct check if cache not available or invalid
    if [[ "$use_cache" == "false" ]]; then
      # Define all workers to check (icon, name, pattern, wrong_pattern)
      # Format: "Icon|Display Name|process_pattern|wrong_pattern"
      local workers=(
        "🔍|Deep Analysis|gtd_deep_analysis_worker.py|"
        "📊|Vector|gtd_vector_worker.py|"
        "💬|Advice|gtd_advice_worker.py|gtd-advice-worker.*daemon"
        "✅|Task Org|gtd_task_organize_worker.py|"
        "🏅|Badge|gtd_badge_suggestion_worker.py|"
        "🧠|Brain Sync|gtd_second_brain_sync_worker.py|"
        "📈|Dashboard Cache|gtd_dashboard_cache_worker.py|"
      )
      
      # Check each worker and build status display
      for worker_info in "${workers[@]}"; do
        # Parse worker info (bash 3.2 compatible - no <<<)
        local worker_icon=$(echo "$worker_info" | cut -d'|' -f1)
        local worker_name=$(echo "$worker_info" | cut -d'|' -f2)
        local worker_pattern=$(echo "$worker_info" | cut -d'|' -f3)
        local wrong_pattern=$(echo "$worker_info" | cut -d'|' -f4)
        local is_running=false
        local is_wrong_version=false
        local status_icon=""
        local status_color=""
        
        # Check for correct worker first
        if pgrep -f "$worker_pattern" >/dev/null 2>&1; then
          local pid=$(pgrep -f "$worker_pattern" | head -1)
          if ps -p "$pid" >/dev/null 2>&1; then
            is_running=true
            running_count=$((running_count + 1))
            status_icon="✅"
            status_color="${GREEN}"
          fi
        fi
        
        # Check for wrong version (if pattern specified)
        if [[ -n "$wrong_pattern" ]] && pgrep -f "$wrong_pattern" >/dev/null 2>&1; then
          local wrong_pid=$(pgrep -f "$wrong_pattern" | head -1)
          if ps -p "$wrong_pid" >/dev/null 2>&1; then
            is_wrong_version=true
            wrong_version_count=$((wrong_version_count + 1))
            wrong_version_workers+=("$worker_name")
            status_icon="⚠️"
            status_color="${YELLOW}"
          fi
        fi
        
        # Set status for not running
        if [[ "$is_running" == "false" ]] && [[ "$is_wrong_version" == "false" ]]; then
          not_running_count=$((not_running_count + 1))
          status_icon="❌"
          status_color="${CYAN}"
        fi
        
        # Build worker status line
        local worker_line="${worker_icon} ${worker_name}: ${status_color}${status_icon}${NC}"
        workers_status+=("$worker_line")
      done
    fi
    
    # Display worker statuses
    if [[ ${#workers_status[@]} -gt 0 ]]; then
      echo -e "  ${GREEN}⚙️${NC} Background Workers:" 2>/dev/null || echo "  ⚙️ Background Workers:"
      for worker_line in "${workers_status[@]}"; do
        echo -e "    $worker_line" 2>/dev/null || echo "    $worker_line"
      done
      
      # Show summary if there are issues
      if [[ $wrong_version_count -gt 0 ]] || [[ $not_running_count -gt 0 ]]; then
        local summary_parts=()
        if [[ $running_count -gt 0 ]]; then
          summary_parts+=("${GREEN}${running_count} running${NC}")
        fi
        if [[ $wrong_version_count -gt 0 ]]; then
          summary_parts+=("${YELLOW}${wrong_version_count} wrong version${NC}")
        fi
        if [[ $not_running_count -gt 0 ]]; then
          summary_parts+=("${CYAN}${not_running_count} stopped${NC}")
        fi
        
        # Join summary parts
        local summary_text=""
        local first_summary=1
        for part in "${summary_parts[@]}"; do
          if [[ $first_summary -eq 1 ]]; then
            summary_text="$part"
            first_summary=0
          else
            summary_text="$summary_text, $part"
          fi
        done
        echo -e "    Summary: $summary_text" 2>/dev/null || echo "    Summary: $summary_text"
      fi
    else
      # Only show hint occasionally if no workers detected at all
      local seconds=$(date +%S | sed 's/^0//')
      if [[ $((seconds % 5)) -eq 0 ]]; then
        echo -e "  ${CYAN}💡${NC} Background Workers available → Check status via ${BOLD}17${NC} → ${BOLD}3${NC}" 2>/dev/null || echo "  💡 Background Workers available → Check status via 17 → 3"
      fi
    fi
  }
  
  # Add background worker status hint (with error handling)
  set +e
  check_background_worker_hint 2>/dev/null || true
  set -e
  
  # GCalCLI Connection Status - Check connection status (uses cache if available)
  check_gcalcli_hint() {
    local gcalcli_status=""
    local gcalcli_installed=false
    local gcalcli_connected=false
    local gcalcli_error=""
    local use_cache=false
    
    # Try to read from cache first
    local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
    if [[ -f "$cache_file" ]]; then
      local cache_age=0
      if command -v stat &>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        else
          cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        fi
      fi
      
      # Cache is valid if less than 30 seconds old
      if [[ $cache_age -lt 30 ]]; then
        # Try to read gcalcli status from cache
        local cache_gcalcli=$(python3 <<PYTHON_EOF 2>/dev/null
import json
import sys
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    gcalcli = cache.get("gcalcli_status", {})
    if gcalcli:
        installed = gcalcli.get("installed", False)
        connected = gcalcli.get("connected", False)
        error = gcalcli.get("error", "")
        # Convert Python booleans to lowercase strings for bash
        installed_str = "true" if installed else "false"
        connected_str = "true" if connected else "false"
        error_str = str(error) if error else ""
        print(f"{installed_str}|{connected_str}|{error_str}")
except Exception:
    pass
PYTHON_EOF
        )
        
        if [[ -n "$cache_gcalcli" ]]; then
          use_cache=true
          gcalcli_installed=$(echo "$cache_gcalcli" | cut -d'|' -f1)
          gcalcli_connected=$(echo "$cache_gcalcli" | cut -d'|' -f2)
          gcalcli_error=$(echo "$cache_gcalcli" | cut -d'|' -f3)
        fi
      fi
    fi
    
    # Fallback to direct check if cache not available or invalid
    if [[ "$use_cache" == "false" ]]; then
      # Check if gcalcli is installed
      # First try command -v (checks PATH)
      local gcalcli_path=""
      if command -v gcalcli &>/dev/null; then
        gcalcli_path="gcalcli"
      else
        # Check common homebrew locations
        if [[ -x "/opt/homebrew/bin/gcalcli" ]]; then
          gcalcli_path="/opt/homebrew/bin/gcalcli"
        elif [[ -x "/usr/local/bin/gcalcli" ]]; then
          gcalcli_path="/usr/local/bin/gcalcli"
        fi
      fi
      
      if [[ -n "$gcalcli_path" ]]; then
        gcalcli_installed=true
        
        # Test connection with timeout (5 seconds max)
        local test_output=""
        if command -v timeout &>/dev/null; then
          test_output=$(timeout 5 "$gcalcli_path" list 2>&1)
          local exit_code=$?
        else
          # Fallback: use gcalcli directly (may hang)
          test_output=$("$gcalcli_path" list 2>&1)
          local exit_code=$?
        fi
        
        if [[ $exit_code -eq 0 ]] && [[ -n "$test_output" ]]; then
          gcalcli_connected=true
        else
          gcalcli_connected=false
          # Try to determine error type (check for comprehensive list of auth errors)
          if echo "$test_output" | grep -qiE "invalid_grant|Token has been expired|Token has been revoked|authentication|oauth|credentials|RefreshError|401|403|unauthorized|access denied|permission denied"; then
            gcalcli_error="not_authenticated"
          elif echo "$test_output" | grep -qi "network\|connection\|timeout"; then
            gcalcli_error="network_error"
          else
            gcalcli_error="unknown_error"
          fi
        fi
      else
        gcalcli_installed=false
        gcalcli_error="not_installed"
      fi
    fi
    
    # Display gcalcli status
    local status_icon=""
    local status_color=""
    local status_text=""
    
    if [[ "$gcalcli_installed" == "true" ]]; then
      if [[ "$gcalcli_connected" == "true" ]]; then
        status_icon="✅"
        status_color="${GREEN}"
        status_text="Connected"
      else
        status_icon="⚠️"
        status_color="${YELLOW}"
        case "$gcalcli_error" in
          "not_authenticated")
            status_text="Not authenticated"
            ;;
          "network_error")
            status_text="Network error"
            ;;
          "timeout")
            status_text="Connection timeout"
            ;;
          *)
            status_text="Connection failed"
            ;;
        esac
      fi
    else
      status_icon="❌"
      status_color="${CYAN}"
      status_text="Not installed"
    fi
    
    echo -e "  ${CYAN}📅${NC} GCalCLI: ${status_color}${status_icon} ${status_text}${NC}" 2>/dev/null || echo "  📅 GCalCLI: ${status_icon} ${status_text}"
    
    # Show hint if not connected
    if [[ "$gcalcli_installed" == "true" ]] && [[ "$gcalcli_connected" == "false" ]]; then
      case "$gcalcli_error" in
        "not_authenticated")
          echo -e "    ${YELLOW}💡${NC} Authentication expired → Re-auth via ${BOLD}29${NC} → ${BOLD}12${NC} or run: ${BOLD}gcalcli init${NC}" 2>/dev/null || echo "    💡 Authentication expired → Re-auth via 29 → 12 or run: gcalcli init"
          ;;
        "network_error"|"timeout")
          echo -e "    ${YELLOW}💡${NC} Check network connection" 2>/dev/null || echo "    💡 Check network connection"
          ;;
      esac
    elif [[ "$gcalcli_installed" == "false" ]]; then
      echo -e "    ${CYAN}💡${NC} Install with: ${BOLD}brew install gcalcli${NC}" 2>/dev/null || echo "    💡 Install with: brew install gcalcli"
    fi
  }
  
  # Add gcalcli status hint (with error handling)
  set +e
  check_gcalcli_hint 2>/dev/null || true
  set -e
  
  # Check for events today (uses cache if available)
  check_today_events_hint() {
    local has_events_today=false
    local event_count=0
    local use_cache=false
    
    # Try to read from cache first
    local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
    if [[ -f "$cache_file" ]]; then
      local cache_age=0
      if command -v stat &>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
          cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
        else
          cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        fi
      fi
      
      # Cache is valid if less than 30 seconds old
      if [[ $cache_age -lt 30 ]]; then
        # Try to read today's events from cache
        local cache_events=$(python3 <<PYTHON_EOF 2>/dev/null
import json
import sys
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    today_events = cache.get("today_events", {})
    if today_events:
        has_events = today_events.get("has_events", False)
        event_count = today_events.get("event_count", 0)
        error = today_events.get("error")
        # Convert Python booleans to lowercase strings for bash
        has_events_str = "true" if has_events else "false"
        event_count_str = str(event_count)
        error_str = str(error) if error else ""
        print(f"{has_events_str}|{event_count_str}|{error_str}")
except Exception:
    pass
PYTHON_EOF
        )
        
        if [[ -n "$cache_events" ]]; then
          use_cache=true
          local has_events_str=$(echo "$cache_events" | cut -d'|' -f1)
          local event_count_str=$(echo "$cache_events" | cut -d'|' -f2)
          local error_str=$(echo "$cache_events" | cut -d'|' -f3)
          
          if [[ "$has_events_str" == "true" ]]; then
            has_events_today=true
            event_count="$event_count_str"
          fi
        fi
      fi
    fi
    
    # Fallback to direct check if cache not available or invalid
    if [[ "$use_cache" == "false" ]]; then
      # Only check if gcalcli is installed and connected
      local gcalcli_path=""
      if command -v gcalcli &>/dev/null; then
        gcalcli_path="gcalcli"
      elif [[ -x "/opt/homebrew/bin/gcalcli" ]]; then
        gcalcli_path="/opt/homebrew/bin/gcalcli"
      elif [[ -x "/usr/local/bin/gcalcli" ]]; then
        gcalcli_path="/usr/local/bin/gcalcli"
      fi
      
      if [[ -n "$gcalcli_path" ]]; then
        # Quick test to see if gcalcli is connected (with timeout)
        local test_output=""
        if command -v timeout &>/dev/null; then
          test_output=$(timeout 3 "$gcalcli_path" list 2>&1)
          local test_exit=$?
        else
          test_output=$("$gcalcli_path" list 2>&1)
          local test_exit=$?
        fi
        
        if [[ $test_exit -eq 0 ]] && [[ -n "$test_output" ]]; then
          # Get events for today (with timeout)
          local today_events=""
          if command -v timeout &>/dev/null; then
            today_events=$(timeout 5 "$gcalcli_path" agenda "today" "today" 2>/dev/null || echo "")
          else
            today_events=$("$gcalcli_path" agenda "today" "today" 2>/dev/null || echo "")
          fi
          
          # Check if there are actual events (not just "No Events Found")
          if [[ -n "$today_events" ]] && ! echo "$today_events" | grep -qiE "No Events Found|No events"; then
            # Count events (rough count - lines that look like events)
            event_count=$(echo "$today_events" | grep -cE "^[A-Z][a-z]{2} [A-Z][a-z]{2} +[0-9]" || echo "0")
            if [[ $event_count -gt 0 ]]; then
              has_events_today=true
            fi
          fi
        fi
      fi
    fi
    
    # Display indicator if there are events today
    if [[ "$has_events_today" == "true" ]]; then
      if [[ $event_count -eq 1 ]]; then
        echo -e "    ${YELLOW}📅${NC} You have ${BOLD}1 event${NC} today → View via ${BOLD}29${NC} → ${BOLD}13${NC} or ${BOLD}gtd-calendar view today${NC}" 2>/dev/null || echo "    📅 You have 1 event today → View via 29 → 13 or gtd-calendar view today"
      else
        echo -e "    ${YELLOW}📅${NC} You have ${BOLD}${event_count} events${NC} today → View via ${BOLD}29${NC} → ${BOLD}13${NC} or ${BOLD}gtd-calendar view today${NC}" 2>/dev/null || echo "    📅 You have ${event_count} events today → View via 29 → 13 or gtd-calendar view today"
      fi
    fi
  }
  
  # Add today's events hint (with error handling)
  set +e
  check_today_events_hint 2>/dev/null || true
  set -e
  
  echo ""
  
  gtd_section_divider "$CYAN" 2>/dev/null || echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  
  # Re-enable error handling and return successfully
  set -e
  return 0
}

# Compact dashboard - one-line status display
# Load dashboard cache values (returns values via stdout for eval)
get_dashboard_cache_values() {
  local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
  local cache_age=0
  
  # Check if cache exists and is recent (within 60 seconds)
  if [[ -f "$cache_file" ]]; then
    if command -v stat &>/dev/null; then
      # Get file modification time
      if [[ "$OSTYPE" == "darwin"* ]]; then
        cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
      else
        cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
      fi
    fi
    
    # Use cache if it's less than 60 seconds old
    if [[ $cache_age -lt 60 ]]; then
      # Parse JSON and output variable assignments
      python3 2>/dev/null <<PYTHON_SCRIPT
import json
import sys
import os

try:
    cache_file = "$cache_file"
    if os.path.exists(cache_file):
        with open(cache_file, 'r') as f:
            cache = json.load(f)
            
        # Extract values and output as bash variable assignments
        print(f"inbox_count={cache.get('inbox_count', 0)}")
        print(f"tasks_count={cache.get('total_active_tasks', cache.get('active_tasks_count', 0) + cache.get('project_tasks_count', 0))}")
        print(f"projects_count={cache.get('projects_count', 0)}")
        print(f"areas_count={cache.get('areas_count', 0)}")
        
        # Suggestions
        suggestions = cache.get('suggestions', {})
        print(f"suggestions_count={suggestions.get('total', 0)}")
        
        # Ready for review total
        review_counts = cache.get('ready_for_review_counts', {})
        review_total = sum([
            review_counts.get('inbox', 0),
            review_counts.get('overdue', 0),
            review_counts.get('blocked', 0),
            review_counts.get('waiting', 0),
            review_counts.get('stalled_projects', 0),
            review_counts.get('ai_suggestions', 0),
            review_counts.get('advice_results', 0),
            review_counts.get('project_suggestions', 0),
            review_counts.get('knowledge_org', 0)
        ])
        print(f"review_total={review_total}")
        
        sys.exit(0)
except Exception as e:
    sys.exit(1)
PYTHON_SCRIPT
      return $?
    fi
  fi
  
  return 1
}

show_compact_dashboard() {
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  
  # Try to load from cache first
  local inbox_count=0
  local tasks_count=0
  local projects_count=0
  local areas_count=0
  local suggestions_count=0
  local review_total=0
  
  # Load cache values if available
  local cache_output
  cache_output=$(get_dashboard_cache_values 2>/dev/null)
  if [[ $? -eq 0 ]] && [[ -n "$cache_output" ]]; then
    # Eval the variable assignments from cache
    eval "$cache_output"
  else
    # Fallback to direct calculation if cache unavailable
    inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
    if [[ -d "${TASKS_PATH}" ]]; then
      tasks_count=$(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ -d "${PROJECTS_PATH}" ]]; then
      projects_count=$(ls -1 "${PROJECTS_PATH}"/*/README.md 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ -d "${AREAS_PATH}" ]]; then
      areas_count=$(ls -1 "${AREAS_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    local suggestions_dir="$HOME/Documents/gtd/suggestions"
    if [[ -d "$suggestions_dir" ]]; then
      while IFS= read -r suggestion_file; do
        local status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$suggestion_file" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
        if [[ "$status" == "pending" ]]; then
          ((suggestions_count++))
        fi
      done < <(find "$suggestions_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null)
    fi
  fi
  
  # Highlight lightbulb if there are items ready for review
  local lightbulb_icon="💡"
  local lightbulb_color="${BOLD}"
  if [[ ${review_total:-0} -gt 0 ]]; then
    lightbulb_color="${BOLD}${YELLOW}"  # Yellow highlight when items need review
  fi
  
  # Show review_total count next to lightbulb (not suggestions_count)
  local review_display=${review_total:-0}
  
  # One-line display
  echo -e "${BOLD}${CYAN}🎯 GTD${NC} ${current_date} ${current_time} | ${RED}📥${NC} ${inbox_count} | ${CYAN}✅${NC} ${tasks_count} | ${CYAN}📁${NC} ${projects_count} | ${CYAN}🎯${NC} ${areas_count} | ${lightbulb_color}${lightbulb_icon}${NC} ${review_display}"
}

# Plain compact dashboard - no colors (for tmux status bar)
show_plain_dashboard() {
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  
  # Try to load from cache first
  local inbox_count=0
  local tasks_count=0
  local projects_count=0
  local areas_count=0
  local suggestions_count=0
  local review_total=0
  
  # Load cache values if available
  local cache_output
  cache_output=$(get_dashboard_cache_values 2>/dev/null)
  if [[ $? -eq 0 ]] && [[ -n "$cache_output" ]]; then
    # Eval the variable assignments from cache
    eval "$cache_output"
  else
    # Fallback to direct calculation if cache unavailable
    inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
    if [[ -d "${TASKS_PATH}" ]]; then
      tasks_count=$(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ -d "${PROJECTS_PATH}" ]]; then
      projects_count=$(ls -1 "${PROJECTS_PATH}"/*/README.md 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ -d "${AREAS_PATH}" ]]; then
      areas_count=$(ls -1 "${AREAS_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    local suggestions_dir="$HOME/Documents/gtd/suggestions"
    if [[ -d "$suggestions_dir" ]]; then
      while IFS= read -r suggestion_file; do
        local status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$suggestion_file" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
        if [[ "$status" == "pending" ]]; then
          ((suggestions_count++))
        fi
      done < <(find "$suggestions_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null)
    fi
  fi
  
  # Highlight lightbulb if there are items ready for review (use ! for emphasis in plain mode)
  local lightbulb_icon="💡"
  if [[ ${review_total:-0} -gt 0 ]]; then
    lightbulb_icon="💡!"  # Add exclamation for emphasis in plain mode
  fi
  
  # Show review_total count next to lightbulb (not suggestions_count)
  local review_display=${review_total:-0}
  
  # One-line display WITHOUT colors
  echo "🎯 GTD ${current_date} ${current_time} | 📥 ${inbox_count} | ✅ ${tasks_count} | 📁 ${projects_count} | 🎯 ${areas_count} | ${lightbulb_icon} ${review_display}"
}

# Show earned badges
show_earned_badges() {
  # Get GTD base directory - try multiple sources
  local gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
  if [[ -z "$GTD_BASE_DIR" ]]; then
    # Try loading from config
    local gtd_config="$HOME/.gtd_config"
    if [[ -f "$HOME/code/dotfiles/zsh/.gtd_config" ]]; then
      gtd_config="$HOME/code/dotfiles/zsh/.gtd_config"
    elif [[ -f "$HOME/code/personal/dotfiles/zsh/.gtd_config" ]]; then
      gtd_config="$HOME/code/personal/dotfiles/zsh/.gtd_config"
    fi
    if [[ -f "$gtd_config" ]]; then
      source "$gtd_config" 2>/dev/null
      gtd_base="${GTD_BASE_DIR:-$HOME/Documents/gtd}"
    fi
  fi
  
  local gamification_file="${gtd_base}/.gtd/gamification/gamification.json"
  
  # Check if gamification file exists
  if [[ ! -f "$gamification_file" ]]; then
    return 0
  fi
  
  # Use Python to parse and display badges with descriptions and status
  python3 2>/dev/null <<PYTHON_SCRIPT
import json
import sys
import os

try:
    gamification_file = "$gamification_file"
    if not os.path.exists(gamification_file):
        sys.exit(0)
    
    with open(gamification_file, "r") as f:
        data = json.load(f)
    
    badges = data.get("badges", {})
    badges_lost = data.get("badges_lost", [])
    stats = data.get("stats", {})
    streaks = data.get("streaks", {})
    
    # Build current stats for maintenance checking (match badge definition format)
    current_stats = {
        "daily_logging_streak": streaks.get("daily_logging", 0),
        "task_streak": streaks.get("task_completion", 0),  # Note: badge defs use "task_streak"
        "exercise_streak": streaks.get("exercise", 0),
        "review_streak": streaks.get("review", 0),
        "tasks_completed": stats.get("tasks_completed", 0),
        "habits_completed": stats.get("habits_completed", 0),
        "projects_completed": stats.get("projects_completed", 0),
        "exercise_sessions": stats.get("exercise_sessions", 0),
        "reviews_completed": stats.get("reviews_completed", 0),
        "wizard_uses": stats.get("wizard_uses", 0),
    }
    
    # Helper function to check maintenance requirements (matches gtd-gamify logic)
    def check_maintenance_requirement(maint_req, current_stats):
        if not maint_req or not isinstance(maint_req, dict) or len(maint_req) == 0:
            return True, 100  # No requirement means always maintained
        
        # Check all requirements in the dict (typically just one)
        for key, required_value in maint_req.items():
            current_value = current_stats.get(key, 0)
            
            if required_value <= 0:
                continue  # Skip invalid requirements
            
            # For streaks and counts, check if current meets required
            if current_value < required_value:
                progress = (current_value / required_value * 100) if required_value > 0 else 100
                return False, progress
        
        # All requirements met
        return True, 100
    
    earned_badges = []
    at_risk_badges = []
    lost_badges_list = []
    
    # Process earned badges
    for badge_id, badge_info in badges.items():
        if isinstance(badge_info, dict):
            is_earned = badge_info.get("earned", False)
            is_lost = badge_id in badges_lost
            
            if is_lost:
                # Collect lost badges
                name = badge_info.get("name", badge_id)
                desc = badge_info.get("description", "No description")
                lost_badges_list.append((name, desc))
            elif is_earned:
                # Check earned badges for maintenance status
                name = badge_info.get("name", badge_id)
                desc = badge_info.get("description", "No description")
                maint_req = badge_info.get("maintenance_requirement", {})
                
                maint_met, progress = check_maintenance_requirement(maint_req, current_stats)
                
                if maint_met:
                    earned_badges.append((name, desc))
                else:
                    # Badge is at risk - maintenance requirement not met
                    at_risk_badges.append((name, desc, progress))
    
    # Display section if there are any badges to show
    if earned_badges or at_risk_badges or lost_badges_list:
        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎖️  Your Badges")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
        
        # Show summary warning if there are at-risk or lost badges
        if at_risk_badges or lost_badges_list:
            warning_count = len(at_risk_badges) + len(lost_badges_list)
            if at_risk_badges and lost_badges_list:
                print(f"  ⚠️  WARNING: You have {len(at_risk_badges)} badge(s) at risk and {len(lost_badges_list)} badge(s) lost!")
            elif at_risk_badges:
                print(f"  ⚠️  WARNING: You have {len(at_risk_badges)} badge(s) at risk!")
            elif lost_badges_list:
                print(f"  ⚠️  WARNING: You have {len(lost_badges_list)} badge(s) lost!")
            print("")
        
        # Show earned badges (maintained)
        if earned_badges:
            for name, desc in earned_badges:
                print(f"  🎖️  {name}")
                print(f"     {desc}")
                print("")
        
        # Show at-risk badges with warning
        if at_risk_badges:
            print("  ⚠️  BADGES AT RISK (Need action to maintain!)")
            print("  " + "-" * 64)
            print("")
            for name, desc, progress in at_risk_badges:
                progress_int = int(progress)
                print(f"  ⚠️  {name}")
                print(f"     {desc}")
                print(f"     Maintenance Progress: {progress_int}% - Take action soon!")
                print("")
        
        # Show lost badges with warning
        if lost_badges_list:
            print("  ❌ LOST BADGES (Build streak to regain!)")
            print("  " + "-" * 64)
            print("")
            for name, desc in lost_badges_list:
                print(f"  ❌ {name}")
                print(f"     {desc}")
                print("")
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("")
except Exception:
    pass
PYTHON_SCRIPT
}

# ============================================================================
# External Services Wizards
# ============================================================================

# Launch database infrastructure wizard
external_database_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🗄️  Database Infrastructure Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  echo "What would you like to do?"
  echo ""
  echo "  1) 🗄️  External Database Services (Kubernetes deployment)"
  echo "  2) 🔍 Vector Database Management (pgvector, embeddings)"
  echo "  3) 🔌 Verify NodePort Services"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read db_choice
  
  case "$db_choice" in
    1)
      local db_wizard_dir="$HOME/code/external_services/database"
      
      if [[ ! -d "$db_wizard_dir" ]]; then
        gtd_feedback error "Database wizard directory not found: $db_wizard_dir"
        echo ""
        echo "Press Enter to return to main menu..."
        read
        return 1
      fi
      
      echo "Entering Database Infrastructure Wizard..."
      echo "  (You can exit this wizard to return to the GTD wizard)"
      echo ""
      gtd_quick_pause
      
      # Change to the database wizard directory and run make wizard
      # This will run in a subshell, so when it exits, we return here
      (
        cd "$db_wizard_dir" || exit 1
        if [[ -f "Makefile" ]]; then
          make wizard
        else
          gtd_feedback error "Makefile not found in $db_wizard_dir"
          gtd_quick_pause
        fi
      )
      
      # When the external wizard exits, we return to the main wizard
      echo ""
      echo "Returning to GTD Wizard..."
      gtd_quick_pause
      ;;
    2)
      # Call vector database wizard from tools
      if type vector_database_wizard &>/dev/null 2>&1; then
        vector_database_wizard
      else
        # Source the tools file if not already loaded
        GTD_WIZARD_TOOLS="$HOME/code/dotfiles/bin/gtd-wizard-tools.sh"
        if [[ ! -f "$GTD_WIZARD_TOOLS" ]]; then
          GTD_WIZARD_TOOLS="$HOME/code/personal/dotfiles/bin/gtd-wizard-tools.sh"
        fi
        if [[ -f "$GTD_WIZARD_TOOLS" ]]; then
          source "$GTD_WIZARD_TOOLS" 2>/dev/null
          vector_database_wizard
        else
          gtd_feedback error "Vector database wizard not available"
          echo ""
          gtd_quick_pause
        fi
      fi
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔌 Verify NodePort Services${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      cd "$HOME/code/dotfiles" && make verify-nodeport
      echo ""
      gtd_quick_pause
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      echo ""
      gtd_quick_pause
      ;;
  esac
}

# Launch RabbitMQ management wizard
external_rabbitmq_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🐰 RabbitMQ Management Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local rabbitmq_wizard_dir="$HOME/code/external_services/rabbitmq"
  
  if [[ ! -d "$rabbitmq_wizard_dir" ]]; then
    gtd_feedback error "RabbitMQ wizard directory not found: $rabbitmq_wizard_dir"
    echo ""
    echo "Press Enter to return to main menu..."
    read
    return 1
  fi
  
  echo "Entering RabbitMQ Management Wizard..."
  echo "  (You can exit this wizard to return to the GTD wizard)"
  echo ""
  gtd_quick_pause
  
  # Change to the RabbitMQ wizard directory and run make wizard
  # This will run in a subshell, so when it exits, we return here
  (
    cd "$rabbitmq_wizard_dir" || exit 1
    if [[ -f "Makefile" ]]; then
      make wizard
    else
      gtd_feedback error "Makefile not found in $rabbitmq_wizard_dir"
      gtd_quick_pause
    fi
  )
  
  # When the external wizard exits, we return to the main wizard
  echo ""
  echo "Returning to GTD Wizard..."
  gtd_quick_pause
}

# Launch Ollama Controller configuration wizard
external_ollama_controller_wizard() {
  clear
  echo ""
  echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}${CYAN}🤖 Ollama Controller Management Wizard${NC}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
  
  local ollama_wizard_dir="$HOME/code/external_services/ollama_controller"
  
  # Check if external wizard exists (similar to RabbitMQ pattern)
  if [[ -d "$ollama_wizard_dir" ]] && [[ -f "$ollama_wizard_dir/Makefile" ]]; then
    # Check if Makefile has a 'wizard' target
    if grep -q "^wizard:" "$ollama_wizard_dir/Makefile" 2>/dev/null || grep -q "^wizard:" "$ollama_wizard_dir/Makefile" 2>/dev/null; then
      echo "Entering Ollama Controller Management Wizard..."
      echo "  (You can exit this wizard to return to the GTD wizard)"
      echo ""
      gtd_quick_pause
      
      # Change to the Ollama Controller wizard directory and run make wizard
      # This will run in a subshell, so when it exits, we return here
      (
        cd "$ollama_wizard_dir" || exit 1
        if [[ -f "Makefile" ]]; then
          make wizard
        else
          gtd_feedback error "Makefile not found in $ollama_wizard_dir"
          gtd_quick_pause
        fi
      )
      
      # When the external wizard exits, we return to the main wizard
      echo ""
      echo "Returning to GTD Wizard..."
      gtd_quick_pause
      return 0
    fi
  fi
  
  # Fallback to inline wizard if external wizard not available
  echo "This wizard will help you configure Ollama Controller to use Kubernetes NodePort."
  echo ""
  
  # Check if Ollama Controller is deployed
  local controller_deployed=false
  if kubectl get deployment ollama-controller-api -n ollama-controller &>/dev/null 2>&1; then
    local replicas=$(kubectl get deployment ollama-controller-api -n ollama-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    local desired=$(kubectl get deployment ollama-controller-api -n ollama-controller -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
    if [[ "$replicas" -gt 0 ]] && [[ "$replicas" == "$desired" ]]; then
      controller_deployed=true
    fi
  fi
  
  # Check if endpoint is responding
  local endpoint_working=false
  if curl -s --max-time 3 "http://127.0.0.1:31080/v1/models" >/dev/null 2>&1; then
    endpoint_working=true
  fi
  
  echo "What would you like to do?"
  echo ""
  if [[ "$controller_deployed" == "true" ]] && [[ "$endpoint_working" == "true" ]]; then
    echo -e "  ${GREEN}✅ Ollama Controller is deployed and responding${NC}"
    echo ""
  elif [[ "$controller_deployed" == "true" ]]; then
    echo -e "  ${YELLOW}⚠️  Ollama Controller is deployed but endpoint not responding${NC}"
    echo ""
  else
    echo -e "  ${RED}❌ Ollama Controller is not deployed${NC}"
    echo ""
  fi
  
  echo "  1) 🚀 Deploy/Enable Ollama Controller"
  echo "  2) 🔧 Configure Ollama Kubernetes Connection"
  echo "  3) 📋 Show Connection Information"
  echo "  4) 🔌 Verify NodePort Service"
  echo "  5) 🧪 Test Ollama Connection"
  echo "  6) 📊 Check Queue Status (by request ID)"
  echo ""
  echo -e "${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read ollama_choice
  
  case "$ollama_choice" in
    1)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🚀 Deploy/Enable Ollama Controller${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      local ollama_dir="$HOME/code/external_services/ollama_controller"
      if [[ ! -d "$ollama_dir" ]]; then
        echo -e "${RED}❌ Ollama Controller repository not found${NC}"
        echo ""
        echo "Expected location: $ollama_dir"
        echo ""
        echo "To download the repository:"
        echo "  mkdir -p ~/code/external_services"
        echo "  cd ~/code/external_services"
        echo "  git clone git@github.com:the-great-abby/llm_proxy.git ollama_controller"
        echo ""
        gtd_enter_to_continue
        return 1
      fi
      
      cd "$ollama_dir" || return 1
      
      # Check if already deployed
      if kubectl get deployment ollama-controller-api -n ollama-controller &>/dev/null 2>&1; then
        local replicas=$(kubectl get deployment ollama-controller-api -n ollama-controller -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        local desired=$(kubectl get deployment ollama-controller-api -n ollama-controller -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")
        
        if [[ "$replicas" -gt 0 ]] && [[ "$replicas" == "$desired" ]]; then
          echo -e "${GREEN}✅ Ollama Controller is already deployed and running${NC}"
          echo ""
          echo "Replicas: $replicas/$desired"
          echo ""
          echo "Would you like to:"
          echo "  1) Redeploy (rebuild and restart)"
          echo "  2) Just restart the API"
          echo "  3) Check status only"
          echo ""
          echo -n "Choose (1-3): "
          read redeploy_choice
          
          case "$redeploy_choice" in
            1)
              echo ""
              echo "Redeploying Ollama Controller..."
              if make k8s-deploy 2>&1; then
                echo ""
                echo -e "${GREEN}✓ Redeployment initiated${NC}"
                echo ""
                echo "Waiting for deployment to be ready..."
                if kubectl wait --for=condition=ready pod -l app=ollama-controller-api -n ollama-controller --timeout=120s 2>/dev/null; then
                  echo -e "${GREEN}✓ Ollama Controller is ready!${NC}"
                else
                  echo -e "${YELLOW}⚠️  Still starting up...${NC}"
                fi
              else
                echo -e "${RED}❌ Redeployment failed${NC}"
              fi
              ;;
            2)
              echo ""
              echo "Restarting API deployment..."
              kubectl rollout restart deployment ollama-controller-api -n ollama-controller
              echo "Waiting for restart..."
              kubectl rollout status deployment ollama-controller-api -n ollama-controller --timeout=120s 2>/dev/null || true
              echo -e "${GREEN}✓ Restart complete${NC}"
              ;;
            3)
              echo ""
              echo "Current status:"
              kubectl get pods -n ollama-controller -l app=ollama-controller-api
              ;;
          esac
        else
          echo -e "${YELLOW}⚠️  Ollama Controller is deployed but not fully ready${NC}"
          echo "Replicas: $replicas/$desired"
          echo ""
          echo "Would you like to redeploy? (y/N): "
          read confirm
          if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            echo ""
            echo "Redeploying..."
            make k8s-deploy 2>&1
          fi
        fi
      else
        echo "Ollama Controller is not deployed."
        echo ""
        echo "This will:"
        echo "  • Build Docker images"
        echo "  • Deploy to Kubernetes"
        echo "  • Configure NodePort service (port 31080)"
        echo ""
        echo -n "Deploy now? (y/N): "
        read confirm
        
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
          echo ""
          echo "Deploying Ollama Controller..."
          if make k8s-deploy 2>&1; then
            echo ""
            echo -e "${GREEN}✓ Deployment initiated${NC}"
            echo ""
            echo "Waiting for Ollama Controller to be ready (this may take 30-60 seconds)..."
            if kubectl wait --for=condition=ready pod -l app=ollama-controller-api -n ollama-controller --timeout=120s 2>/dev/null; then
              echo -e "${GREEN}✓ Ollama Controller is ready!${NC}"
              echo ""
              echo "Connection information:"
              make connection-info 2>/dev/null || echo "  Run 'make connection-info' for details"
            else
              echo -e "${YELLOW}⚠️  Ollama Controller is still starting up${NC}"
              echo "You can check status with: kubectl get pods -n ollama-controller"
            fi
          else
            echo -e "${RED}❌ Deployment failed${NC}"
            echo "You can try manually: cd ~/code/external_services/ollama_controller && make k8s-deploy"
          fi
        fi
      fi
      
      echo ""
      # Test endpoint
      echo "Testing endpoint..."
      sleep 2
      if curl -s --max-time 5 "http://127.0.0.1:31080/v1/models" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Endpoint is responding!${NC}"
      else
        echo -e "${YELLOW}⚠️  Endpoint not responding yet (may need a moment)${NC}"
        echo "Test manually: curl http://127.0.0.1:31080/v1/models"
      fi
      
      gtd_enter_to_continue
      ;;
    2)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔧 Configure Ollama Kubernetes Connection${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      if [[ -f "$HOME/code/dotfiles/bin/configure-ollama-kubernetes" ]]; then
        "$HOME/code/dotfiles/bin/configure-ollama-kubernetes"
      elif [[ -f "$HOME/code/personal/dotfiles/bin/configure-ollama-kubernetes" ]]; then
        "$HOME/code/personal/dotfiles/bin/configure-ollama-kubernetes"
      else
        gtd_feedback error "configure-ollama-kubernetes script not found"
        echo "Please ensure the script exists in your dotfiles bin directory."
      fi
      
      gtd_enter_to_continue
      ;;
    3)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📋 Ollama Connection Information${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      local ollama_dir="$HOME/code/external_services/ollama_controller"
      if [[ ! -d "$ollama_dir" ]]; then
        ollama_dir="$HOME/code/ollama_controller"
      fi
      
      if [[ -d "$ollama_dir" ]] && [[ -f "$ollama_dir/Makefile" ]]; then
        cd "$ollama_dir" || return 1
        make connection-info
      else
        echo "Ollama controller directory not found."
        echo "Expected: ~/code/external_services/ollama_controller"
        echo ""
        echo "Connection information:"
        echo "  NodePort: 31134"
        echo "  URL: http://<NODE_IP>:31134/v1/chat/completions"
        echo ""
        echo "To get the correct Node IP, run: make verify-nodeport"
      fi
      
      gtd_enter_to_continue
      ;;
    4)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🔌 Verify Ollama NodePort Service${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      cd "$HOME/code/dotfiles" && make verify-nodeport 2>/dev/null || {
        echo "Running verify-nodeport..."
        if [[ -f "$HOME/code/dotfiles/bin/verify-nodeport" ]]; then
          "$HOME/code/dotfiles/bin/verify-nodeport"
        else
          echo "verify-nodeport script not found"
        fi
      }
      
      gtd_enter_to_continue
      ;;
    5)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}🧪 Test Ollama Connection${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      
      # Detect node IP
      NODE_IP="192.168.64.2"
      if command -v minikube &>/dev/null && minikube status &>/dev/null 2>&1; then
        NODE_IP=$(minikube ip 2>/dev/null || echo "192.168.64.2")
      elif kubectl get nodes &>/dev/null 2>&1; then
        DETECTED_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
        if [[ "$DETECTED_IP" == "127.0.0.1" ]] || [[ "$DETECTED_IP" == *"192.168"* ]]; then
          NODE_IP="127.0.0.1"
        elif [[ -n "$DETECTED_IP" ]]; then
          NODE_IP="$DETECTED_IP"
        fi
      fi
      
      # Check if using Controller API (port 31080) or direct Ollama (port 31134)
      OLLAMA_URL="${OLLAMA_URL:-http://localhost:11434/v1/chat/completions}"
      if [[ "$OLLAMA_URL" == *":31080"* ]]; then
        TEST_PORT="31080"
        TEST_SERVICE="Ollama Controller API"
      else
        TEST_PORT="31134"
        TEST_SERVICE="Ollama"
      fi
      
      echo "Testing $TEST_SERVICE at: http://$NODE_IP:$TEST_PORT"
      echo ""
      
      # Test models endpoint
      if curl -s --max-time 5 "http://$NODE_IP:$TEST_PORT/v1/models" >/dev/null 2>&1; then
        echo "✅ $TEST_SERVICE API is responding"
        echo ""
        echo "Available models:"
        curl -s --max-time 5 "http://$NODE_IP:$TEST_PORT/v1/models" | python3 -c "import sys, json; data=json.load(sys.stdin); models=[m.get('id', 'unknown') for m in data.get('data', [])]; print('\n'.join(['  - ' + m for m in models[:5]]))" 2>/dev/null || echo "  (Could not parse models list)"
        if [[ "$TEST_PORT" == "31080" ]]; then
          echo ""
          echo "Note: Using Ollama Controller (provides throttling, queuing, monitoring)"
        fi
      else
        echo "❌ $TEST_SERVICE API is not responding"
        echo ""
        echo "Possible issues:"
        if [[ "$TEST_PORT" == "31080" ]]; then
          echo "  - Controller API NodePort service not configured"
          echo "  - Controller API service not running"
          echo "  - Controller may need to be redeployed"
        else
          echo "  - NodePort service not configured"
          echo "  - Ollama service not running"
        fi
        echo "  - Network connectivity issue"
        echo ""
        echo "Run 'make verify-nodeport' to check NodePort configuration"
      fi
      
      gtd_enter_to_continue
      ;;
    6)
      clear
      echo ""
      echo -e "${BOLD}${CYAN}📊 Check Request Status${NC}"
      echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
      echo ""
      echo "Check the status of an advice request or Ollama Controller request."
      echo ""
      echo "You can check by:"
      echo "  • Advice request ID (e.g., advice_20260102_184640_12189)"
      echo "  • Ollama Controller request ID (e.g., 51257cb6-70d7-48d0-ace4-dc09484efceb)"
      echo ""
      echo "Enter the request ID to check:"
      echo -n "Request ID: "
      read request_id
      
      if [[ -z "$request_id" ]]; then
        echo -e "${YELLOW}⚠️  No request ID provided${NC}"
        echo ""
        gtd_quick_pause
      else
        echo ""
        echo "Checking request status..."
        echo ""
        
        # Check if request status tool exists (preferred - shows comprehensive status)
        REQUEST_STATUS_TOOL="$HOME/code/dotfiles/bin/gtd-request-status"
        if [[ ! -f "$REQUEST_STATUS_TOOL" ]]; then
          REQUEST_STATUS_TOOL="$HOME/code/personal/dotfiles/bin/gtd-request-status"
        fi
        
        if [[ -f "$REQUEST_STATUS_TOOL" ]] && [[ -x "$REQUEST_STATUS_TOOL" ]]; then
          "$REQUEST_STATUS_TOOL" "$request_id"
        else
          # Fallback: use queue status tool or Python directly
          QUEUE_STATUS_TOOL="$HOME/code/dotfiles/bin/gtd-queue-status"
          if [[ ! -f "$QUEUE_STATUS_TOOL" ]]; then
            QUEUE_STATUS_TOOL="$HOME/code/personal/dotfiles/bin/gtd-queue-status"
          fi
          
          if [[ -f "$QUEUE_STATUS_TOOL" ]] && [[ -x "$QUEUE_STATUS_TOOL" ]]; then
            "$QUEUE_STATUS_TOOL" "$request_id"
          else
            # Final fallback: use Python directly
            python3 <<PYTHON_EOF
import sys
import os
from pathlib import Path

# Add functions directory to path
functions_dir = Path.home() / "code" / "dotfiles" / "zsh" / "functions"
if not functions_dir.exists():
    functions_dir = Path.home() / "code" / "personal" / "dotfiles" / "zsh" / "functions"

if functions_dir.exists():
    sys.path.insert(0, str(functions_dir))

try:
    from gtd_ai_helpers import get_queue_status, is_ollama_controller_url
    
    # Get Ollama URL from environment or config
    ollama_url = os.getenv("OLLAMA_URL", "http://127.0.0.1:31080/v1/chat/completions")
    
    # Check if using Ollama Controller
    if not is_ollama_controller_url(ollama_url):
        print("❌ Not using Ollama Controller")
        print(f"   URL: {ollama_url}")
        print("   Queue status is only available for Ollama Controller requests")
        sys.exit(1)
    
    # Extract base URL
    base_url = ollama_url.rsplit('/v1', 1)[0]
    
    # Get queue status
    request_id = "$request_id"
    status = get_queue_status(request_id, base_url)
    
    # Display status
    print(f"📊 Queue Status for Request: {request_id}")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print(f"Status: {status['status']}")
    print(f"Message: {status['message']}")
    
    if status.get('queue_position') is not None:
        print(f"Queue Position: {status['queue_position']}")
    
    if status.get('elapsed_time') is not None:
        elapsed_min = int(status['elapsed_time'] // 60)
        elapsed_sec = int(status['elapsed_time'] % 60)
        print(f"Elapsed Time: {elapsed_min}m {elapsed_sec}s")
    
    if status.get('error'):
        print(f"Error: {status['error']}")
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
except Exception as e:
    print(f"❌ Error checking queue status: {e}")
    import traceback
    traceback.print_exc()
PYTHON_EOF
          fi
        fi
        
        echo ""
        gtd_enter_to_continue
      fi
      ;;
    0|"")
      return 0
      ;;
    *)
      echo "Invalid choice"
      gtd_quick_pause
      ;;
  esac
}

# Get favorited tasks (returns array of task files)
# Optimized to prevent hanging on systems with many files
get_favorited_tasks() {
  local favorited_tasks=()
  local file_count=0
  local max_files=100  # Limit to prevent hanging
  
  # Check tasks directory
  if [[ -d "${TASKS_PATH:-}" ]]; then
    while IFS= read -r task_file && [[ $file_count -lt $max_files ]]; do
      [[ ! -f "$task_file" ]] && continue
      ((file_count++))
      # Use head to limit file reading (frontmatter is at top)
      local frontmatter=$(head -30 "$task_file" 2>/dev/null || echo "")
      if [[ -z "$frontmatter" ]]; then
        continue
      fi
      # Extract values from frontmatter directly (faster than calling function twice)
      local favorite=$(echo "$frontmatter" | grep "^favorite:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      local status=$(echo "$frontmatter" | grep "^status:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      if [[ "$favorite" == "true" ]] && [[ "$status" == "active" ]]; then
        favorited_tasks+=("$task_file")
      fi
    done < <(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | head -$max_files)
  fi
  
  # Check project directories (limit to prevent hanging)
  if [[ -d "${PROJECTS_PATH:-}" ]]; then
    file_count=0
    while IFS= read -r task_file && [[ $file_count -lt $max_files ]]; do
      [[ ! -f "$task_file" || "$task_file" == */README.md ]] && continue
      ((file_count++))
      # Use head to limit file reading (frontmatter is at top)
      local frontmatter=$(head -30 "$task_file" 2>/dev/null || echo "")
      if [[ -z "$frontmatter" ]]; then
        continue
      fi
      # Extract values from frontmatter directly (faster than calling function twice)
      local favorite=$(echo "$frontmatter" | grep "^favorite:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      local status=$(echo "$frontmatter" | grep "^status:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
      if [[ "$favorite" == "true" ]] && [[ "$status" == "active" ]]; then
        favorited_tasks+=("$task_file")
      fi
    done < <(find "${PROJECTS_PATH}" -name "*.md" -type f 2>/dev/null | head -$max_files)
  fi
  
  # Output task files (one per line)
  for task_file in "${favorited_tasks[@]}"; do
    echo "$task_file"
  done
}

# Get favorited projects (returns array of project directories)
# Optimized to prevent hanging on systems with many projects
get_favorited_projects() {
  local favorited_projects=()
  local max_projects=50  # Limit to prevent hanging
  
  if [[ -d "${PROJECTS_PATH:-}" ]]; then
    # Use sorted order to match cache worker behavior
    while IFS= read -r project_dir; do
      [[ ! -d "$project_dir" ]] && continue
      local readme="${project_dir}/README.md"
      if [[ -f "$readme" ]]; then
        # Use head to limit file reading (frontmatter is at top)
        local frontmatter=$(head -30 "$readme" 2>/dev/null || echo "")
        if [[ -z "$frontmatter" ]]; then
          continue
        fi
        # Extract values from frontmatter directly (faster than calling function twice)
        local favorite=$(echo "$frontmatter" | grep "^favorite:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        local project_status=$(echo "$frontmatter" | grep "^status:" | head -1 | cut -d':' -f2- | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        # If no status field, assume active (default for projects)
        [[ -z "$project_status" ]] && project_status="active"
        if [[ "$favorite" == "true" ]] && [[ "$project_status" == "active" ]]; then
          favorited_projects+=("$project_dir")
          # Limit results to prevent hanging
          if [[ ${#favorited_projects[@]} -ge $max_projects ]]; then
            break
          fi
        fi
      fi
    done < <(find "${PROJECTS_PATH}" -type d -mindepth 1 -maxdepth 1 2>/dev/null | sort)
  fi
  
  # Output project directories (one per line)
  for project_dir in "${favorited_projects[@]}"; do
    echo "$project_dir"
  done
}

# Main menu display
show_main_menu() {
  # Show organization techniques guide (helper text at top)
  show_organization_guide
  
  # Show process reminders (helper text at top)
  show_process_reminders
  
  # Show earned badges
  show_earned_badges
  
  echo -e "${BOLD}What would you like to do?${NC}"
  echo ""
  
  # Get column setting (default to 1 if not set)
  local columns="${GTD_WIZARD_COLUMNS:-1}"
  
  # Helper function to print menu section
  print_menu_section() {
    local section_title="$1"
    shift
    local menu_items=("$@")
    
    echo -e "$section_title"
    if [[ "$columns" == "2" ]]; then
      gtd_print_menu_items_two_columns "${menu_items[@]}"
    else
      for item in "${menu_items[@]}"; do
        echo -e "  $item"
      done
    fi
    echo ""
  }
  
  # FOCUS section - favorited tasks and projects (only show if there are any)
  # Try to use cache first for faster loading
  local favorited_tasks=()
  local favorited_projects=()
  local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
  local cache_used=false
  
  # Try to read from cache (if fresh, less than 30 seconds old)
  if [[ -f "$cache_file" ]]; then
    local cache_age=0
    if command -v stat &>/dev/null; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
      else
        cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
      fi
    fi
    
    # Cache is valid if less than 30 seconds old
    if [[ $cache_age -lt 30 ]]; then
      local cache_data=""
      cache_data=$(python3 <<PYTHON_EOF 2>/dev/null
import json
import sys
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    # Output favorited items (cache stores them as lists of path strings)
    favorited_tasks = cache.get('favorited_tasks', [])
    for task_path in favorited_tasks[:3]:  # Limit to 3 for menu
        if task_path and isinstance(task_path, str):
            print(f"FAVORITED_TASK={task_path}")
    favorited_projects = cache.get('favorited_projects', [])
    for project_path in favorited_projects[:2]:  # Limit to 2 for menu
        if project_path and isinstance(project_path, str):
            print(f"FAVORITED_PROJECT={project_path}")
except Exception:
    pass
PYTHON_EOF
)
      if [[ -n "$cache_data" ]]; then
        cache_used=true
        while IFS='=' read -r key value; do
          case "$key" in
            FAVORITED_TASK) [[ -n "$value" ]] && favorited_tasks+=("$value") ;;
            FAVORITED_PROJECT) [[ -n "$value" ]] && favorited_projects+=("$value") ;;
          esac
        done <<< "$cache_data"
      fi
    fi
  fi
  
  # Fallback to live calculation if cache not available or stale
  # Use timeout to prevent blocking if these operations are slow
  if [[ "$cache_used" != "true" ]]; then
    # Check if function exists before calling
    if declare -f get_favorited_tasks &>/dev/null; then
      if command -v timeout &>/dev/null; then
        while IFS= read -r task_file; do
          [[ -n "$task_file" ]] && favorited_tasks+=("$task_file")
        done < <(timeout 2 get_favorited_tasks 2>/dev/null || true)
      else
        while IFS= read -r task_file; do
          [[ -n "$task_file" ]] && favorited_tasks+=("$task_file")
        done < <(get_favorited_tasks 2>/dev/null || true)
      fi
    fi
    
    # Check if function exists before calling
    if declare -f get_favorited_projects &>/dev/null; then
      if command -v timeout &>/dev/null; then
        while IFS= read -r project_dir; do
          [[ -n "$project_dir" ]] && favorited_projects+=("$project_dir")
        done < <(timeout 2 get_favorited_projects 2>/dev/null || true)
      else
        while IFS= read -r project_dir; do
          [[ -n "$project_dir" ]] && favorited_projects+=("$project_dir")
        done < <(get_favorited_projects 2>/dev/null || true)
      fi
    fi
  fi
  
  # Always show FOCUS section if there are favorited items, or show helpful message
  if [[ ${#favorited_tasks[@]} -gt 0 ]] || [[ ${#favorited_projects[@]} -gt 0 ]]; then
    local focus_items=()
    
    # Add favorited tasks with quick edit/complete
    local task_index=0
    for task_file in "${favorited_tasks[@]}"; do
      [[ ! -f "$task_file" ]] && continue
      local task_id=$(basename "$task_file" .md)
      local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$task_file" .md)
      # Truncate long task names
      if [[ ${#task_name} -gt 40 ]]; then
        task_name="${task_name:0:37}..."
      fi
      local menu_num=$((900 + task_index))  # Start at 900 to avoid conflicts and allow growth
      focus_items+=("${GREEN}${menu_num})${NC} ⭐ ${task_name} (Quick Edit/Complete)")
      ((task_index++))
      if [[ $task_index -ge 3 ]]; then  # Limit to 3 tasks
        break
      fi
    done
    
    # Add favorited projects with quick edit
    local project_index=0
    for project_dir in "${favorited_projects[@]}"; do
      [[ ! -d "$project_dir" ]] && continue
      local project_slug=$(basename "$project_dir")
      local project_readme="${project_dir}/README.md"
      local project_name=""
      
      if [[ -f "$project_readme" ]]; then
        # Try to get name from frontmatter first
        project_name=$(gtd_get_frontmatter_value "$project_readme" "name" 2>/dev/null || echo "")
        [[ -z "$project_name" ]] && project_name=$(gtd_get_frontmatter_value "$project_readme" "project" 2>/dev/null || echo "")
        
        # If still no name, try to get from H1 heading
        if [[ -z "$project_name" ]]; then
          project_name=$(head -20 "$project_readme" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' || echo "")
        fi
      fi
      
      # Final fallback: format the slug nicely
      if [[ -z "$project_name" ]]; then
        project_name=$(echo "$project_slug" | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
      fi
      
      # Truncate long project names
      if [[ ${#project_name} -gt 40 ]]; then
        project_name="${project_name:0:37}..."
      fi
      
      local menu_num=$((903 + project_index))  # Start at 903 to avoid conflicts and allow growth
      focus_items+=("${GREEN}${menu_num})${NC} ⭐ ${project_name} (Quick Edit)")
      ((project_index++))
      if [[ $project_index -ge 2 ]]; then  # Limit to 2 projects
        break
      fi
    done
    
    if [[ ${#focus_items[@]} -gt 0 ]]; then
      print_menu_section "${BOLD}${YELLOW}⭐ FOCUS - Favorited Items:${NC}" "${focus_items[@]}"
    fi
  fi
  
  # INPUTS section
  print_menu_section "${BOLD}${CYAN}📥 INPUTS - Capture & Process:${NC}" \
    "${GREEN}1)${NC} 📥 Capture something to inbox" \
    "${GREEN}2)${NC} 📋 Process inbox items" \
    "${GREEN}15)${NC} 📝 Log to daily log" \
    "${GREEN}31)${NC} 👁️  View daily log" \
    "${GREEN}19)${NC} 🌅 Morning/Evening Check-In"
  
  # ORGANIZATION section
  print_menu_section "${BOLD}${CYAN}🗂️  ORGANIZATION - Manage Your System:${NC}" \
    "${GREEN}3)${NC} ✅ Manage tasks" \
    "${GREEN}4)${NC} 📁 Manage projects" \
    "${GREEN}5)${NC} 🎯 Manage areas of responsibility" \
    "${GREEN}8)${NC} 🗺️  Manage MOCs (Maps of Content)" \
    "${GREEN}23)${NC} 🔗 Zettelkasten (atomic notes)" \
    "${GREEN}55)${NC} 🎯 Prioritization Review"
  
  # SECOND BRAIN section
  print_menu_section "${BOLD}${CYAN}🧠 SECOND BRAIN - Advanced Operations:${NC}" \
    "${GREEN}48)${NC} 🔗 Connect notes" \
    "${GREEN}49)${NC} 📊 Converge/consolidate notes" \
    "${GREEN}50)${NC} 🔍 Discover connections" \
    "${GREEN}51)${NC} 📝 Distill (progressive summarization)" \
    "${GREEN}52)${NC} 💡 Diverge (expand ideas)" \
    "${GREEN}53)${NC} 🌲 Evergreen notes" \
    "${GREEN}54)${NC} 📦 Note packets"
  
  # OUTPUTS section
  print_menu_section "${BOLD}${CYAN}📤 OUTPUTS - Reviews & Creation:${NC}" \
    "${GREEN}6)${NC} 📊 Review (daily/weekly/monthly)" \
    "${GREEN}7)${NC} 🧠 Sync with Second Brain" \
    "${GREEN}57)${NC} 🔄 Bidirectional Obsidian Sync" \
    "${GREEN}59)${NC} 📊 Enhanced Review System" \
    "${GREEN}62)${NC} 📝 Review Draft Notes (evergreen insights)" \
    "${GREEN}66)${NC} 🎯 Agent Skills (workflows & processes)" \
    "${GREEN}9)${NC} ✍️  Express Phase (create content from notes)" \
    "${GREEN}10)${NC} 📋 Use Templates" \
    "${GREEN}22)${NC} 🎨 Create diagrams & mindmaps"
  
  # LEARNING section
  print_menu_section "${BOLD}${CYAN}📚 LEARNING - Guides & Discovery:${NC}" \
    "${GREEN}12)${NC} 📚 Learn Organization System (GTD + Second Brain + Zettelkasten)" \
    "${GREEN}13)${NC} 🧠 Learn Second Brain (where to start)" \
    "${GREEN}14)${NC} 🎯 Discover Life Vision (if you don't have a plan)" \
    "${GREEN}20)${NC} ☸️  Learn Kubernetes/CKA" \
    "${GREEN}21)${NC} 🇬🇷 Learn Greek (Language)"
  
  # ANALYSIS section
  print_menu_section "${BOLD}${CYAN}🔍 ANALYSIS - Insights & Tracking:${NC}" \
    "${GREEN}16)${NC} 🔍 Search GTD system" \
    "${GREEN}17)${NC} 📊 System status" \
    "${GREEN}25)${NC} 🎯 Goal Tracking & Progress" \
    "${GREEN}26)${NC} ⚡ Energy Audit (drains & boosts)" \
    "${GREEN}30)${NC} 💪 HealthKit & Health Data (disabled)" \
    "${GREEN}34)${NC} 📈 Log statistics & streaks" \
    "${GREEN}35)${NC} 🔗 Metric correlations" \
    "${GREEN}36)${NC} 🔍 Pattern recognition" \
    "${GREEN}37)${NC} 📊 Weekly progress report" \
    "${GREEN}38)${NC} 🧠 Second Brain metrics" \
    "${GREEN}56)${NC} 📊 Success metrics (usage & effectiveness)" \
    "${GREEN}58)${NC} 📚 Learning System Preferences"
  
  # TOOLS section
  print_menu_section "${BOLD}${CYAN}🛠️  TOOLS & SUPPORT:${NC}" \
    "${GREEN}11)${NC} 🤖 Get advice from personas" \
    "${GREEN}18)${NC} 🔁 Manage habits & recurring tasks" \
    "${GREEN}24)${NC} 🤖 AI Suggestions & MCP Tools" \
    "${GREEN}29)${NC} 📅 Calendar (view, sync tasks, check conflicts)" \
    "${GREEN}39)${NC} ⚡ Energy-aware scheduling" \
    "${GREEN}40)${NC} 🎯 What should I do now? (context-aware)" \
    "${GREEN}41)${NC} 🔍 Find items (advanced search)" \
    "${GREEN}42)${NC} 🎉 Celebrate milestones"
  
  # SETTINGS section
  print_menu_section "${BOLD}${CYAN}⚙️  SETTINGS:${NC}" \
    "${GREEN}27)${NC} ⚙️  Configuration & Setup" \
    "${GREEN}28)${NC} 🎮 Gamification & Habitica" \
    "${GREEN}60)${NC} 💻 Switch Computer Mode (work/home)" \
    "${GREEN}61)${NC} 🧪 Run Unit Tests"
  
  # INFRASTRUCTURE section
  print_menu_section "${BOLD}${CYAN}🔧 INFRASTRUCTURE - External Services:${NC}" \
    "${GREEN}63)${NC} 🗄️  Database Infrastructure Wizard" \
    "${GREEN}64)${NC} 🐰 RabbitMQ Management Wizard" \
    "${GREEN}65)${NC} 🤖 Ollama Controller Configuration"
  
  # Exit option (always single line)
  echo -e "${YELLOW}0)${NC} Exit"
  echo ""
  
  # Show dashboard (command center) at the bottom
  # Wrap in comprehensive error handling to prevent wizard from crashing
  # Use timeout to prevent blocking if dashboard cache processing is slow
  set +e  # Don't exit on errors
  
  # Run dashboard with timeout using background process (functions can't use timeout command directly)
  local dashboard_output=$(mktemp)
  local dashboard_pid
  (
    show_dashboard 2>/dev/null > "$dashboard_output" 2>&1
  ) &
  dashboard_pid=$!
  
  # Wait up to 3 seconds for dashboard to complete (30 iterations of 0.1s = 3s)
  local waited=0
  while [[ $waited -lt 30 ]] && kill -0 "$dashboard_pid" 2>/dev/null; do
    sleep 0.1
    waited=$((waited + 1))
  done
  
  # If still running, kill it
  if kill -0 "$dashboard_pid" 2>/dev/null; then
    kill "$dashboard_pid" 2>/dev/null || true
    wait "$dashboard_pid" 2>/dev/null || true
    # Show fallback if timed out
    echo ""
    echo "🎯 GTD Command Center"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Status display unavailable (timeout)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  else
    # Dashboard completed - show output
    cat "$dashboard_output" 2>/dev/null || {
      # Fallback if output file doesn't exist or can't be read
      echo ""
      echo "🎯 GTD Command Center"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
      echo "⚠️  Status display unavailable"
      echo ""
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo ""
    }
  fi
  
  # Cleanup
  rm -f "$dashboard_output" 2>/dev/null || true
  set -e  # Re-enable error handling
  
  echo -n "Choose: "
}

# Main function - entry point for the wizard
main() {
  # Check if non-interactive (e.g., running in tests) - exit early
  if ! is_interactive; then
    echo "GTD Wizard requires an interactive terminal. Skipping in non-interactive mode."
    return 0
  fi
  
  # Set up signal handlers to prevent crashes
  trap 'echo ""; echo "Exiting wizard..."; exit 0' INT TERM
  trap 'echo ""; echo "Error in wizard. Exiting..."; exit 1' ERR
  
  # Award XP for opening wizard (first time in this session)
  # Use timeout and error isolation to prevent hanging
  set +e
  if command -v timeout &>/dev/null; then
    timeout 1 bash -c "award_wizard_xp 'wizard_use' 'Opened GTD wizard'" 2>/dev/null || true
  else
    award_wizard_xp "wizard_use" "Opened GTD wizard" 2>/dev/null || true
  fi
  set -e
  
  # Track daily usage with timeout protection
  set +e
  if command -v gtd-success-metrics &>/dev/null; then
    if command -v timeout &>/dev/null; then
      timeout 1 gtd-success-metrics track "gtd-wizard" 2>/dev/null || true
    else
      gtd-success-metrics track "gtd-wizard" 2>/dev/null || true
    fi
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-success-metrics" ]]; then
    if command -v timeout &>/dev/null; then
      timeout 1 "$HOME/code/dotfiles/bin/gtd-success-metrics" track "gtd-wizard" 2>/dev/null || true
    else
      "$HOME/code/dotfiles/bin/gtd-success-metrics" track "gtd-wizard" 2>/dev/null || true
    fi
  fi
  set -e
  
  while true; do
    # Show menu with error handling
    set +e
    show_main_menu 2>&1 | grep -v "bad substitution" || {
      echo ""
      echo "Error displaying menu. Press Enter to continue..."
      read -t 60 choice 2>/dev/null || true
      continue
    }
    set -e
    
    # Read user choice - use simple read without timeout to avoid issues
    # The timeout might be causing problems in some environments
    # Check if still interactive before reading (in case stdin was closed)
    if ! is_interactive; then
      echo ""
      echo "Exiting (non-interactive mode detected)..."
      exit 0
    fi
    
    local choice=""
    set +e  # Don't exit if read fails
    # Flush any pending output before reading
    exec >&2  # Ensure we're writing to stderr for prompts
    read choice 2>/dev/null || {
      # If read fails (e.g., EOF), exit gracefully
      echo ""
      echo "Exiting..."
      exit 0
    }
    set -e  # Re-enable error handling
    
    # Handle empty choice (just Enter)
    if [[ -z "$choice" ]]; then
      # Empty input - show menu again
      continue
    fi
    
    # Track wizard option usage for preferences learning (with timeout)
    if [[ "$choice" =~ ^[0-9]+$ ]]; then
      set +e
      if command -v gtd-preferences-learn &>/dev/null; then
        if command -v timeout &>/dev/null; then
          timeout 1 gtd-preferences-learn track-feature "wizard_option" "$choice" 2>/dev/null || true
        else
          gtd-preferences-learn track-feature "wizard_option" "$choice" 2>/dev/null || true
        fi
      fi
      set -e
    fi
    
    case "$choice" in
      1)
        award_wizard_xp "wizard_productive" "Used wizard: Capture"
        capture_wizard
        ;;
      2)
        award_wizard_xp "wizard_productive" "Used wizard: Process inbox"
        process_wizard
        ;;
      3)
        award_wizard_xp "wizard_productive" "Used wizard: Manage tasks"
        task_wizard
        ;;
      4)
        award_wizard_xp "wizard_productive" "Used wizard: Manage projects"
        project_wizard
        ;;
      5)
        award_wizard_xp "wizard_action" "Used wizard: Manage areas"
        area_wizard
        ;;
      6)
        award_wizard_xp "wizard_productive" "Used wizard: Review"
        review_wizard
        ;;
      7)
        award_wizard_xp "wizard_productive" "Used wizard: Sync Second Brain"
        sync_wizard
        ;;
      57)
        award_wizard_xp "wizard_action" "Used wizard: Bidirectional Obsidian Sync"
        bidirectional_sync_wizard
        ;;
      59)
        award_wizard_xp "wizard_action" "Used wizard: Enhanced Review System"
        enhanced_review_wizard
        ;;
      8)
        award_wizard_xp "wizard_productive" "Used wizard: Manage MOCs"
        moc_wizard
        ;;
      9)
        award_wizard_xp "wizard_productive" "Used wizard: Express Phase"
        express_wizard
        ;;
      10)
        award_wizard_xp "wizard_productive" "Used wizard: Templates"
        template_wizard
        ;;
      11)
        award_wizard_xp "wizard_action" "Used wizard: Get advice"
        advice_wizard
        ;;
      12)
        award_wizard_xp "wizard_action" "Used wizard: Learn Organization System"
        tips_wizard
        ;;
      13)
        award_wizard_xp "wizard_action" "Used wizard: Learn Second Brain"
        learn_second_brain_wizard
        ;;
      14)
        award_wizard_xp "wizard_action" "Used wizard: Life Vision"
        life_vision_wizard
        ;;
      15)
        award_wizard_xp "wizard_productive" "Used wizard: Daily Log"
        log_wizard
        ;;
      16)
        award_wizard_xp "wizard_action" "Used wizard: Search"
        search_wizard
        ;;
      17)
        award_wizard_xp "wizard_action" "Used wizard: System Status"
        status_wizard
        ;;
      18)
        award_wizard_xp "wizard_productive" "Used wizard: Habits"
        habit_wizard
        ;;
      19)
        award_wizard_xp "wizard_productive" "Used wizard: Check-In"
        checkin_wizard
        ;;
      31)
        award_wizard_xp "wizard_productive" "Used wizard: View Daily Log"
        clear
        echo ""
        if command -v gtd-log &>/dev/null; then
          gtd-log today
        elif [[ -f "$HOME/code/dotfiles/bin/gtd-log" ]]; then
          "$HOME/code/dotfiles/bin/gtd-log" today
        elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log" ]]; then
          "$HOME/code/personal/dotfiles/bin/gtd-log" today
        else
          gtd_feedback error "gtd-log command not found. Install it or check your PATH."
          gtd_quick_pause
          continue
        fi
        echo ""
        gtd_quick_pause
        ;;
      20)
        award_wizard_xp "wizard_action" "Used wizard: Learn Kubernetes"
        k8s_wizard
        ;;
      21)
        award_wizard_xp "wizard_action" "Used wizard: Learn Greek"
        greek_wizard
        ;;
      22)
        award_wizard_xp "wizard_productive" "Used wizard: Diagrams"
        diagram_wizard
        ;;
      23)
        award_wizard_xp "wizard_productive" "Used wizard: Zettelkasten"
        zettelkasten_wizard
        ;;
      24)
        award_wizard_xp "wizard_action" "Used wizard: AI Suggestions"
        ai_suggestions_wizard
        ;;
      25)
        award_wizard_xp "wizard_action" "Used wizard: Goal Tracking"
        goal_tracking_wizard
        ;;
      26)
        award_wizard_xp "wizard_action" "Used wizard: Energy Audit"
        energy_audit_wizard
        ;;
      27)
        award_wizard_xp "wizard_action" "Used wizard: Configuration"
        config_wizard
        ;;
      28)
        award_wizard_xp "wizard_action" "Used wizard: Gamification"
        gamification_wizard
        ;;
      29)
        award_wizard_xp "wizard_action" "Used wizard: Calendar"
        calendar_wizard
        ;;
      30)
        award_wizard_xp "wizard_action" "Used wizard: HealthKit"
        healthkit_wizard
        ;;
      31)
        award_wizard_xp "wizard_productive" "Used wizard: Morning Routine"
        morning_routine_wizard
        ;;
      32)
        award_wizard_xp "wizard_productive" "Used wizard: Afternoon Routine"
        afternoon_routine_wizard
        ;;
      33)
        award_wizard_xp "wizard_productive" "Used wizard: Evening Routine"
        evening_routine_wizard
        ;;
      34)
        award_wizard_xp "wizard_action" "Used wizard: Log Stats"
        log_stats_wizard
        ;;
      35)
        award_wizard_xp "wizard_action" "Used wizard: Metric Correlations"
        metric_correlations_wizard
        ;;
      36)
        award_wizard_xp "wizard_action" "Used wizard: Pattern Recognition"
        pattern_recognition_wizard
        ;;
      37)
        award_wizard_xp "wizard_action" "Used wizard: Weekly Progress"
        weekly_progress_wizard
        ;;
      38)
        award_wizard_xp "wizard_action" "Used wizard: Brain Metrics"
        brain_metrics_wizard
        ;;
      39)
        award_wizard_xp "wizard_action" "Used wizard: Energy Schedule"
        energy_schedule_wizard
        ;;
      40)
        award_wizard_xp "wizard_action" "Used wizard: What Should I Do Now"
        now_wizard
        ;;
      41)
        award_wizard_xp "wizard_action" "Used wizard: Find Items"
        find_wizard
        ;;
      42)
        award_wizard_xp "wizard_action" "Used wizard: Milestone Celebration"
        milestone_wizard
        ;;
      43)
        award_wizard_xp "wizard_productive" "Used wizard: Evening Summary"
        evening_summary_wizard
        ;;
      44)
        award_wizard_xp "wizard_action" "Used wizard: Deployment"
        deployment_wizard
        ;;
      45)
        award_wizard_xp "wizard_productive" "Used wizard: Collect All"
        collect_all_wizard
        ;;
      46)
        award_wizard_xp "wizard_productive" "Used wizard: Quick Complete Habits"
        quick_complete_habits
        ;;
      47)
        award_wizard_xp "wizard_productive" "Used wizard: Mood Log"
        mood_log_wizard
        ;;
      48)
        award_wizard_xp "wizard_productive" "Used wizard: Connect Notes"
        brain_connect_wizard
        ;;
      49)
        award_wizard_xp "wizard_productive" "Used wizard: Converge Notes"
        brain_converge_wizard
        ;;
      50)
        award_wizard_xp "wizard_productive" "Used wizard: Discover Notes"
        brain_discover_wizard
        ;;
      51)
        award_wizard_xp "wizard_productive" "Used wizard: Distill Notes"
        brain_distill_wizard
        ;;
      52)
        award_wizard_xp "wizard_productive" "Used wizard: Diverge Notes"
        brain_diverge_wizard
        ;;
      53)
        award_wizard_xp "wizard_productive" "Used wizard: Evergreen Notes"
        brain_evergreen_wizard
        ;;
      54)
        award_wizard_xp "wizard_productive" "Used wizard: Note Packets"
        brain_packet_wizard
        ;;
      55)
        award_wizard_xp "wizard_action" "Used wizard: Prioritization Review"
        prioritization_wizard
        ;;
      56)
        award_wizard_xp "wizard_action" "Used wizard: Success Metrics"
        success_metrics_wizard
        ;;
      58)
        award_wizard_xp "wizard_action" "Used wizard: Learning System Preferences"
        preferences_learning_wizard
        ;;
      60)
        award_wizard_xp "wizard_action" "Used wizard: Switch Computer Mode"
        computer_mode_wizard
        ;;
      61)
        award_wizard_xp "wizard_action" "Used wizard: Run Unit Tests"
        test_execution_wizard
        ;;
      62)
        award_wizard_xp "wizard_productive" "Used wizard: Review Draft Notes"
        review_drafts_wizard
        ;;
      63)
        award_wizard_xp "wizard_action" "Used wizard: Database Infrastructure"
        external_database_wizard
        ;;
      64)
        award_wizard_xp "wizard_action" "Used wizard: RabbitMQ Management"
        external_rabbitmq_wizard
        ;;
      65)
        external_ollama_controller_wizard
        ;;
      66)
        award_wizard_xp "wizard_productive" "Used wizard: Agent Skills"
        skills_wizard
        ;;
      # Handle favorited tasks (900-902) and projects (903-904)
      900|901|902)
        # Get favorited tasks
        local favorited_tasks=()
        while IFS= read -r task_file; do
          [[ -n "$task_file" ]] && favorited_tasks+=("$task_file")
        done < <(get_favorited_tasks)
        
        # Calculate which task was selected (900 = first, 901 = second, 902 = third)
        local task_index=$((choice - 900))
        if [[ $task_index -ge 0 && $task_index -lt ${#favorited_tasks[@]} ]]; then
          local selected_task_file="${favorited_tasks[$task_index]}"
          local task_id=$(basename "$selected_task_file" .md)
          local task_name=$(head -20 "$selected_task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || basename "$selected_task_file" .md)
          
          clear
          echo ""
          echo -e "${BOLD}⭐ Favorited Task: ${task_name}${NC}"
          echo ""
          echo "What would you like to do?"
          echo ""
          echo "  1) Quick Edit"
          echo "  2) Quick Complete"
          echo "  3) View Full Task"
          echo "  4) ⭐ Unfavorite (remove from favorites)"
          echo ""
          echo -e "${YELLOW}0)${NC} Back to Main Menu"
          echo ""
          echo -n "Choose: "
          read action_choice
          
          case "$action_choice" in
            1)
              # Quick edit - use task update wizard
              if command -v gtd-task &>/dev/null; then
                gtd-task update "$task_id"
              else
                gtd_feedback error "gtd-task command not found"
              fi
              gtd_quick_pause
              ;;
            2)
              # Quick complete
              if command -v gtd-task &>/dev/null; then
                gtd-task complete "$task_id"
                gtd_action_success "completed" "favorited task" "$task_name"
              else
                gtd_feedback error "gtd-task command not found"
              fi
              gtd_quick_pause
              ;;
            3)
              # View full task
              if command -v gtd-task &>/dev/null; then
                gtd-task view "$task_id"
                gtd_enter_to_continue
              else
                gtd_feedback error "gtd-task command not found"
                gtd_quick_pause
              fi
              ;;
            4)
              # Unfavorite task
              if [[ -f "$selected_task_file" ]]; then
                if grep -q "^favorite:" "$selected_task_file" 2>/dev/null; then
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/^favorite:.*/favorite: false/" "$selected_task_file"
                  else
                    sed -i "s/^favorite:.*/favorite: false/" "$selected_task_file"
                  fi
                  echo ""
                  echo -e "${GREEN}✓${NC} Task '$task_name' unfavorited"
                  echo "   It will no longer appear in your favorited items list."
                else
                  echo ""
                  echo -e "${YELLOW}⚠️${NC} Task is not currently favorited"
                fi
                echo ""
                gtd_quick_pause
              else
                gtd_feedback error "Task file not found"
                gtd_quick_pause
              fi
              ;;
            0|"")
              # Back - do nothing
              ;;
            *)
              echo "Invalid choice"
              gtd_quick_pause
              ;;
          esac
        else
          gtd_feedback error "Favorited task not found"
          gtd_quick_pause
        fi
        ;;
      903|904)
        # Get favorited projects - use same method as menu (cache first, then function)
        local favorited_projects=()
        local cache_file="${GTD_BASE_DIR:-$HOME/Documents/gtd}/.dashboard_cache.json"
        local cache_used=false
        
        # Try to read from cache first (same as menu does)
        if [[ -f "$cache_file" ]]; then
          local cache_age=0
          if command -v stat &>/dev/null; then
            if [[ "$OSTYPE" == "darwin"* ]]; then
              cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0)))
            else
              cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
            fi
          fi
          
          # Cache is valid if less than 30 seconds old (same as menu)
          if [[ $cache_age -lt 30 ]]; then
            local cache_data=""
            cache_data=$(python3 <<PYTHON_EOF 2>/dev/null
import json
try:
    with open("$cache_file", "r") as f:
        cache = json.load(f)
    favorited_projects = cache.get('favorited_projects', [])
    for project_path in favorited_projects[:2]:  # Limit to 2
        if project_path and isinstance(project_path, str):
            print(f"FAVORITED_PROJECT={project_path}")
except Exception:
    pass
PYTHON_EOF
)
            if [[ -n "$cache_data" ]]; then
              cache_used=true
              while IFS='=' read -r key value; do
                case "$key" in
                  FAVORITED_PROJECT) [[ -n "$value" ]] && favorited_projects+=("$value") ;;
                esac
              done <<< "$cache_data"
            fi
          fi
        fi
        
        # Fallback to function if cache not available or stale
        if [[ "$cache_used" != "true" ]]; then
          if declare -f get_favorited_projects &>/dev/null; then
            while IFS= read -r project_dir; do
              [[ -n "$project_dir" ]] && favorited_projects+=("$project_dir")
            done < <(get_favorited_projects 2>/dev/null)
          fi
        fi
        
        # Calculate which project was selected (903 = first, 904 = second)
        local project_index=$((choice - 903))
        if [[ $project_index -ge 0 && $project_index -lt ${#favorited_projects[@]} ]]; then
          local selected_project_dir="${favorited_projects[$project_index]}"
          local project_slug=$(basename "$selected_project_dir")
          local project_readme="${selected_project_dir}/README.md"
          local project_name="$project_slug"
          if [[ -f "$project_readme" ]]; then
            project_name=$(gtd_get_frontmatter_value "$project_readme" "name" 2>/dev/null || echo "$project_slug")
            [[ -z "$project_name" ]] && project_name=$(gtd_get_frontmatter_value "$project_readme" "project" 2>/dev/null || echo "$project_slug")
          fi
          
          clear
          echo ""
          echo -e "${BOLD}⭐ Favorited Project: ${project_name}${NC}"
          echo ""
          echo "What would you like to do?"
          echo ""
          echo "  1) Quick Edit (view/edit project)"
          echo "  2) View Project Tasks"
          echo "  3) View Full Project"
          echo "  4) ⭐ Unfavorite (remove from favorites)"
          echo ""
          echo -e "${YELLOW}0)${NC} Back to Main Menu"
          echo ""
          echo -n "Choose: "
          read action_choice
          
          case "$action_choice" in
            1)
              # Quick edit - view project
              if command -v gtd-project &>/dev/null; then
                gtd-project view "$project_slug"
                echo ""
                echo "What would you like to edit?"
                echo "  1) Update project status"
                echo "  2) Add task to project"
                echo "  3) Add note to project"
                echo ""
                echo -e "${YELLOW}0)${NC} Back"
                echo ""
                echo -n "Choose: "
                read edit_choice
                
                case "$edit_choice" in
                  1)
                    echo -n "New status: "
                    read new_status
                    if [[ -n "$new_status" ]]; then
                      gtd-project status "$project_slug" "$new_status"
                    fi
                    ;;
                  2)
                    echo -n "Task description: "
                    read task_desc
                    if [[ -n "$task_desc" ]]; then
                      gtd-project add-task "$project_slug" "$task_desc"
                    fi
                    ;;
                  3)
                    gtd-project add-note "$project_slug"
                    ;;
                esac
              else
                gtd_feedback error "gtd-project command not found"
              fi
              gtd_quick_pause
              ;;
            2)
              # View and manage project tasks interactively
              # Check if review_project_tasks function exists (from gtd-wizard-org.sh)
              if declare -f review_project_tasks &>/dev/null; then
                review_project_tasks "$project_slug" "$project_name"
              else
                # Fallback: use gtd-project view and offer basic interaction
                if command -v gtd-project &>/dev/null; then
                  clear
                  echo ""
                  echo -e "${BOLD}⭐ Project Tasks: ${project_name}${NC}"
                  echo ""
                  gtd-project view "$project_slug" | grep -A 100 "## Tasks" || gtd-project view "$project_slug"
                  echo ""
                  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                  echo ""
                  echo "What would you like to do?"
                  echo "  1) Select a task to manage (complete, edit, add notes)"
                  echo "  2) Back to project menu"
                  echo ""
                  echo -n "Choose: "
                  read task_action
                  
                  case "$task_action" in
                    1)
                      # Get tasks in project
                      local project_dir="${PROJECTS_PATH:-$HOME/Documents/gtd/1-projects}/${project_slug}"
                      local tasks=()
                      if [[ -d "$project_dir" ]]; then
                        while IFS= read -r task_file; do
                          [[ ! -f "$task_file" ]] && continue
                          [[ "$task_file" == */README.md ]] && continue
                          local status=$(gtd_get_frontmatter_value "$task_file" "status" 2>/dev/null)
                          if [[ "$status" == "active" ]]; then
                            tasks+=("$task_file")
                          fi
                        done < <(find "$project_dir" -name "*.md" -type f 2>/dev/null)
                      fi
                      
                      if [[ ${#tasks[@]} -eq 0 ]]; then
                        echo ""
                        echo "No active tasks found in this project."
                        gtd_quick_pause
                      else
                        # Display tasks for selection
                        echo ""
                        echo "Select a task:"
                        local task_index=1
                        local task_ids=()
                        for task_file in "${tasks[@]}"; do
                          local task_id=$(basename "$task_file" .md)
                          task_ids+=("$task_id")
                          local task_name=$(head -20 "$task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || echo "$task_id")
                          if [[ ${#task_name} -gt 50 ]]; then
                            task_name="${task_name:0:47}..."
                          fi
                          echo "  ${task_index}) ${task_name}"
                          ((task_index++))
                        done
                        echo ""
                        echo -n "Task number: "
                        read selected_num
                        
                        if [[ "$selected_num" =~ ^[0-9]+$ ]] && [[ "$selected_num" -ge 1 ]] && [[ "$selected_num" -le ${#tasks[@]} ]]; then
                          local selected_task_id="${task_ids[$((selected_num - 1))]}"
                          local selected_task_file="${tasks[$((selected_num - 1))]}"
                          local selected_task_name=$(head -20 "$selected_task_file" 2>/dev/null | grep "^# " | head -1 | sed 's/^# //' || echo "$selected_task_id")
                          
                          clear
                          echo ""
                          echo -e "${BOLD}Task: ${selected_task_name}${NC}"
                          echo ""
                          echo "What would you like to do?"
                          echo "  1) Complete task"
                          echo "  2) Edit task"
                          echo "  3) Add note to task"
                          echo "  4) View full task"
                          echo ""
                          echo -e "${YELLOW}0)${NC} Back"
                          echo ""
                          echo -n "Choose: "
                          read task_choice
                          
                          case "$task_choice" in
                            1)
                              if command -v gtd-task &>/dev/null; then
                                gtd-task complete "$selected_task_id"
                                gtd_action_success "completed" "task" "$selected_task_name"
                              else
                                gtd_feedback error "gtd-task command not found"
                              fi
                              gtd_quick_pause
                              ;;
                            2)
                              if command -v gtd-task &>/dev/null; then
                                gtd-task update "$selected_task_id"
                              else
                                gtd_feedback error "gtd-task command not found"
                              fi
                              gtd_quick_pause
                              ;;
                            3)
                              if command -v gtd-task &>/dev/null; then
                                echo -n "Note title (or press Enter to be prompted): "
                                read note_title
                                if [[ -n "$note_title" ]]; then
                                  gtd-task add-note "$selected_task_id" "$note_title"
                                else
                                  gtd-task add-note "$selected_task_id"
                                fi
                              else
                                gtd_feedback error "gtd-task command not found"
                              fi
                              gtd_quick_pause
                              ;;
                            4)
                              if command -v gtd-task &>/dev/null; then
                                gtd-task view "$selected_task_id"
                                gtd_enter_to_continue
                              else
                                gtd_feedback error "gtd-task command not found"
                              fi
                              ;;
                            0|"")
                              # Back - do nothing
                              ;;
                            *)
                              echo "Invalid choice"
                              gtd_quick_pause
                              ;;
                          esac
                        else
                          gtd_feedback error "Invalid task number"
                          gtd_quick_pause
                        fi
                      fi
                      ;;
                    2|0|"")
                      # Back - do nothing
                      ;;
                    *)
                      echo "Invalid choice"
                      gtd_quick_pause
                      ;;
                  esac
                else
                  gtd_feedback error "gtd-project command not found"
                  gtd_quick_pause
                fi
              fi
              ;;
            3)
              # View full project
              if command -v gtd-project &>/dev/null; then
                gtd-project view "$project_slug"
                gtd_enter_to_continue
              else
                gtd_feedback error "gtd-project command not found"
                gtd_quick_pause
              fi
              ;;
            4)
              # Unfavorite project
              if [[ -f "$project_readme" ]]; then
                if grep -q "^favorite:" "$project_readme" 2>/dev/null; then
                  if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s/^favorite:.*/favorite: false/" "$project_readme"
                  else
                    sed -i "s/^favorite:.*/favorite: false/" "$project_readme"
                  fi
                  echo ""
                  echo -e "${GREEN}✓${NC} Project '$project_name' unfavorited"
                  echo "   It will no longer appear in your favorited items list."
                else
                  echo ""
                  echo -e "${YELLOW}⚠️${NC} Project is not currently favorited"
                fi
                echo ""
                gtd_quick_pause
              else
                gtd_feedback error "Project README not found"
                gtd_quick_pause
              fi
              ;;
            0|"")
              # Back - do nothing
              ;;
            *)
              echo "Invalid choice"
              gtd_quick_pause
              ;;
          esac
        else
          gtd_feedback error "Favorited project not found"
          gtd_quick_pause
        fi
        ;;
      0|"")
        clear
        echo "Goodbye! Use 'gtd-wizard' anytime you need help organizing."
        exit 0
        ;;
      *)
        echo "Invalid choice. Press Enter..."
        read
        ;;
    esac
  done
}
