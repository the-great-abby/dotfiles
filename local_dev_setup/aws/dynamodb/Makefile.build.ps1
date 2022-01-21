# -------------------------------------------------------------------------------------
# aws commands
# Dynamo DB
task list_dynamodb_tables {
  aws dynamodb list-tables --endpoint-url $env:end_point_url
}

task create_dynamodb_table {
  Write-Output "create dynamodb table"
  aws dynamodb create-table --cli-input-json file://local_dev/dynamodb_json/create_dynamodb1.json --endpoint-url $env:end_point_url
}

task populate_dynamodb {
  Write-Output "populate dynamodb"
  aws dynamodb list-tables --endpoint-url $env:end_point_url
}

task dynamodb_wizard {
  aws dynamodb wizard new-table --endpoint-url $env:end_point_url
  # https://dynobase.dev/dynamodb-cli-query-examples/
}

task dynamodb_get_item {
  aws dynamodb get-item \ --table-name NameOfTheTable \ --key '{"id": {"S": "123"}, "email": {"S": "john@doe.com"}}' --endpoint-url $env:end_point_url --consistent-read # This is optional

}

task dynamodb_put_item {
  aws dynamodb put-item  --table-name NameOfTheTable  --item '{"id":"123"}' --endpoint-url $env:end_point_url
}

task dynamodb_describe {
  aws dynamodb describe-table --table-name $dynamodb_table_name --endpoint-url $env:end_point_url
}

task dynamodb_cleanup {
  Set-Location local_dev/iac/dynamodb
  terraform destroy -auto-approve
}

task terraform_build_dynamodb {

  invoke-build set_endpoint_url
  Set-Location local_dev/setup_dynamodb
  terraform init
  terraform plan -out=testfile -input=false
  # terraform plan -var-file local_dev_test.tfvars -out=testfile -input=false
  terraform apply -input=false testfile
}

