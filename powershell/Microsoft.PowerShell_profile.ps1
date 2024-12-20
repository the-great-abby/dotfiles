# Setup Git for Powershell
# Import-Module posh-git
# Import-Module oh-my-posh

#Set-Theme Paradox
# pwsh -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
Set-PSReadlineOption -EditMode vi

# ahh yes... this would be so nice if it was a built in variable
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set so pip won't run without a virtualenv
$env:PIP_REQUIRE_VIRTUALENV=1

# Make the tab completion work like Bash
Set-PSReadlineKeyHandler -Key Tab -Function Complete

# Remove System PATH to OpenSSH to use my version
$remove = "C:\Windows\System32\OpenSSH\"
$env:Path = ($env:Path.Split(';') | Where-Object -FilterScript {$_ -ne $Remove}) -join ';'
$add = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319"
$env:Path = $env:Path + ';' + $add

$add = "~\scoop\modules"
$env:PSModulePath = $env:PSModulePath + ';' + $add

$env:SECOND_BRAIN = "~/code/work/obsidian/filevine"
# Clean out so Curl works as expected
if (Test-Path Alias:curl) { remove-item alias:curl }
set-alias -name ib -value Invoke-Build

# $GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
# set-theme agnoster

# =================================================================
# Make emacs launch on the command line in powershell
# $emacs_wildcard = "${Env:ProgramFiles}\Emacs\*\bin\emacs.exe"
# if ($(Test-Path $emacs_wildcard)) {
    # $emacs_path = (Get-ChildItem $emacs_wildcard)[-1].FullName -replace ' ', '` '
      # function emacs { "$emacs_path -nw $args" | Invoke-Expression }
# }

# ===========================================================
# Helper functions
# ===========================================================
Get-ChildItem ${HOME}\code\dotfiles\powershell\functions\*.ps1 | %{. $_ }

# z directory fun
import-module zlocation

if (test-path alias:set) { remove-item alias:set }


# ================================================================
# Powershell history
if ((Get-Content $PROFILE | Select-String "Import-Module PSReadLine").Length -eq 0) {
    Write-Output "Import-Module PSReadLine" | Add-Content "$PROFILE"
}
 Set-PSReadLineOption -PredictionSource HistoryAndPlugin
if ((Get-Content $PROFILE | Select-String "Set-PSReadLineOption -PredictionSource History").Length -eq 0) {
    Write-Output "Set-PSReadLineOption -PredictionSource History" | Add-Content "$PROFILE"
}
 Set-PSReadLineOption -PredictionViewStyle InlineView
if ((Get-Content $PROFILE | Select-String "Set-PSReadLineOption -PredictionViewStyle ListView").Length -eq 0) {
    Write-Output "Set-PSReadLineOption -PredictionViewStyle ListView" | Add-Content "$PROFILE"
}
if ((Get-Content $PROFILE | Select-String "Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete").Length -eq 0) {
    Write-Output "Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete" | Add-Content "$PROFILE"
}
if ((Get-Content $PROFILE | Select-String "Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward").Length -eq 0) {
    Write-Output "Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward" | Add-Content "$PROFILE"
}
if ((Get-Content $PROFILE | Select-String "Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward").Length -eq 0) {
    Write-Output "Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward" | Add-Content "$PROFILE"
}

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# Unlock-SecretStore -Password (Import-Clixml ~\.vaultmanagement\vaultmanagement)

# . ${HOME}/code/dotfiles/starship/init.ps1


# . ${HOME}/code/dotfiles/starship/sections/terraform.ps1
# try { $null = gcm pshazz -ea stop; pshazz init 'default' } catch { }

oh-my-posh init pwsh | Invoke-Expression

