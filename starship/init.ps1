  $Env:STARSHIP_CONFIG = "${HOME}/.starship.toml"
  $ENV:STARSHIP_CACHE = "$HOME\AppData\Local\Temp"
  Invoke-Expression (&starship init powershell)
