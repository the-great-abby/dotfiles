task docker_build {
  docker compose -f docker-compose-test-deploy.yml `
		build gitlab_test_node
  # docker build -f ./local_dev/gitlab_test_node/Dockerfile -t gitlab_test_node
}

task docker_down {
  docker compose -f docker-compose-test-deploy.yml down
}

task docker_prune {
  docker volume prune -f
  docker container prune -f
  docker image prune -f
  docker network prune -f
}

task docker_deep_dive {
  docker run --env-file ./local_dev/docker_node/_envfile `
		--env-file ./local_dev/docker_node/_aws_envfile `
		--volume ${PWD}:/code `
		-it docker_node `
		/bin/bash
}
