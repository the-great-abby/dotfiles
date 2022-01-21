# Execute: invoke-build init -f Makefile.creds.build.ps1
#
# Assuming you have sqlcmd installed on your machine (you should if you have SSMS)
task init {
  $env:sql_server_db_host          = "frickn-apples.rds.dev.filevinedev.com"
  $env:sql_server_db_name          = "Filevine"
  # $env:sql_server_porta          = ""
  $env:sql_server_user             = "fvdbadmin"
  $env:sql_server_password         = "AMXOepDUIQU0`$a4!&46F!O6W%uk558cysVNYzgyWRXxqkJInbSbI"

  # --------------------------------------------------
  # You should not need to edit beyond this line
  # --------------------------------------------------
  $env:sql_server_cmd_input_file  = "./sql_server_cmd_input.sql"
  $env:sql_server_cmd_output_file = "./sql_server_cmd_output.out"
  $env:SQLCMDPASSWORD             = $env:sql_server_password
  Set-Content -Path "./sql_server_cmd_output.out" -Value ""
}



