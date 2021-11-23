Write-Output "
============================
Starship PS1 Functions Loaded
============================
"
# Starship Settings
# ================================================================
# If we want to specify default starship.toml file location
# $ENV:STARSHIP_CONFIG = "$HOME\.starship"
# $Env:STARSHIP_CONFIG = "${HOME}./starship/config.toml"

# Where do we want to store Default Logs

# Invoke-Expression (&starship init powershell)
function reload_functions_starship {
  . ${HOME}/code/dotfiles/powershell/functions/starship.ps1
  . ${HOME}/code/dotfiles/starship/init.ps1
  Write-Output "
  . `${HOME}/code/dotfiles/powershell/functions/starship.ps1
  . `${HOME}/code/dotfiles/starship/init.ps1
  "
}

function set_starship_settings {
  $Env:STARSHIP_CONFIG = "${HOME}/.config/starship.toml"
  $ENV:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"
  #. ${HOME}/code/dotfiles/powershell/functions/starship.ps1
}

function update_starship {
  scoop update starship
}

function start_starship {
  Invoke-Expression (&starship init powershell)
}
