# ======================================================================================
# AWS EC2
# ======================================================================================
task aws_find_ec2_by_name {
  # $name
  # $_profile
  Write-Output "To Execute: invoke-build aws_find_ec2_by_name -name team-fva -_profile fva"
  Write-Output "Profile $_profile"
  Write-Output "Name $name"
  Write-Output "Use sls or Select-String to see stuff in the listing"
  $env:aws_cli_auto_prompt = "off"
  aws ec2 describe-instances --profile ${_profile} --filters "Name=tag:Name,Values=${name}*" --filters "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].{Instance:InstanceId, AZ:Placement.AvailabilityZone, Name:Tags[?Key=='Name']|[0].Value}" --no-cli-pager
  $env:aws_cli_auto_prompt = "on"
}

# ======================================================================================
# AWS SSM - Secure Session Manager - EC2
# ======================================================================================
task aws_ssm_start_session {
  # $target
  # $_profile
  Write-Output "To Execute: invoke-build aws_ssm_start_session -target INSTANCE_ID -_profile ${_profile}"
  $env:aws_cli_auto_prompt = "off"
  aws ssm start-session --profile ${_profile} --target ${_target}
  $env:aws_cli_auto_prompt = "on"
}

