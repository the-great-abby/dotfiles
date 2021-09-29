docker_build:
	docker compose -f docker-compose-test-deploy.yml build gitlab_test_node
	docker build -f ./local_dev/gitlab_test_node/Dockerfile -t gitlab_test_node

docker_run:
	docker run \
		--env-file ./local_dev/gitlab_test_node/_aws_envfile \
		--env-file ./local_dev/gitlab_test_node/_envfile \
		--volume ${PWD}:/code \
		-it dashboard_local_dev_gitlab_test_node /bin/bash

docker_run_terraform_rover:
	docker run --rm -it -p 9000:9000 -v $(pwd):/src im2nguyen/rover
	#$ docker run --rm -it -p 9000:9000 -v $(pwd):/src im2nguyen/rover -tfVarsFile test.tfvars -tfVar max_length=4
	# This runs rover on localhost:9000 and then from there we are
	# able to see visualization
