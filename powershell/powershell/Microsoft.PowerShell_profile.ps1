#Import-Module posh-git
#Import-Module oh-my-posh
#Set-Theme Paradox
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

$add = "~\scoop\modules"
$env:PSModulePath = $env:PSModulePath + ';' + $add

# Clean out so Curl works as expected
if (Test-Path Alias:curl) { remove-item alias:curl }


# Setup Git for Powershell
#import-module oh-my-posh
#import-module posh-git

$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true
# set-theme agnoster

# =================================================================
# Make emacs launch on the command line in powershell
$emacs_wildcard = "${Env:ProgramFiles}\Emacs\*\bin\emacs.exe"
if ($(Test-Path $emacs_wildcard)) {
    $emacs_path = (Get-ChildItem $emacs_wildcard)[-1].FullName -replace ' ', '` '
      function emacs { "$emacs_path -nw $args" | Invoke-Expression }
}

# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    dotnet complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
# PowerShell parameter completion shim for the dotnet CLI
Register-ArgumentCompleter -Native -CommandName git -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    git complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName terraform -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    terraform complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

Register-ArgumentCompleter -Native -CommandName aws -ScriptBlock {
  param($commandName, $wordToComplete, $cursorPosition)
    aws complete --position $cursorPosition "$wordToComplete" | ForEach-Object {
      [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# ===========================================================
# Helper functions
# ===========================================================

function helpFunctions {
  Write-Output "Functions that you probably use often"
  Write-Host "
    -----------------------------
    helpAbby
    addTodoAbby
    -----------------------------
    helpFilevine
    addTodoFilevine
    -----------------------------
    GoGitWork (_gcw)
    GoGitPersonal (_gcp)
    -----------------------------
    set-sshkeys-filevine
    set-sshkeys-abby
    -----------------------------
    which
    rm-rf
    touch
    g (gvim)
    git_log_one_line
    clean-git
    now
    -----------------------------
    help_filevine_powershell_piping_commands
    getInstalledPackageGuid
    ultragrep
    tail
    docker_list
    docker_logs
    docker_start
    docker_stop
    git_fp
    Search-String
    Select-ColorString
    get_environment_variables
    set_google_api_key
    Set
    -----------------------------
    aws_configservice_describe_compliance_by_config_rule
    aws_configservice_compliance_details_by_config_rules
    aws_configservice_describe_aggregate_compliance_by_config_rules
    aws_configservice_describe_config_rules
    aws_configservice_remadiation_exceptions
    -----------------------------
    aws_sso_signin
    aws_sso_configure
    install_aws_cli
    aws_turn_off_cli_auto_prompt
    aws_turn_on_cli_auto_prompt
    aws_view_config_and_credentials
    aws_find_ec2_by_name
    aws_ssm_start_session
    -----------------------------
    # Installed yaml validator via npm
    yaml-validator random_file.yml
    yamllint random_file.yml
    -----------------------------
    To Reload Profile
    . `$PROFILE
  "
}

. ${HOME}/code/dotfiles_windows/powershell/functions/utility.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/abby.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/filevine.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/docker.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/aws.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/help.ps1
. ${HOME}/code/dotfiles_windows/powershell/functions/git.ps1



# z directory fun
import-module zlocation



if (test-path alias:set) { remove-item alias:set }


# ================================================================

. ${HOME}/code/dotfiles_windows/powershell/functions/starship.ps1
try { $null = gcm pshazz -ea stop; pshazz init 'default' } catch { }
