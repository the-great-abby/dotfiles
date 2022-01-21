# ======================================================================================
# Docker
# ======================================================================================
task lazydocker {
  lazydocker
}
task install_lazydocker {
  scoop install lazydocker
}


task docker_prune {
  Write-Output "Prune Containers and Images"
  docker containers prune
  docker images prune
}

task docker_volume_prune {
  Write-Output "Prune Volumes"
  docker volumes prune
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

# -------------------------------------------------------------------------------------
task docker_down {
  docker compose down
}

# Setting up local Docker Registry Server
task setup_local_docker_registry_server {
  docker run -d -p 5000:5000 --name docker_registry registry:2.7
  Write-Output "my.registry.address:port/repository"
  Write-Output "--------------------------------------------------"
  Write-Output "docker logs -f docker_registry"
  Write-Output "docker tag ubuntu localhost:5000/ubuntu"
  Write-Output "docker push localhost:5000/ubuntu"
  Write-Output "--------------------------------------------------"
  Write-Output "Update your docker config to use this repository"
  Write-Output "as a caching configuration"
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

task test_deploy_deep_dive {
  # docker compose -f docker-compose-test-deploy.yml exec gitlab_test_node /bin/sh
  # docker compose -f docker-compose-test-deploy.yml run gitlab_test_node /bin/bash
  cat ./gitlab_test_node/help.txt
  docker run `
    --env-file ./gitlab_test_node/_aws_envfile `
    --env-file ./gitlab_test_node/_envfile `
    --volume ${PWD}:/code `
    --volume ${PWD}/_aws:/home/user/.aws `
    -it dashboard_gitlab_test_node `
    /bin/bash
}

task custom_docker_lambda_build {
  docker build -t hello-world  -f custom.Dockerfile .
}
task test_custom_docker_lambda_build {
  # docker build -t hello-world  -f custom.Dockerfile .
  # aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789012.dkr.ecr.us-east-1.amazonaws.com
  # aws ecr create-repository --repository-name hello-world --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE
  # docker tag  hello-world:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
  # docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest
  # curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'
  # https://aws.amazon.com/blogs/aws/new-for-aws-lambda-container-image-support/
}
