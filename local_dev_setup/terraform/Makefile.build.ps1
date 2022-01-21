task login_aws_team {
  $env:aws_cli_auto_prompt = "off"
  $_profile = "team_provider"
  aws sso login --endpoint-url https://d-92671f41c2.awsapps.com/start#/ --profile $_profile
  $env:aws_cli_auto_prompt = "on"
}

task init {
    terraform init
}

task validate {
    terraform validate
}

task plan {
    terraform plan -var-file local_test.tfvars -out=testfile -input=false
}

task plan_debug {
    $env:TF_LOG="DEBUG"
    # $env:TF_LOG="TRACE"
    $env:TF_LOG_PATH="./terraform_debug.txt"
    terraform plan -var-file local_test.tfvars -out=testfile -input=false
    $env:TF_LOG=""
}

task apply {
    terraform apply -input=false testfile
}


task destroy_environment {
  terraform destroy -var-file local_test.tfvars -input=false
}

task destroy destroy_environment

task reset_environment destroy_environment,parent-test,apply

task set-local {
  Copy-Item provider.tf_local provider.tf
}

task set-octopus {
  Copy-Item provider.tf_octopus provider.tf
}

task save-octopus {
  Copy-Item provider.tf provider.tf_octopus
}

task save-local {
  Copy-Item provider.tf provider.tf_local
}

task show {
    terraform show
}

task clean {
  try {
    remove-item .terraform -recurse -force
  } catch {
      Write-Output "Could not remove .terraform"
  }
  try {
    remove-item .terraform.lock.hcl
  } catch {
      Write-Output "Could not remove .terraform.lock.hcl"
  }
  try {
    remove-item terraform.tfstate
  } catch {
      Write-Output "Could not remove terraform.tfstate"
  }
  try {
    remove-item terraform.tfstate.backup
  } catch {
      Write-Output "Could not remove terraform.tfstate"
  }
}

task git_rebase {
  git fetch
  git rebase origin/master
}


task todo {

  Write-Output "
==============================================
TODO List
==============================================
==============================================
"
}

# =======================================================
# https://www.oneworldcoders.com/blog/using-terraform-to-provision-amazons-ecr-and-ecs-to-manage-containers-docker
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository
task login_ecr {
#  $region = ""
#  $aws_account_id = ""
  aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${aws_account_id}.dkr.ecr.${region}.amazonaws.com
  Write-Output "You should see 'Login Succeeded'"
}

task check_docker_images {
  docker images
}

task tag_docker_image {
  docker tag ${image_id} ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${repository-name}:${image_tag}
}

task push_docker_image {
  docker push ${aws_account_id}.dkr.ecr.${region}.amazonaws.com/${repository-name}
}
# =======================================================

task git_push {
   git push origin feature/add-team-deploy -f
}

