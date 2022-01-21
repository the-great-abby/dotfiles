# The purpose of this file is to allow you to build out your own personal directory of helpful files that
# that you can use to leave yourself and others helpful notes about code syntax and configuration.


 param(
   $name = "not_available",
   $profile = "not_available",
   $ns = "not_available", # namespace
   $target = "not_available",
   $dir = "not_available",
   $minutes = "not_available",
   $query_id = "not_available",
   $query = "not_available",
   $_profile = "team_provider",
   $SPACER = "==============================================================="
)

# ======================================================================================
# START HERE!
# run invoke-build init
# ======================================================================================
task init aws_init,
          db_init

task db_init setup_team_database_connection_info

task aws_init set_default_environment,
              login_aws_team


# ======================================================================================
# General Functions
# ======================================================================================
task setup_team_database_connection_info {
  Write-Output "Please make sure that you have a 'Makefile.creds.build.ps1'"
  invoke-build init -f Makefile.creds.build.ps1
}

task install_aws_helper {
  try {
    mv ${HOME}/.aws/config ${HOME}/.aws/config.bak
  } catch {
      Write-Output "Could not move ${HOME}/.aws/config"
  }
  cp aws/config ${HOME}/.aws/config
}

task install_terraform_helper_files {
  cp terraform/Makefile.build.ps1 ${dir}/Makefile.build.ps1
  cp terraform/local_test.tfvars ${dir}/local_test.tfvars
  cp terraform/provider.tf_local ${dir}/provider.tf_local
  cp terraform/provider_override.tf ${dir}/provider_override.tf
}

task install_octopus_deploy {
  # You should really download an updated provider exe ...
  cp terraform/terraform-provider-octopusdeploy_v0.5.0.exe ${dir}/terraform-provider-octopusdeploy_v0.5.0.exe
}

task install_other_helpers {
  # jq - https://stedolan.github.io/jq/tutorial/
  scoop install jq
  scoop install jid
  scoop install rg # Ripgrep
}


# ======================================================================================
# General Functions
# ======================================================================================


task set_default_environment {
  $env:AWS_DEFAULT_REGION = "us-west-2"
}

task login_aws_team {
  # This allows you to turn off the auto prompt non sense
  $env:aws_cli_auto_prompt = "off"
  $_profile = "team_provider"
  # Please select a proflie from your "`${HOME}/.aws/config"
  aws sso login --endpoint-url https://d-92671f41c2.awsapps.com/start#/ --profile $_profile

  # Don't forget to turn on the helpful auto prompt menu
  $env:aws_cli_auto_prompt = "on"
}

task test_json_jq_file {
  $json = Get-Content -Path "./outfile.json"
  #Write-Output $json
  #Write-Output $json | jq '.'
  # Write-Output $json | jq '.schema.fields'
}

# invoke-build get_timestamp_min_ago -minutes 5
task get_timestamp_min_ago {
  #Write-Output [int64]
  # Write-Output [int64](Get-Date -UFormat %s -Date (Get-Date).AddMinutes(-5))
  $timestamp = getTimestampMinutesAgo ($minutes)
  Write-Output $timestamp
}

task get_timestamp_now {
  $timestamp = getTimestampNow
  Write-Output  $timestamp
}

function getTimestampMinutesAgo ($minutes) {
  #Write-Output "Minutes: ${minutes}"
  return [int64](Get-Date -UFormat %s -Date (Get-Date).AddMinutes(-${minutes}))
  #return (Get-Date -UFormat %s -Date (Get-Date).AddMinutes(-${minutes}))
}

function getTimestampNow () {
  return [int64](Get-Date -UFormat %s)
  #return (Get-Date -UFormat %s)
}

# -------------------------------------------------------------------------------------
# View Markdown
# -------------------------------------------------------------------------------------
task view_markdown_editing_plan {
  # docker compose -f docker-compose-readme-viewer.yml exec markdown_editing grip /root/docs/PLAN.md 0.0.0.0:6419
  docker run --rm -v ${PWD}:/root/docs -p 6419:6419 -t -i fstab/grip grip /root/docs/PLAN.md 0.0.0.0:6419
}


# ======================================================================================
# Database
# ======================================================================================
# Assuming you have sqlcmd installed on your machine (you should if you have SSMS)
task db_run_query {
  # https://app.getguru.com/card/TEGLE45c/ZPA-Access-for-Devs-SREs-DBREs
  # <subdoman>.rds.<environment_name>.<domainname>
  # sqlcmd -S tcp:<SERVER> -U <username> -P <password> -Q <command line query> -o <outputFile> -d <DatabaseName>
  # sqlcmd -S tcp:<SERVER> -U <username> -P <password> -i <query_file> -o <outputFile> -d <DatabaseName>
  # Environment Variable: SQLCMDPASSWORD
  Get-Content -Path ${env:sql_server_cmd_input_file}
  sqlcmd -S tcp:${env:sql_server_db_host} -U ${env:sql_server_user} -d ${env:sql_server_db_name} -i ${env:sql_server_cmd_input_file} -o ${env:sql_server_cmd_output_file}
  Get-Content -Path ${env:sql_server_cmd_output_file}
}


# ======================================================================================
# Git
# ======================================================================================
task git_push {
  Write-Output @"
   # git push origin <BRANCH> -f # Force Push
   # git push origin <BRANCH>:<NEW_REMOTE_BRANCH> -f # Force Push
   # git push origin <BRANCH>
"@
}

# ======================================================================================
# Runbooks
# ======================================================================================

task rb_set_filevine_main_directory {
  $env:filevine_main_directory = "${HOME}/code/work/teams/main/filevine"
}

task rb_audit_get_constants {
  # This is specific for my directory
  Get-Content -Path "${env:filevine_main_directory}/Filevine.common/AuditLogType.cs"
}

task rb_db_run_sql_server_audit_desc {
  invoke-build -f ./filevine/audit/Makefile.build.ps1 desc_audit
}

task db_set_sql_server_cmd_input_file_audit_time_search {
  invoke-build -f ./filevine/audit/Makefile.build.ps1 search
}

