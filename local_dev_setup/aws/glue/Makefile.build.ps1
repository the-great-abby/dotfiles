# ======================================================================================
# AWS Glue
# ======================================================================================

# invoke-build glue_query_stop -jobid ${JOB_RUN_ID}
task glue_query_stop {
  #$_profile = "main_provider"
  #$SMALL_JOB_NAME = "prod-us-dms_member_job-query_expression_audit_research"
  $JOB_RUN_ID = $jobid
  $json_input = @"
{
  "RunId": "${JOB_RUN_ID}",
  "JobName": "${SMALL_JOB_NAME}"
}
"@
  set-content -path test.json -value ${json_input}
  $CMD = "aws glue batch-stop-job-run  --job-name ${SMALL_JOB_NAME} --profile ${_profile} --job-run-id ${JOB_RUN_ID} "
  write-output $SPACER
  write-output "CMD: $CMD"
  write-output $SPACER
  invoke-expression $CMD
}

# invoke-build glue_query_run_status -jobid ${JOB_RUN_ID}
task glue_query_run_status {
  # $_profile = "main_provider"
  # $SMALL_JOB_NAME = "prod-us-dms_member_job-query_expression_audit_research"

  $JOB_RUN_ID = ${jobid}
  $CMD = "aws glue get-job-run --job-name ${SMALL_JOB_NAME} --profile ${_profile} --run-id ${JOB_RUN_ID} "
  write-output $SPACER
  write-output "CMD: $CMD"
  write-output $SPACER
  invoke-expression $CMD
}

# invoke-build glue_query
# This is semi complete info ..
task glue_query {
  write-output "hello"
  Write-output "aws glue start-job-run --job-name team-fva-dms_member_job-query_expression"
  write-output "Default Job Parameters: --hour -1 --year 2021 --predicate UserID>0 --month 5 --search_bucket team-fva-audit-stream "
    " --select_fields UserID --result_bucket data-fva-zax9wk --format csv --day 2 --JOB_NAME cliff_audit_research"
  Write-output "aws glue get-job-run --job-name --job-id"
  $SMALL_JOB_NAME = "team-fva-dms_member_job-query_expression_audit_research"
  $BIG_JOB_NAME = "audit_query"

  $json_input = @"
{
  "JobName": "${SMALL_JOB_NAME}",
  "Arguments": {
      "--JOB_NAME": "${BIG_JOB_NAME}"
  }
}
"@
  write-output $json_input

  set-content -path test.json -value ${json_input}
  $CMD = "aws glue start-job-run --job-name ${SMALL_JOB_NAME} --profile ${_profile} --cli-input-json file://test.json"
  write-output $SPACER
  write-output "CMD: $CMD"
  write-output $SPACER
  invoke-expression $CMD
}


