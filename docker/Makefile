docker_build:
	docker compose -f docker-compose-test-deploy.yml build gitlab_test_node
	# docker build -f ./local_dev/gitlab_test_node/Dockerfile -t gitlab_test_node

docker_run:
	docker run \
		--env-file ./local_dev/docker_node/_aws_envfile \
		--env-file ./local_dev/docker_node/_envfile \
		--volume ${PWD}:/code \
		-it dashboard_local_dev_docker_node \
		/bin/bash

docker_prune:
	docker volume prune -f
	docker container prune -f
	docker image prune -f
	docker network prune -f

docker_list:
	docker ps -s
	docker container ls -s

docker_local_image_repository:
	echo "Setup the local image repository"
