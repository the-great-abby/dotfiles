Write-Output "
============================
AWS PS1 Functions Loaded
============================
"

# AWS Helpers
# ================================================================
$Env:aws_cli_auto_prompt = "on"

$addAwsPath = "C:Program FilesAmazonAWSCLIV2"
$env:Path = $env:Path + ';' + $addAwsPath
# $Env:Path = Join-Path $env:Path $addAwsPath
function reload_functions_aws {
  . ${HOME}/code/dotfiles/powershell/functions/aws.ps1
  Write-Output "
  . `${HOME}/code/dotfiles/powershell/functions/aws.ps1
  "
}


function aws_configservice_describe_compliance_by_config_rule () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile,
      [Parameter(Mandatory=$true)] $_config_rule_name
  )
  aws configservice describe-compliance-by-config-rule --profile $_profile --config-rule-name $_config_rule_name
}

function aws_configservice_compliance_details_by_config_rules () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile,
      [Parameter(Mandatory=$true)] $_config_rule_name
  )
  aws configservice get-compliance-details-by-config-rule --profile $_profile --config-rule-name $_config_rule_name
}


function aws_configservice_describe_aggregate_compliance_by_config_rules () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile,
      [Parameter(Mandatory=$true)] $_config_rule_name
  )
  aws configservice describe-aggregate-compliance-by-config-rules --profile $_profile --config-rule-name $_config_rule_name
}

function aws_configservice_describe_config_rules () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile
  )
  aws configservice describe-config-rules --profile $_profile
}

function aws_configservice_remediation_exceptions () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile,
      [Parameter(Mandatory=$true)] $_config_rule_name
  )
  aws configservice describe-remediation-exceptions --config-rule-name $_config_rule_name --profile $_profile
}
function aws_sso_signin () {
  param
  (
      [Parameter(Mandatory=$true)] $_profile
  )
  aws sso login --endpoint-url https://d-92671f41c2.awsapps.com/start#/ --profile $_profile
}

function aws_sso_configure() {
  param
  (
      [Parameter(Mandatory=$true)] $_profile
  )
  aws configure sso --profile $_profile --endpoint-url https://d-92671f41c2.awsapps.com/start#/

}
function install_aws_cli {
  # https://docs.aws.amazon.com/cli/latest/userguide/awscli-install-windows.html
  # $dlurl = "https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi"
  # Some reason this did not work the way I had hoped ...
  $dlurl = "https://awscli.amazonaws.com/AWSCLIV2.msi"
  $installerPath = Join-Path $env:TEMP (Split-Path $dlurl -Leaf)
  Invoke-WebRequest $dlurl -OutFile $installerPath
  Start-Process -FilePath msiexec -Args "/i $installerPath /passive" -Verb RunAs -Wait
  Remove-Item $installerPath
}

function aws_turn_off_cli_auto_prompt {
  $Env:aws_cli_auto_prompt = "off"

}

function aws_turn_on_cli_auto_prompt {
  $Env:aws_cli_auto_prompt = "on"
}

function aws_view_config_and_credentials {
  bat $HOME/.aws/credentials
  bat $HOME/.aws/config
}

function aws_find_ec2_by_name () {
  param
  (
      [Parameter(Mandatory=$true)] $name,
      [Parameter(Mandatory=$true)] $_profile
  )
  aws_turn_off_cli_auto_prompt
  Write-Output "To Execute: aws_find_ec2_by_name -name team-fva -_profile fva"
  Write-Output "Profile $_profile"
  Write-Output "Name $name"
  Write-Output "Use sls or Select-String to see stuff in the listing"
  aws ec2 describe-instances --profile $_profile --filters "Name=tag:Name,Values=${name}*" --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].{Instance:InstanceId, AZ:Placement.AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value}" --no-cli-pager
  aws_turn_on_cli_auto_prompt
}

function aws_ssm_start_session () {
  param
  (
      [Parameter(Mandatory=$true)] $_target,
      [Parameter(Mandatory=$true)] $_profile
  )
  Write-Output "To Execute: aws_ssm_start_session -target INSTANCE_ID -_profile fva"
  turn_off_aws_cli_auto_prompt
  aws ssm start-session --profile $_profile --target $_target
  turn_on_aws_cli_auto_prompt
}
