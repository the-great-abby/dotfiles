#!/bin/bash
# Common environment configuration for both bash and zsh
# This file sets up PATH and other environment variables that should be available
# to both interactive shells and bash scripts (like gtd commands)

# Initialize PATH with system paths if empty or missing
if [[ -z "$PATH" ]] || [[ ":$PATH:" != *":/usr/bin:"* ]]; then
  export PATH="/usr/bin:/bin:/usr/sbin:/sbin${PATH:+:$PATH}"
fi

# System paths - ensure they're always present
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
  export PATH="/usr/bin:${PATH}"
fi
if [[ ":$PATH:" != *":/bin:"* ]]; then
  export PATH="/bin:${PATH}"
fi
if [[ ":$PATH:" != *":/usr/sbin:"* ]]; then
  export PATH="/usr/sbin:${PATH}"
fi
if [[ ":$PATH:" != *":/sbin:"* ]]; then
  export PATH="/sbin:${PATH}"
fi

# Homebrew (Apple Silicon)
if [[ -d "/opt/homebrew/bin" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:${PATH}"
fi

# Homebrew (Intel/Linux)
if [[ -d "/usr/local/bin" ]]; then
  export PATH="/usr/local/bin:${PATH}"
fi

# Linuxbrew
if [[ -d "/home/linuxbrew/.linuxbrew/bin" ]]; then
  export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"
fi

# npm global packages
if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# User bin directory
if [[ -d "${HOME}/bin" ]]; then
  export PATH="${HOME}/bin:${PATH}"
fi

# Dotfiles bin directory (GTD commands and other utilities)
if [[ -d "${HOME}/code/dotfiles/bin" ]]; then
  export PATH="${HOME}/code/dotfiles/bin:${PATH}"
fi

# Personal dotfiles location (if different)
if [[ -d "${HOME}/code/personal/dotfiles/bin" ]]; then
  export PATH="${HOME}/code/personal/dotfiles/bin:${PATH}"
fi

# LM Studio CLI
if [[ -d "${HOME}/.lmstudio/bin" ]] || [[ -d "/Users/abbymalson/.lmstudio/bin" ]]; then
  if [[ -d "${HOME}/.lmstudio/bin" ]]; then
    export PATH="${PATH}:${HOME}/.lmstudio/bin"
  elif [[ -d "/Users/abbymalson/.lmstudio/bin" ]]; then
    export PATH="${PATH}:/Users/abbymalson/.lmstudio/bin"
  fi
fi

# Rancher Desktop
if [[ -d "${HOME}/.rd/bin" ]]; then
  export PATH="${HOME}/.rd/bin:${PATH}"
fi

# Ruby gems
if [[ -d "${HOME}/.gem/ruby/3.0.0/bin" ]]; then
  export PATH="${HOME}/.gem/ruby/3.0.0/bin:${PATH}"
fi

# Final safety check: ensure system binaries are always in PATH
if [[ ":$PATH:" != *":/usr/bin:"* ]]; then
  export PATH="/usr/bin:${PATH}"
fi
if [[ ":$PATH:" != *":/bin:"* ]]; then
  export PATH="/bin:${PATH}"
fi

