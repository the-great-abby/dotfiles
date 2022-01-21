# ======================================================================================
# AWS Logs
# ======================================================================================

task aws_logs {
  $out = @"
  # aws logs tail LOG_GROUP --follow --profile
  # aws logs tail "/aws-glue/jobs/output" --follow --profile ${_profile}
  #  --filter-pattern "${jobid}"
"@
  Write-Output $out
}

# invoke-build aws_insights_create_json_file -minutes 5
task aws_insights_create_json_file {
  $timestampMinutesAgo = getTimestampMinutesAgo($minutes)
  $timestampNow = getTimestampNow
  Write-Output @"
  Step 0a: 'invoke-build aws_insights_create_json_file -minutes 5 # 5 minutes ago'
  Step 0b: 'invoke-build aws_insights_create_json_file -minutes 30 # 30 minutes ago'
  Step 1: Please update the insights.json file
  Step 2: Add logGroupNames to use in search query
  Some Suggested logGroupNames are:
  (please feel free to add more)
  * {EnvName}/Filevine.WindowsService.AutoReportsService/Debug
  * {EnvName}/Filevine/Default
  * {EnvName}/FilevineSite/Debug
  * {EnvName}/FilevineSite/Error
  Note: This is helpful when leaving suggestions for others to search related logs
  Step 3: Please update the queryString to the appropriate value to search
  Step 4: run 'invoke-build aws_insights_start_query'
  * You should have recieved a query id value
  Step 5: run 'invoke-build aws_insights_get_query_results -Query_id `${query_id}'
"@
$json = @"
{
    "logGroupName": "",
    "logGroupNames": [
        ""
    ],
    "startTime": ${timestampMinutesAgo},
    "endTime": ${timestampNow},
    "queryString": "${query}",
    "limit": 0
}
"@
  Set-Content -Value $json -Path "./insights.json"
}

task aws_insights_start_query {
  aws logs start-query --cli-input-json ./insights.json
}

task aws_insights_get_query_results {
  aws logs get-query-results --query-id ${query_id}
}

task aws_insights_describe_queries {
  aws logs describe-queries --profile ${_profile}
}


