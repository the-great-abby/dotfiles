
# ======================================================================================
# AWS Elasticache - Redis
# ======================================================================================

task aws_elasticache_redis {
  # name: team-fva-shared-redis
  aws elasticache describe-replication-groups --query 'ReplicationGroups[*].NodeGroups[*].Address'  --profile ${_profile}
}


