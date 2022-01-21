# ======================================================================================
# AWS ECR
# ======================================================================================
# =======================================================
# https://www.oneworldcoders.com/blog/using-terraform-to-provision-amazons-ecr-and-ecs-to-manage-containers-docker
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
task login_ecr {
#  $region = ""
#  $aws_account_id = ""
  aws ecr get-login-password --region ${region} --profile ${_profile} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com
  Write-Output "You should see 'Login Succeeded'"
}

