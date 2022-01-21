# ----
# S3
task get_s3_info {
  $env:aws_cli_auto_prompt = "off"
  $_profile = "team_provider"
  aws s3 ls --profile ${_profile}
}

# ======================================================================================
# AWS S3
# ======================================================================================
task aws_view_s3_file_output {
  #$bucket = "data-prod-us-dms-ksicoos3234"
  #$_profile = "main_provider"

  $key_path    = "audit_query/2021/11/15/18/1206110/17_query_result.json"
  $outfile      = "outfile.json"

 #  aws s3api get-object --bucket mybucket_name --key path/to/the/file.log --range bytes=0-10000 /dev/stdout | head
  aws s3api get-object --bucket ${bucket} --key ${key_path} --profile ${_profile} ${outfile}
}

task aws_s3_is_file_there {
  #$bucket      = "data-prod-us-dms-ksicoos3234"
  #$_profile    = "main_provider"

  $search_area = "audit_query"
  $search_area = "17_query_result.json"

  aws s3api list-objects --bucket ${bucket} --query "Contents[?contains(Key, '${search_area}')]" --profile ${_profile}
}

task test_aws_s3_ls {
  $env:aws_cli_auto_prompt = "off"
  aws s3 ls --profile ${_profile} 
  $env:aws_cli_auto_prompt = "on"
}

task test_aws_s3_sync {
  $env:aws_cli_auto_prompt = "off"
#  aws s3 sync archive/ --profile ${_profile} "s3://${env:s3_copy_test_bucket}"
  $env:aws_cli_auto_prompt = "on"
}

task set_s3_copy_folder {
  #$app_name                   = "s3-app"
  #$env_name                   = "team-fva-abby-local-test"
  # $dns_domain                 = "filevinedev.com"
  #$env:s3_copy_test_bucket = "app-${env_name}-${app_name}-${app_part}"
  #Write-Output "s3_copy_test_bucket: ${env:s3_copy_test_bucket}"
  # Write-Output "static web angular    : http://${env:s3_copy_test_bucket}.s3-website-us-west-2.amazonaws.com"
}

task remove_aws_s3_query_audit {
  $env:aws_cli_auto_prompt = "off"
  #aws s3 ls --profile team_provider
  #$glue_bucket = "data-fva-dms-scripts-dms-provider-updated"
  #$file_path   = "glue/query/query-expression-audit-research.py"
  #aws s3 rm s3://${glue_bucket}/${file_path} --profile ${_profile}
  $env:aws_cli_auto_prompt = "on"
}

task upload_new_s3_query_audit {
  $local_path         = "project_folder/src/query/query-expression-audit-research.py"
  $glue_bucket        = "s3://data-fva-dms-scripts-dms-provider-updated"
  $remote_file_path   = "glue/query/query-expression-audit-research.py"
  aws s3 cp ${local_path} ${glue_bucket}/${remote_file_path} --profile ${_profile}
}

task s3_search_result_output {
  $bucket = "data-prod-us-dms-ksicoos3234"
  $_profile = "main_provider"

  # $search_area = "audit_query"
  # $search_area = "17_query_result.json"
  $search_area = "2022"

 #  aws s3api get-object --bucket mybucket_name --key path/to/the/file.log --range bytes=0-10000 /dev/stdout | head
  aws s3api list-objects --bucket ${bucket} --query "Contents[?contains(Key, '${search_area}')]" --profile ${_profile}
}
