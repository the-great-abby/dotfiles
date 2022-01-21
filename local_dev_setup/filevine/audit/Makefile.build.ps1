task desc_audit {
  $env:sql_server_cmd_input_file = "./desc_audit.sql"
  invoke-build run_query
}
task search {
  $env:sql_server_cmd_input_file = "./time_search.sql"
  invoke-build run_query
}

task get_constants {
  Get-Content -Path "${HOME}/code/work/teams/main/filevine/Filevine.common/AuditLogType.cs"
}

# Assuming you have sqlcmd installed on your machine (you should if you have SSMS)
task run_query {
  # https://app.getguru.com/card/TEGLE45c/ZPA-Access-for-Devs-SREs-DBREs
  # <subdoman>.rds.<environment_name>.<domainname>
  # sqlcmd -S tcp:<SERVER> -U <username> -P <password> -Q <command line query> -o <outputFile> -d <DatabaseName>
  # sqlcmd -S tcp:<SERVER> -U <username> -P <password> -i <query_file> -o <outputFile> -d <DatabaseName>
  # Environment Variable: SQLCMDPASSWORD
  Get-Content -Path ${env:sql_server_cmd_input_file}
  sqlcmd -S tcp:${env:sql_server_db_host} -U ${env:sql_server_user} -d ${env:sql_server_db_name} -i ${env:sql_server_cmd_input_file} -o ${env:sql_server_cmd_output_file}
  Get-Content -Path ${env:sql_server_cmd_output_file}
}

