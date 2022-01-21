
redis_instance:
	docker run --name some-redis -d redis

start_with_persistent_storage:
	docker run --name some-redis -d redis redis-server --save 60 1 --loglevel warning

connecting_via_redis_cli:
	docker run -it --network some-network --rm redis redis-cli -h some-redis

connecting_docker_run_with_custom_redis_conf:
	docker run -v /myredis/conf:/usr/local/etc/redis --name myredis redis redis-server /usr/local/etc/redis/redis.conf
