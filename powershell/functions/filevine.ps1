Write-Output "
============================
Filevine PS1 Functions Loaded
============================
"
function helpFilevine {
  Write-Output "Things you were working on last ..."
  # get-content "~/code/personal/abby-todo-list.md" | bat
  bat "${HOME}/code/filevine/todo-list.md"
}

function addTodoFilevine ($todo) {
  Add-Content -Path "~/code/filevine/todo-list.md" -Value "* ${todo}"
  bat "${HOME}/code/filevine/todo-list.md"
}

function set-sshkeys-filevine {
  copy ~/.ssh/id_rsa.filevine ~/.ssh/id_rsa -force
  copy ~/.ssh/id_rsa.pub.filevine ~/.ssh/id_rsa.pub -force
}

function GoGitWork { Set-Location -Path ~/code/work }
#function GoToFvaDashboardWork 
#
set-alias _gcw -value GoGitWork

function reload_functions_filevine {
  . ${HOME}/code/dotfiles/powershell/functions/filevine.ps1
  Write-Output ". `${HOME}/code/dotfiles/powershell/functions/filevine.ps1"
}

function help_filevine_tasks_dashboard {
  #Set-Location -Path ~/code/work/teams/fva/dashboard/iac/terraform
  Set-Location "${HOME}/code/work/teams/fva/dashboard"
}
function help_filevine_tasks_dashboard {
  #Set-Location -Path ~/code/work/teams/fva/dashboard/iac/terraform
  Set-Location "${HOME}/code/work/teams/fva/dms_lambda_iac"
}
set-alias _gcw_tasks_dashboard -value help_filevine_tasks_dashboard

function help_filevine_tasks_testFramework {
  Set-Location -Path ~/code/work/teams/fva/test_framework/iac
}
set-alias _gcw_tasks_tf -value help_filevine_tasks_testFramework

function help_filevine_tasks_filevine_terraform {
  Set-Location -Path ~/code/work/teams/filevine/filevine/iac/terraform
}
set-alias _gcw_tasks_fv -value help_filevine_tasks_filevine
