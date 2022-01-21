task amplify_plugin_scan {
  amplify plugin scan
}

task amplify_manual_add_environment {
  # Get AWS Info from the Console screen
  # May be able to run this through gitlab through it's user
  # Paste the info into the console .aws/config screen
  # (Update the last 4 lines)
  # amplify will ask you for which way to access the keys
  #amplify env add team_production --permissions-boundary arn:aws:iam::926927448710:policy/test_iam_policy_for_amplify
  $test = "amplify env add ${env:AMPLIFY_ENVIRONMENT} --permissions-boundary arn:aws:iam::926927448710:policy/test_iam_policy_for_amplify"
  write-output $test
  invoke-expression $test
}

task amplify_manual_init {
  $USER_POOL_ID = "us-west-2_5GHFkfRhR"
  $USER_POOL_NAME = "team-fva-tenant-b79c7eaf-b4ba-4140-8b26-ac1000f2094c"
  $WEB_CLIENT_ID = "5nec3rmm05ucj1hs1jbm0j9i6g"
  $NATIVE_CLIENT_ID = "5nec3rmm05ucj1hs1jbm0j9i6g"
  $AUTHCONFIG = @"
{ "userPoolId": "${USER_POOL_ID}", "userPoolName": "${USER_POOL_NAME}", "webClientId": "${WEB_CLIENT_ID}", "nativeClientId": "${NATIVE_CLIENT_ID}" }
"@
  $CATEGORIES = @"
{ "auth": $AUTHCONFIG }
"@
  $CODEGEN = @"
 { "generateCode":false, "generateDocs":false }
"@
  $CODEGEN = $CODEGEN.trim()
  $CATEGORIES = $CATEGORIES.trim()
  $AUTHCONFIG = $AUTHCONFIG.trim()

  $AMPLIFY_APP_ID = "d1wg6h9552y3u2"
  # $AMPLIFY_ENVIRONMENT = "stage" #"abby_local_test1"
  $AMPLIFY_ENVIRONMENT = $env:AMPLIFY_ENVIRONMENT #"abby_local_test1"
  $AMPLIFY = @"
  { "envName":"${AMPLIFY_ENVIRONMENT}",   "appId":"${AMPLIFY_APP_ID}" }
"@
  $PROJECT_FRONTEND_NAME = "dashboard"
  $PROJECT_NAME = "dashboard"
  $JAVASCRIPT_CONFIG = @"
  { "SourceDir": "src","DistributionDir": "public","BuildCommand": "yarn build","StartCommand": "yarn start" }
"@
  $JAVASCRIPT_CONFIG = $JAVASCRIPT_CONFIG.trim()
  $FRONTEND = @"
  { "frontend": "${PROJECT_FRONTEND_NAME}", "framework":"none","config": ${JAVASCRIPT_CONFIG} }
"@
  #$AWSCLOUDFORMATION = @"
  #{ "configLevel":"project", "useProfile":"true", "profileName":"amplify",   "appId":"${AMPLIFY_APP_ID}"}
  #"@
  $AWSCLOUDFORMATION = @"
  { "configLevel":"project", "useProfile":"true", "profileName":"team_provider",   "appId":"${AMPLIFY_APP_ID}"}
"@
  $PROVIDERS = @"
  { "awscloudformation": ${AWSCLOUDFORMATION} }
"@
  $AMPLIFY = $AMPLIFY.trim()
  $FRONTEND = $FRONTEND.trim()
  $PROVIDERS = $PROVIDERS.trim()
  $AWSCLOUDFORMATION = $AWSCLOUDFORMATION.trim()
  $FRONTEND = $FRONTEND.trim()
  $PROVIDERS = $PROVIDERS.trim()

  $test = @"
  amplify init --amplify '${AMPLIFY}' --frontend '${FRONTEND}' --providers '${PROVIDERS}' --codegen '${CODEGEN}' --categories '${CATEGORIES}' --yes
"@
  write-output "AMPLIFY    = '${AMPLIFY}'"
  write-output "FRONTEND   = '${FRONTEND}'"
  write-output "PROVIDERS  = '${PROVIDERS}'"
  write-output "CODEGEN    = '${CODEGEN}'"
  write-output "CATEGORIES = '${CATEGORIES}'"
  write-output $test
  invoke-expression $test
}
task amplify_add_environment {
  Write-Output "Starts CLI Menu session to answer questions"
  Write-Output "Select 'No' if you wish to add a new environment"
  Write-Output "Select Visual Studio Code"
  amplify env add ${environment_name} --permissions-boundary ${PERMISSION_BOUNDARY}
  Write-Output "* [TODO] Add plugin for vim - not necessary - none is an option"
  Write-Output "* [TODO] Add plugin for visual studio - not necessary - none is an option"
  Write-Output "https://github.com/aws-amplify/amplify-cli/issues/2746"
  Write-Output "remove global yarn directory, reinstall amplify CLI using yarn"
  # amplify env add
}


task aws_amplify_list_backend_environments {
  $_profile = "team_provider"
  $appid = "d1wg6h9552y3u2";
  $CMD = "aws amplify list-backend-environments --profile ${_profile} --app-id ${appid}"
  write-output $CMD
  Invoke-Expression $CMD
  # write-output sls environmentName
}

task aws_amplify_add_backend_environment {
  $_profile = "team_provider"
  $appid = "d1wg6h9552y3u2";
  $CI_COMMIT_SLUG = "abby-local-test"
  $randomNum = Get-Random -Maximum 100000 -Minimum 10000
  $stackName = "amplify-dashboard-${CI_COMMIT_SLUG}-${randomNum}";
  $deployArt = "${stackName}-deployment";
  $cbe = @"
{
    "appId": "${appid}",
    "environmentName": "${newEnv}",
    "stackName": "${stackName}",
    "deploymentArtifacts": "${deployArt}"
}
"@
  $CMD = "aws amplify create-backend-environment --profile ${_profile} --app-id ${appid} --cli-input-json "
  write-output $CMD $cbe
  Invoke-Expression $CMD $cbe
}


