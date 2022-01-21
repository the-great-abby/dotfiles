# ======================================================================================
# Local - Redis ??
# ======================================================================================

task local_redis_instance {
  docker run --name some-redis -d redis
}

task local_redis_start_with_persistent_storage {
  docker run --name some-redis -d redis redis-server --save 60 1 --loglevel warning
}

task local_redis_connecting_via_redis_cli {
  docker run -it --network some-network --rm redis redis-cli -h some-redis
}
task local_connecting_docker_run_with_custom_redis_conf {
  https://gitlab.com/filevine/technology/project/filevine-platform/local_terraform_dev_scriptsdocker run -v /myredis/conf:/usr/local/etc/redis --name myredis redis redis-server /usr/local/etc/redis/redis.conf
}


