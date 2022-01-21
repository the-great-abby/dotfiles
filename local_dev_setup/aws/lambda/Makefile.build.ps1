# -------------------------------------------------------------------------------------
# lambda commands
task create_lambda_json {
  #Set-Location local_dev/lambda_json/
  #aws iam create-role --role-name lambda-ex --assume-role-policy-document file://iam-trust-policy.json --endpoint-url $env:end_point_url
  #zip function.zip index.js
  #aws lambda create-function --function-name my-function --zip-file fileb://function.zip --handler index.handler --runtime nodejs12.x --role arn:aws:iam:123456789012:role/lambda-ex --endpoint-url $env:end_point_url
}

task list_functions_json {
  aws lambda list-functions --max-items 10 --endpoint-url $env:end_point_url
  Write-Output "aws lambda list-functions --max-items 10 --starting-token "
}

task lambda_get_log_events {
  Write-Output "Look out for log stream id"
  aws logs get-log-events --log-group-name /aws/lambda/my-function --log-stream-name $(Get-Content out) --limit 5 --endpoint_url $env:end_point_url
}

task lambda_invoke_function {
  aws lambda invoke --function-name my-function out --log-type Tail --endpoint-url $env:end_point_url #\
  # --query 'LogResult' --output text |  base64 -d
}

task lambda_get_function {
  aws lambda get-function --function-name my-function --endpoint-url $env:end_point_url
}

task lambda_cleanup {
  aws lambda delete-function --function-name my-function --endpoint-url $env:end_point_url
}

task lambda_docker {
  # https://docs.aws.amazon.com/lambda/latest/dg/lambda-images.html
  # https://docs.aws.amazon.com/lambda/latest/dg/images-create.html
  # https://docs.aws.amazon.com/lambda/latest/dg/images-test.html
}
