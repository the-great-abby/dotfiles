Write-Output "
============================
Help PS1 Functions Loaded
============================
"
function reload_functions_help {
  . ${HOME}/code/dotfiles/powershell/functions/help.ps1
}

function help_powershell_piping_commands {
  Write-Output "====================================="
  Write-Output "You can pipe commands together"
  Write-Output "get_environment_variables | Select-String 'google'"
  Write-Output "get_environment_variables | sls 'google'"
  Write-Output "get_environment_variables | findstr 'google'"
  Write-Output "====================================="
}

