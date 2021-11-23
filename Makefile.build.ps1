
task hello_world {
  Write-Output "Hello World"
}

task make_link_code_directory {

  $link = "${env:USERPROFILE}\code"
  # $source = "${PWD}\"
  $source = "${HOME}\Documents\code\"
  New-Item -Path $link -ItemType SymbolicLink -Target $source
}

task make_link_starship_toml {
  $link = "${env:USERPROFILE}\.starship.toml"
  $source = "${PWD}\starship/starship.toml"
  New-Item -Path $link -ItemType SymbolicLink -Target $source
}

task make_link_dotfiles_directory {

  $link = "${env:USERPROFILE}\code\dotfiles"
  # $source = "${PWD}\"
  $source = "${HOME}\Documents\code\personal\dotfiles"
  New-Item -Path $link -ItemType SymbolicLink -Target $source
}

task make_link_vimrc {

  # New-Item -Path $_link -ItemType SymbolicLink -Target $_source
  $link = "${env:USERPROFILE}\_vimrc"
  $source = "${PWD}\windows_shell\vimrc"
  New-Item -Path $link -ItemType SymbolicLink -Target $source
}

task replace_powershell_profile_with_symlink {
  Write-Output "Replace Powershell with Symlink"
  # New-Item -Path $_link -ItemType SymbolicLink -Target $_source
  $link = "${env:USERPROFILE}\Documents\WindowsPowerShell\Microsoft.PowerShell_Profile.ps1"
  $linkFolder = "${env:USERPROFILE}\Documents\WindowsPowerShell\"
  $source = "${PWD}\powershell\Microsoft.PowerShell_profile.ps1"
  #$cmd = "move-item -path '$source.orig' -destination '${source}'"
  #write-output $cmd
  #invoke-expression -command $cmd
  #$cmd = "move-item -path '$link' -destination '${link}.orig'"
  #write-output $cmd
  #invoke-expression -command $cmd
  #$cmd = "New-Item -Path '${linkFolder}' -ItemType Directory"
  #write-output $cmd
  #invoke-expression -command $cmd
  #$cmd = "New-Item -Path '$source' -ItemType SymbolicLink -Target '$link'"
  $cmd = "New-Item -Path '$link' -ItemType SymbolicLink -Target '$source'"
  write-output $cmd
  invoke-expression -command $cmd
}

task create_powershell_profile_directory {
  $linkFolder = "${env:USERPROFILE}\Documents\WindowsPowerShell\"
  write-output $cmd
  invoke-expression -command $cmd
  $cmd = "New-Item -Path '${linkFolder}' -ItemType Directory"

}

#task link_windows_zshrc {
#  # ln_s_directory -_link $
#  move-item ~/.zshrc ~/.zshrc.old
#New-Item -Path ~/.zshrc -ItemType SymbolicLink -Target ${PWD}/zsh/zshrc
#}

task todo {
  Write-Output "
* [ ] Type up Readme.md
* [ ] What commands do we need to run with scoop?
* [ ] Vim configuration/installation
* [ ] 
"
}

task set_endpoint_url {
  $env:end_point_url = "http://127.0.0.1:4566"
}

task initiate_localstack {
  Write-Output "initate localstack"
  docker-compose up localstack --build
}

task initiate_localdev {
  Write-Output "initate local dev"
  remove-item -force -recurse local_dev/iac/current-iac-data/
  mkdir local_dev/iac/current-iac-data/
  copy-item -recurse -force -Path ./iac/terraform/bad_setup/* -Destination local_dev/iac/current-iac-data
  cd local_dev/iac/current-iac-data
  invoke-build save-octopus
  invoke-build set-localdev
  # cp local_provider.tfinfo local_dev/iac/current-iac-data/provider.tf -force
  invoke-build init
  invoke-build localdev_plan
  invoke-build localdev_apply
}
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
  cd local_dev/iac/dynamodb
  terraform destroy -auto-approve
}

task terraform_build_dynamodb {

  invoke-build set_endpoint_url
  cd local_dev/setup_dynamodb
  terraform init
  terraform plan -out=testfile -input=false
  # terraform plan -var-file local_dev_test.tfvars -out=testfile -input=false
  terraform apply -input=false testfile
}
# -------------------------------------------------------------------------------------
# lambda commands
task create_lambda_json {
  cd local_dev/lambda_json/
  aws iam create-role --role-name lambda-ex --assume-role-policy-document file://iam-trust-policy.json --endpoint-url $env:end_point_url
  zip function.zip index.js
  aws lambda create-function --function-name my-function --zip-file fileb://function.zip --handler index.handler --runtime nodejs12.x --role arn:aws:iam:123456789012:role/lambda-ex --endpoint-url $env:end_point_url
}

task list_functions_json {
  aws lambda list-functions --max-items 10 --endpoint-url $env:end_point_url
  Write-Output "aws lambda list-functions --max-items 10 --starting-token "
}

task lambda_get_log_events {
  Write-Output "Look out for log stream id"
  aws logs get-log-events --log-group-name /aws/lambda/my-function --log-stream-name $(cat out) --limit 5 --endpoint_url $env:end_point_url
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


# ----
# IAM roles
task list_iam_roles {
  aws iam list-roles --endpoint-url $env:end_point_url
  # aws iam list-instance-profiles-for-role --role-name role-name --endpoint-url $env:end_point_url
  # aws iam remove-role-from-instance-profile --instance-profile-name instance-profile-name --role-name role-name --endpoint-url $env:end_point_url
  # aws iam list-role-policies --role-name role-name --endpoint-url $env:end_point_url
  # aws iam delete-role --role-name role-name --endpoint-url $env:end_point_url
}

# -------------------------------------------------------------------------------------
# graphql commands

#task initiate_graphql {
#  Write-Output "initate graphql"
#  docker-compose up graphql-engine --build
#  # Postgres automatically iniates
#}
#task initiate_postgres {
#  Write-Output "initate postgres"
#  docker-compose up postgres --build
#}

#task build_lambda {
#
#}

# -------------------------------------------------------------------------------------
# Apollo Server/graphql
#task apollo_setup_step1 {
#  cd ./local_dev/graphql-server-example
#  npm init --yes
#}
#
#task apollo_setup_step2 {
#
#  cd ./local_dev/graphql-server-example
#  node index.js
#}
task apollo_start {
  docker compose up apollo --build
}

# -------------------------------------------------------------------------------------
task docker_down {
  docker compose down
}

# -------------------------------------------------------------------------------------
# Test deploy process
# -------------------------------------------------------------------------------------
task view_markdown_editing_plan {
  # docker compose -f docker-compose-readme-viewer.yml exec markdown_editing grip /root/docs/PLAN.md 0.0.0.0:6419
  docker run --rm -v ${PWD}:/root/docs -p 6419:6419 -t -i fstab/grip grip /root/docs/PLAN.md 0.0.0.0:6419
}

task view_markdown_editing_readme {
  # docker compose -f docker-compose-readme-viewer.yml exec markdown_editing grip /bin/sh
  docker run --rm -v ${PWD}:/root/docs -p 6419:6419 -t -i fstab/grip grip /root/docs/README.md 0.0.0.0:6419
}

# This won't work for what I want to do at the moment
task test_deploy_process_containerize {
  docker compose -f docker-compose-test-deploy.yml up containerize --build
}

# This will require additional research if we wish to use that method
task run_kaniko_with_config {
  Write-Output "This does not work"
  # https://github.com/GoogleContainerTools/kaniko#running-kaniko-in-docker
  # Docker
  # ----------------------------------------------------------
  # docker run \
  #  -v "$HOME"/.config/gcloud:/root/.config/gcloud \
  #  -v /path/to/context:/workspace \
  #  gcr.io/kaniko-project/executor:latest \
  #  --dockerfile /workspace/Dockerfile \
  #  --destination "gcr.io/$PROJECT_ID/$IMAGE_NAME:$TAG" \
  #  --context dir:///workspace/
  #
  #  Amazon ECR
  # ----------------------------------------------------------
  #docker run -ti --rm -v `pwd`:/workspace -v `pwd`/config.json:/kaniko/.docker/config.json:ro gcr.io/kaniko-project/executor:latest --dockerfile=Dockerfile --destination=yourimagename
  # Update the credStore section in the config.json
  # { "credsStore": "ecr-login" }
  # you can mount int the new config as a configMap
  # kubectl create configmap docker-config --from-file=<path to config.json>
  # config instance role permissions
  #
}

# This won't work for now
task test_deploy_deep_dive_containerize {
  docker compose -f docker-compose-test-deploy.yml exec containerize /bin/sh
  # docker compose -f docker-compose-test-deploy.yml run containerize /bin/sh
}

# This won't work for now
task test_deploy_process_speedy_containerize {
  docker compose -f docker_compose_test_deploy.yml containerize up
}

task test_deploy_process_down {
  docker compose -f docker_compose_test_deploy.yml down
}

task test_deploy_process {
  docker compose -f docker-compose-test-deploy.yml up gitlab_test_node --build
}

task test_build_deploy_process {
  docker compose -f docker-compose-test-deploy.yml build gitlab_test_node
}

task cancel_test_deploy_process {
  docker compose -f docker-compose-test-deploy.yml down
}

task setup_local_docker_registry_server {
  docker run -d -p 5000:5000 --name docker_registry registry:2.7
  Write-Output "my.registry.address:port/repository"
  Write-Output "docker logs -f docker_registry"
  Write-Output "docker tag ubuntu localhost:5000/ubuntu"
  Write-Output "docker push localhost:5000/ubuntu"
}

task test_deploy_deep_dive {
  # docker compose -f docker-compose-test-deploy.yml exec gitlab_test_node /bin/sh
  # docker compose -f docker-compose-test-deploy.yml run gitlab_test_node /bin/bash
  Write-Output "
    docker run ``
       --env-file ./local_dev/gitlab_test_node/_aws_envfile ``
       --env-file ./local_dev/gitlab_test_node/_envfile ``
       --volume `${PWD}:/code ``
       -it dashboard_local_dev_gitlab_test_node ``
       /bin/bash

    - make set_credentials
    # - make init_gitlab_amplify
    - amplify env checkout ${AMPLIFY_ENVIRONMENT}
    - amplify status
    - amplify publish
    # - amplify push --yes

    - docker ps
    - invoke-build docker_prune
    - invoke-build test_build_deploy_process
    - invoke-build test_deploy_deep_dive

    - amplify/.config/local-aws-info.json
  "
  docker run `
     --env-file ./local_dev/gitlab_test_node/_aws_envfile `
     --env-file ./local_dev/gitlab_test_node/_envfile `
     --volume ${PWD}:/code `
     -it dashboard_local_dev_gitlab_test_node `
     /bin/bash
}

task test_manual_build_deploy {
  # docker context create --from . my_deploy_context
  # docker build ./local_dev/gitlab_test_node/Dockerfile -t gitlab_test_node
}

task test_deploy_process_speedy {
  docker compose -f docker_compose_test_deploy.yml gitlab_test_node up
}

task test_reset_docker {
  docker volume prune -f
  docker container prune -f
}

task docker_prune {
  docker volume prune -f
  docker container prune -f
  docker image prune -f
  docker network prune -f
}

task login_aws_team {
  $env:aws_cli_auto_prompt = "off"
  $_profile = "team_provider"
  aws sso login --endpoint-url https://d-92671f41c2.awsapps.com/start#/ --profile $_profile
  $env:aws_cli_auto_prompt = "on"
}

task how_do_we_deploy_test {
  Write-Output "
  Update local_dev/gitlab_test_node/_envfile
  with environment info for admin access from
  test_deploy_process
  "
}

task push_abby {
  git add .\.gitlab-ci.yml
  git add .\.amplify-headless-init.sh
  git add .\Makefile.build.ps1
  git add .\PLAN.md
  git add .\docker-compose-readme-viewer.yml
  git add .\docker-compose-test-deploy.yml
  git commit -m 'hello amplify #13 - test-yarn-deploy gitlab-yml fixes'
  git push origin feature/deploy_amplify
}

task set_environment {
  $env:AMPLIFY_ENVIRONMENT = "localabby"
}

task amplify_plugin_scan {
  amplify plugin scan
}

task amplify_manual_add_environment {
  # Get AWS Info from the Console screen
  # May be able to run this through gitlab through it's user
  # Paste the info into the console .aws/config screen
  # (Update the last 4 lines)
  # amplify will ask you for which way to access the keys
  amplify env add team_production --permissions-boundary arn:aws:iam::926927448710:policy/test_iam_policy_for_amplify
}

task amplify_plugin_add_vim {
  Write-Output "This doesn't work yet"
}

task amplify_plugin_add_vscode {
  Write-Output "This doesn't work yet"
}

task amplify_plugin_help {
  amplify plugin help
}

task amplify_add_environment {
  Write-Output "Starts CLI Menu session to answer questions"
  Write-Output "Select 'No' if you wish to add a new environment"
  Write-Output "Select Visual Studio Code"
  amplify env add  --permissions-boundary ${PERMISSION_BOUNDARY}
  Write-Output "* [TODO] Add plugin for vim - not necessary - none is an option"
  Write-Output "* [TODO] Add plugin for visual studio - not necessary - none is an option"
  Write-Output "https://github.com/aws-amplify/amplify-cli/issues/2746"
  Write-Output "remove global yarn directory, reinstall amplify CLI using yarn"
  amplify env add
}

task gitlab_pipeline_ci_view {
  glab pipeline ci view
}

task install_glab {
  scoop install glab
}

task update_glab {
  scoop update glab
}
