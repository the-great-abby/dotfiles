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
  local mode_daily_log="DAILY_LOG_DIR_${mode_upper}"
  if [[ -n "${!mode_daily_log:-}" ]]; then
    # Update active DAILY_LOG_DIR in daily_log_config
    if grep -q "^DAILY_LOG_DIR=" "$daily_log_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"${!mode_daily_log}\"|" "$daily_log_config"
      else
        sed -i "s|^DAILY_LOG_DIR=.*|DAILY_LOG_DIR=\"${!mode_daily_log}\"|" "$daily_log_config"
      fi
    else
      # Add it
      echo "DAILY_LOG_DIR=\"${!mode_daily_log}\"" >> "$daily_log_config"
    fi
    export DAILY_LOG_DIR="${!mode_daily_log}"
  fi
  
  # Apply mode-specific GTD_BASE_DIR if it exists
  local mode_gtd_base="GTD_BASE_DIR_${mode_upper}"
  if [[ -n "${!mode_gtd_base:-}" ]]; then
    # Update active GTD_BASE_DIR in gtd_config
    if grep -q "^GTD_BASE_DIR=" "$gtd_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"${!mode_gtd_base}\"|" "$gtd_config"
      else
        sed -i "s|^GTD_BASE_DIR=.*|GTD_BASE_DIR=\"${!mode_gtd_base}\"|" "$gtd_config"
      fi
    else
      # Add it after Directory Structure comment
      if grep -q "^# Directory Structure" "$gtd_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "/^# Directory Structure/a\\
GTD_BASE_DIR=\"${!mode_gtd_base}\"
" "$gtd_config"
        else
          sed -i "/^# Directory Structure/a GTD_BASE_DIR=\"${!mode_gtd_base}\"" "$gtd_config"
        fi
      else
        echo "GTD_BASE_DIR=\"${!mode_gtd_base}\"" >> "$gtd_config"
      fi
    fi
    export GTD_BASE_DIR="${!mode_gtd_base}"
  fi
  
  # Apply mode-specific SECOND_BRAIN if it exists
  local mode_second_brain="SECOND_BRAIN_${mode_upper}"
  if [[ -n "${!mode_second_brain:-}" ]]; then
    # Update active SECOND_BRAIN in gtd_config
    if grep -q "^SECOND_BRAIN=" "$gtd_config" 2>/dev/null; then
      if [[ -n "$is_macos" ]]; then
        sed -i '' "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"${!mode_second_brain}\"|" "$gtd_config"
      else
        sed -i "s|^SECOND_BRAIN=.*|SECOND_BRAIN=\"${!mode_second_brain}\"|" "$gtd_config"
      fi
    else
      # Add it after Second Brain Integration comment
      if grep -q "^# Second Brain Integration" "$gtd_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "/^# Second Brain Integration/a\\
SECOND_BRAIN=\"${!mode_second_brain}\"
" "$gtd_config"
        else
          sed -i "/^# Second Brain Integration/a SECOND_BRAIN=\"${!mode_second_brain}\"" "$gtd_config"
        fi
      else
        echo "SECOND_BRAIN=\"${!mode_second_brain}\"" >> "$gtd_config"
      fi
    fi
    export SECOND_BRAIN="${!mode_second_brain}"
  fi
  
  # Apply mode-specific settings from .gtd_config_database if it exists
  if [[ -f "$db_config" ]]; then
    # Check for mode-specific GTD_VECTORIZATION_ENABLED
    local mode_vectorization="GTD_VECTORIZATION_ENABLED_${mode_upper}"
    if [[ -n "${!mode_vectorization:-}" ]]; then
      # Use mode-specific value
      local vectorization_value="${!mode_vectorization}"
      if grep -q "^GTD_VECTORIZATION_ENABLED=" "$db_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=${vectorization_value}/" "$db_config"
        else
          sed -i "s/^GTD_VECTORIZATION_ENABLED=.*/GTD_VECTORIZATION_ENABLED=${vectorization_value}/" "$db_config"
        fi
      else
        # Add it
        echo "GTD_VECTORIZATION_ENABLED=${vectorization_value}" >> "$db_config"
      fi
    fi
    
    # Check for mode-specific RABBITMQ_ENABLED
    local mode_rabbitmq="RABBITMQ_ENABLED_${mode_upper}"
    if [[ -n "${!mode_rabbitmq:-}" ]]; then
      # Use mode-specific value
      local rabbitmq_value="${!mode_rabbitmq}"
      if grep -q "^RABBITMQ_ENABLED=" "$db_config" 2>/dev/null; then
        if [[ -n "$is_macos" ]]; then
          sed -i '' "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=${rabbitmq_value}/" "$db_config"
        else
          sed -i "s/^RABBITMQ_ENABLED=.*/RABBITMQ_ENABLED=${rabbitmq_value}/" "$db_config"
        fi
      else
        # Add it after RABBITMQ_URL line if found, otherwise append
        if grep -q "^RABBITMQ_URL=" "$db_config" 2>/dev/null; then
          if [[ -n "$is_macos" ]]; then
            sed -i '' "/^RABBITMQ_URL=/a\\
RABBITMQ_ENABLED=${rabbitmq_value}
" "$db_config"
          else
            sed -i "/^RABBITMQ_URL=/a RABBITMQ_ENABLED=${rabbitmq_value}" "$db_config"
          fi
        else
          echo "RABBITMQ_ENABLED=${rabbitmq_value}" >> "$db_config"
        fi
      fi
    fi
    
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
    # Count JSON files with status "completed" (not error)
    completed_advice_count=$(find "$advice_results_dir" -name "*.json" -type f 2>/dev/null | while read -r file; do
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

# Test execution wizard
test_execution_wizard() {
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
  echo -e "${BOLD}${CYAN}All Tests:${NC}"
  echo -e "  ${GREEN}12)${NC} Run complete test suite (all bash + Python)"
  echo ""
  echo -e "  ${YELLOW}0)${NC} Back to Main Menu"
  echo ""
  echo -n "Choose: "
  read choice
  
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
        bash "$tests_dir/run_tests.sh" 2>&1 | grep -E "(test_|Running:|Test|PASS|FAIL|Summary)" || bash "$tests_dir/run_tests.sh"
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
      echo ""
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
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
      gtd_quick_pause
      ;;
    12)
      echo ""
      echo -e "${CYAN}Running complete test suite...${NC}"
      echo ""
      if [[ -f "$tests_dir/run_tests.sh" ]]; then
        bash "$tests_dir/run_tests.sh"
      else
        echo -e "${RED}Test runner not found: $tests_dir/run_tests.sh${NC}"
      fi
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
  echo ""
  echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# Dashboard - Show system status and quick stats (polished version)
show_dashboard() {
  # Get current date/time
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  local day_name=$(date +"%A" 2>/dev/null || echo "")
  
  echo ""
  gtd_section_divider "$CYAN"
  echo -e "${BOLD}${CYAN}🎯 GTD Command Center${NC}"
  if [[ -n "$day_name" ]]; then
    echo -e "${CYAN}   ${day_name}, ${current_date} ${current_time}${NC}"
  else
    echo -e "${CYAN}   ${current_date} ${current_time}${NC}"
  fi
  gtd_section_divider "$CYAN"
  echo ""
  
  # System Status Section - Compact format
  echo -e "${BOLD}📊 System Status${NC}"
  
  # Inbox count (cached for 5 seconds) - with error handling
  local inbox_count=0
  if [[ -n "${INBOX_PATH:-}" ]]; then
    inbox_count=$(gtd_get_cached_count "inbox" "${INBOX_PATH}" "*.md" 5 2>/dev/null || echo "0")
    # Ensure it's numeric
    [[ "$inbox_count" =~ ^[0-9]+$ ]] || inbox_count=0
  fi
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${RED}📥${NC} ${BOLD}Inbox:${NC} ${inbox_count} ${YELLOW}→ Process first! (2)${NC}"
  else
    echo -e "  ${GREEN}✓${NC} ${BOLD}Inbox:${NC} Empty"
  fi
  
  # Active tasks count (cached) - with error handling
  local tasks_count=0
  if [[ -n "${TASKS_PATH:-}" ]]; then
    tasks_count=$(gtd_get_cached_count "tasks" "${TASKS_PATH}" "*.md" 5 2>/dev/null || echo "0")
    # Ensure it's numeric
    [[ "$tasks_count" =~ ^[0-9]+$ ]] || tasks_count=0
  fi
  echo -e "  ${CYAN}✅${NC} ${BOLD}Tasks:${NC} ${tasks_count}"
  
  # Active projects count (cached) - special pattern for projects - with error handling
  local projects_count=0
  if [[ -n "${PROJECTS_PATH:-}" ]]; then
    projects_count=$(gtd_get_cached_count "projects" "${PROJECTS_PATH}" "projects" 5 2>/dev/null || echo "0")
    # Ensure it's numeric
    [[ "$projects_count" =~ ^[0-9]+$ ]] || projects_count=0
  fi
  echo -e "  ${CYAN}📁${NC} ${BOLD}Projects:${NC} ${projects_count}"
  
  # Areas count (cached) - with error handling
  local areas_count=0
  if [[ -n "${AREAS_PATH:-}" ]]; then
    areas_count=$(gtd_get_cached_count "areas" "${AREAS_PATH}" "*.md" 5 2>/dev/null || echo "0")
    # Ensure it's numeric
    [[ "$areas_count" =~ ^[0-9]+$ ]] || areas_count=0
  fi
  echo -e "  ${CYAN}🎯${NC} ${BOLD}Areas:${NC} ${areas_count}"
  
  # Smart Suggestions count (with timeout protection and efficiency)
  local suggestions_dir="$HOME/Documents/gtd/suggestions"
  local total_suggestions=0
  local high_conf_suggestions=0
  local medium_conf_suggestions=0
  local low_conf_suggestions=0
  
  if [[ -d "$suggestions_dir" ]]; then
    # Use a simple, fast approach: count pending files with single grep
    # This is much faster than reading each file individually
    set +e  # Allow errors in case of permission issues
    total_suggestions=$(grep -l '"status"[[:space:]]*:[[:space:]]*"pending"' "$suggestions_dir"/*.json 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    set -e
    [[ "$total_suggestions" =~ ^[0-9]+$ ]] || total_suggestions=0
    
    # Only do detailed confidence breakdown if reasonable number of files (< 50)
    # This prevents timeout on systems with many suggestion files
    if [[ $total_suggestions -gt 0 && $total_suggestions -lt 50 ]]; then
      local processed=0
      while IFS= read -r suggestion_file && [[ $processed -lt 50 ]]; do
        # Quick check - only read if file exists and is readable
        if [[ ! -r "$suggestion_file" ]]; then
          continue
        fi
        
        # Single read of file content
        local file_content=$(head -20 "$suggestion_file" 2>/dev/null || echo "")
        if [[ -z "$file_content" ]]; then
          continue
        fi
        
        # Get confidence level (single grep)
        local confidence=$(echo "$file_content" | grep -o '"confidence"[[:space:]]*:[[:space:]]*[0-9.]*' 2>/dev/null | sed 's/.*:[[:space:]]*//' | head -1)
        
        if [[ -n "$confidence" ]]; then
          # Use awk for numeric comparison (more reliable than bc)
          if awk "BEGIN {exit !($confidence >= 0.85)}" 2>/dev/null; then
            ((high_conf_suggestions++))
          elif awk "BEGIN {exit !($confidence >= 0.70)}" 2>/dev/null; then
            ((medium_conf_suggestions++))
          else
            ((low_conf_suggestions++))
          fi
        fi
        ((processed++))
      done < <(grep -l '"status"[[:space:]]*:[[:space:]]*"pending"' "$suggestions_dir"/*.json 2>/dev/null | head -50)
    fi
  fi
  
  # Display suggestions with confidence breakdown
  if [[ $total_suggestions -gt 0 ]]; then
    local suggestion_details=""
    [[ $high_conf_suggestions -gt 0 ]] && suggestion_details+="${GREEN}⭐${high_conf_suggestions}${NC} "
    [[ $medium_conf_suggestions -gt 0 ]] && suggestion_details+="${YELLOW}●${medium_conf_suggestions}${NC} "
    [[ $low_conf_suggestions -gt 0 ]] && suggestion_details+="${CYAN}○${low_conf_suggestions}${NC}"
    echo -e "  ${CYAN}💡${NC} ${BOLD}Suggestions:${NC} ${total_suggestions} ${suggestion_details} ${YELLOW}→ (9)${NC}"
  fi
  
  echo ""
  
  # Quick Stats Section - Compact format
  echo -e "${BOLD}📈 Quick Stats${NC}"
  
  # Logging streak (with timeout protection)
  local streak_script=""
  if command -v gtd-log-stats &>/dev/null; then
    streak_script="gtd-log-stats"
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/dotfiles/bin/gtd-log-stats"
  elif [[ -f "$HOME/code/personal/dotfiles/bin/gtd-log-stats" ]]; then
    streak_script="$HOME/code/personal/dotfiles/bin/gtd-log-stats"
  fi
  
  if [[ -n "$streak_script" ]]; then
    local current_streak=0
    # Use timeout if available to prevent hanging
    if command -v timeout &>/dev/null; then
      current_streak=$(timeout 2 "$streak_script" streak 2>/dev/null || echo "0")
    else
      current_streak=$("$streak_script" streak 2>/dev/null || echo "0")
    fi
    current_streak=$(echo "$current_streak" | tr -d '[:space:]')
    if [[ ! "$current_streak" =~ ^[0-9]+$ ]]; then
      current_streak=0
    fi
    if [[ $current_streak -gt 0 ]]; then
      echo -e "  ${GREEN}🔥${NC} ${BOLD}Streak:${NC} ${current_streak} day(s)"
    else
      echo -e "  ${YELLOW}📝${NC} ${BOLD}Streak:${NC} Start logging!"
    fi
  fi
  
  # Today's log entries
  local today=$(gtd_get_today)
  local today_log="${DAILY_LOG_DIR:-$HOME/Documents/daily_logs}/${today}.md"
  local today_entries=0
  if [[ -f "$today_log" ]]; then
    today_entries=$(grep -c "^[0-9][0-9]:[0-9][0-9] -" "$today_log" 2>/dev/null || echo "0")
  fi
  echo -e "  ${CYAN}📝${NC} ${BOLD}Today:${NC} ${today_entries} entries"
  
  # Waiting for items (cached)
  # Waiting count - with error handling
  local waiting_count=0
  if [[ -n "${WAITING_PATH:-}" ]]; then
    set +e
    waiting_count=$(gtd_get_cached_count "waiting" "${WAITING_PATH}" "*.md" 5 2>/dev/null || echo "0")
    set -e
    # Ensure it's numeric
    [[ "$waiting_count" =~ ^[0-9]+$ ]] || waiting_count=0
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳${NC} ${BOLD}Waiting:${NC} ${waiting_count}"
  fi
  
  # Someday/Maybe items (cached) - with error handling
  local someday_count=0
  if [[ -n "${SOMEDAY_PATH:-}" ]]; then
    set +e
    someday_count=$(gtd_get_cached_count "someday" "${SOMEDAY_PATH}" "*.md" 5 2>/dev/null || echo "0")
    set -e
    # Ensure it's numeric
    [[ "$someday_count" =~ ^[0-9]+$ ]] || someday_count=0
  fi
  if [[ $someday_count -gt 0 ]]; then
    echo -e "  ${MAGENTA}💭${NC} ${BOLD}Someday:${NC} ${someday_count}"
  fi
  
  echo ""
  
  # Smart Defaults Section
  show_smart_defaults
  
  # Quick Actions Section - Compact format
  echo -e "${BOLD}⚡ Quick Actions${NC}"
  if [[ $inbox_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⚠️${NC} ${BOLD}${inbox_count}${NC} inbox → Press ${BOLD}2${NC}"
  fi
  if [[ $waiting_count -gt 0 ]]; then
    echo -e "  ${YELLOW}⏳${NC} ${waiting_count} waiting → Review (6)"
  fi
  echo -e "  ${CYAN}💡${NC} 'What now?' → ${BOLD}40${NC}"
  echo -e "  ${CYAN}📝${NC} Daily log → ${BOLD}15${NC}"
  echo -e "  ${CYAN}📊${NC} Full status → ${BOLD}17${NC}"
  echo ""
  
  gtd_section_divider "$CYAN"
  echo ""
}

# Compact dashboard - one-line status display
show_compact_dashboard() {
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  
  # Get counts
  local inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  local tasks_count=0
  if [[ -d "${TASKS_PATH}" ]]; then
    tasks_count=$(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  local projects_count=0
  if [[ -d "${PROJECTS_PATH}" ]]; then
    projects_count=$(ls -1 "${PROJECTS_PATH}"/*/README.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  local areas_count=0
  if [[ -d "${AREAS_PATH}" ]]; then
    areas_count=$(ls -1 "${AREAS_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  # Smart Suggestions count
  local suggestions_count=0
  local suggestions_dir="$HOME/Documents/gtd/suggestions"
  if [[ -d "$suggestions_dir" ]]; then
    while IFS= read -r suggestion_file; do
      local status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$suggestion_file" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
      if [[ "$status" == "pending" ]]; then
        ((suggestions_count++))
      fi
    done < <(find "$suggestions_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null)
  fi
  
  # One-line display
  echo -e "${BOLD}${CYAN}🎯 GTD${NC} ${current_date} ${current_time} | ${RED}📥${NC} ${inbox_count} | ${CYAN}✅${NC} ${tasks_count} | ${CYAN}📁${NC} ${projects_count} | ${CYAN}🎯${NC} ${areas_count} | ${BOLD}💡${NC} ${suggestions_count}"
}

# Plain compact dashboard - no colors (for tmux status bar)
show_plain_dashboard() {
  local current_date=$(gtd_get_today)
  local current_time=$(gtd_get_current_time)
  
  # Get counts
  local inbox_count=$(ls -1 "${INBOX_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  local tasks_count=0
  if [[ -d "${TASKS_PATH}" ]]; then
    tasks_count=$(find "${TASKS_PATH}" -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')
  fi
  local projects_count=0
  if [[ -d "${PROJECTS_PATH}" ]]; then
    projects_count=$(ls -1 "${PROJECTS_PATH}"/*/README.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  local areas_count=0
  if [[ -d "${AREAS_PATH}" ]]; then
    areas_count=$(ls -1 "${AREAS_PATH}"/*.md 2>/dev/null | wc -l | tr -d ' ')
  fi
  
  # Smart Suggestions count
  local suggestions_count=0
  local suggestions_dir="$HOME/Documents/gtd/suggestions"
  if [[ -d "$suggestions_dir" ]]; then
    while IFS= read -r suggestion_file; do
      local status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$suggestion_file" 2>/dev/null | sed 's/.*"\([^"]*\)"/\1/')
      if [[ "$status" == "pending" ]]; then
        ((suggestions_count++))
      fi
    done < <(find "$suggestions_dir" -maxdepth 1 -name "*.json" -type f 2>/dev/null)
  fi
  
  # One-line display WITHOUT colors
  echo "🎯 GTD ${current_date} ${current_time} | 📥 ${inbox_count} | ✅ ${tasks_count} | 📁 ${projects_count} | 🎯 ${areas_count} | 💡 ${suggestions_count}"
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
  
  echo -e "${BOLD}${CYAN}📥 INPUTS - Capture & Process:${NC}"
  echo -e "${GREEN}1)${NC} 📥 Capture something to inbox"
  echo -e "${GREEN}2)${NC} 📋 Process inbox items"
  echo -e "${GREEN}15)${NC} 📝 Log to daily log"
  echo -e "${GREEN}31)${NC} 👁️  View daily log"
  echo -e "${GREEN}19)${NC} 🌅 Morning/Evening Check-In"
  echo ""
  
  echo -e "${BOLD}${CYAN}🗂️  ORGANIZATION - Manage Your System:${NC}"
  echo -e "${GREEN}3)${NC} ✅ Manage tasks"
  echo -e "${GREEN}4)${NC} 📁 Manage projects"
  echo -e "${GREEN}5)${NC} 🎯 Manage areas of responsibility"
  echo -e "${GREEN}8)${NC} 🗺️  Manage MOCs (Maps of Content)"
  echo -e "${GREEN}23)${NC} 🔗 Zettelkasten (atomic notes)"
  echo -e "${GREEN}55)${NC} 🎯 Prioritization Review"
  echo ""
  echo -e "${BOLD}${CYAN}🧠 SECOND BRAIN - Advanced Operations:${NC}"
  echo -e "${GREEN}48)${NC} 🔗 Connect notes"
  echo -e "${GREEN}49)${NC} 📊 Converge/consolidate notes"
  echo -e "${GREEN}50)${NC} 🔍 Discover connections"
  echo -e "${GREEN}51)${NC} 📝 Distill (progressive summarization)"
  echo -e "${GREEN}52)${NC} 💡 Diverge (expand ideas)"
  echo -e "${GREEN}53)${NC} 🌲 Evergreen notes"
  echo -e "${GREEN}54)${NC} 📦 Note packets"
  echo ""
  
  echo -e "${BOLD}${CYAN}📤 OUTPUTS - Reviews & Creation:${NC}"
  echo -e "${GREEN}6)${NC} 📊 Review (daily/weekly/monthly)"
  echo -e "${GREEN}7)${NC} 🧠 Sync with Second Brain"
  echo -e "${GREEN}57)${NC} 🔄 Bidirectional Obsidian Sync"
  echo -e "${GREEN}59)${NC} 📊 Enhanced Review System"
  echo -e "${GREEN}62)${NC} 📝 Review Draft Notes (evergreen insights)"
  echo -e "${GREEN}9)${NC} ✍️  Express Phase (create content from notes)"
  echo -e "${GREEN}10)${NC} 📋 Use Templates"
  echo -e "${GREEN}22)${NC} 🎨 Create diagrams & mindmaps"
  echo ""
  
  echo -e "${BOLD}${CYAN}📚 LEARNING - Guides & Discovery:${NC}"
  echo -e "${GREEN}12)${NC} 📚 Learn Organization System (GTD + Second Brain + Zettelkasten)"
  echo -e "${GREEN}13)${NC} 🧠 Learn Second Brain (where to start)"
  echo -e "${GREEN}14)${NC} 🎯 Discover Life Vision (if you don't have a plan)"
  echo -e "${GREEN}20)${NC} ☸️  Learn Kubernetes/CKA"
  echo -e "${GREEN}21)${NC} 🇬🇷 Learn Greek (Language)"
  echo ""
  
  echo -e "${BOLD}${CYAN}🔍 ANALYSIS - Insights & Tracking:${NC}"
  echo -e "${GREEN}16)${NC} 🔍 Search GTD system"
  echo -e "${GREEN}17)${NC} 📊 System status"
  echo -e "${GREEN}25)${NC} 🎯 Goal Tracking & Progress"
  echo -e "${GREEN}26)${NC} ⚡ Energy Audit (drains & boosts)"
  echo -e "${GREEN}30)${NC} 💪 HealthKit & Health Data (disabled)"
  echo -e "${GREEN}34)${NC} 📈 Log statistics & streaks"
  echo -e "${GREEN}35)${NC} 🔗 Metric correlations"
  echo -e "${GREEN}36)${NC} 🔍 Pattern recognition"
  echo -e "${GREEN}37)${NC} 📊 Weekly progress report"
  echo -e "${GREEN}38)${NC} 🧠 Second Brain metrics"
  echo -e "${GREEN}56)${NC} 📊 Success metrics (usage & effectiveness)"
  echo -e "${GREEN}58)${NC} 📚 Learning System Preferences"
  echo ""
  
  echo -e "${BOLD}${CYAN}🛠️  TOOLS & SUPPORT:${NC}"
  echo -e "${GREEN}11)${NC} 🤖 Get advice from personas"
  echo -e "${GREEN}18)${NC} 🔁 Manage habits & recurring tasks"
  echo -e "${GREEN}24)${NC} 🤖 AI Suggestions & MCP Tools"
  echo -e "${GREEN}29)${NC} 📅 Calendar (view, sync tasks, check conflicts)"
  echo -e "${GREEN}39)${NC} ⚡ Energy-aware scheduling"
  echo -e "${GREEN}40)${NC} 🎯 What should I do now? (context-aware)"
  echo -e "${GREEN}41)${NC} 🔍 Find items (advanced search)"
  echo -e "${GREEN}42)${NC} 🎉 Celebrate milestones"
  echo ""
  
  echo -e "${BOLD}${CYAN}⚙️  SETTINGS:${NC}"
  echo -e "${GREEN}27)${NC} ⚙️  Configuration & Setup"
  echo -e "${GREEN}28)${NC} 🎮 Gamification & Habitica"
  echo -e "${GREEN}60)${NC} 💻 Switch Computer Mode (work/home)"
  echo -e "${GREEN}61)${NC} 🧪 Run Unit Tests"
  echo ""
  echo -e "${BOLD}${CYAN}🔧 INFRASTRUCTURE - External Services:${NC}"
  echo -e "${GREEN}63)${NC} 🗄️  Database Infrastructure Wizard"
  echo -e "${GREEN}64)${NC} 🐰 RabbitMQ Management Wizard"
  echo ""
  echo -e "${YELLOW}0)${NC} Exit"
  echo ""
  
  # Show dashboard (command center) at the bottom
  # Wrap in error handling to prevent wizard from crashing if dashboard fails
  if ! show_dashboard 2>/dev/null; then
    # Fallback: show minimal status if dashboard fails
    echo ""
    echo "🎯 GTD Command Center"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "⚠️  Status display unavailable"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
  
  echo -n "Choose: "
}

# Main function - entry point for the wizard
main() {
  # Award XP for opening wizard (first time in this session)
  award_wizard_xp "wizard_use" "Opened GTD wizard"
  
  # Track daily usage
  if command -v gtd-success-metrics &>/dev/null; then
    gtd-success-metrics track "gtd-wizard" 2>/dev/null || true
  elif [[ -f "$HOME/code/dotfiles/bin/gtd-success-metrics" ]]; then
    "$HOME/code/dotfiles/bin/gtd-success-metrics" track "gtd-wizard" 2>/dev/null || true
  fi
  
  while true; do
    show_main_menu
    read choice
    
    # Track wizard option usage for preferences learning
    if [[ "$choice" =~ ^[0-9]+$ ]] && command -v gtd-preferences-learn &>/dev/null; then
      gtd-preferences-learn track-feature "wizard_option" "$choice" 2>/dev/null || true
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
