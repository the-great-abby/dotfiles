task aws_cloudformation_deploy_template {
  aws cloudformation deploy --template-file amplify/backend/hosting/S3AndCloudFront/template.json --stack-name test-abby-static-website --parameter-overrides file://local_dev/amplify/s3_and_cloudfront_parameters.json
}

task aws_cloudformation_describe_stack_events {
  aws cloudformation describe-stack-events --stack-name test-abby-static-website
}

task aws_cloudformation_remove_stack {
  aws cloudformation delete-stack --stack-name test-abby-static-website
}


