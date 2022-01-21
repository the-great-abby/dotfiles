# -----
# Cloudfront
task list_cloudfront {
  $_profile = "team_provider"
  #aws cloudfront list-distributions --query DistributionList.Items[*].Id --profile ${_profile}
  # E2603RK9S1RY75
  aws cloudfront list-distributions --query "DistributionList.Items[*].[Id,Comment,ARN,Status,Origins.Items[*].DomainName,Origins.Items[*].S3OriginConfig.OriginAccessIdentity,WebACLId]" --profile ${_profile}
}
task get_cloudfront_info {
  $_profile = "team_provider"
  #aws cloudfront list-distributions --query DistributionList.Items[*].Id --profile ${_profile}
  # E2603RK9S1RY75
  aws cloudfront list-distributions --query "DistributionList.Items[?Id=='E2603RK9S1RY75']" --profile ${_profile}
}

# ======================================================================================
# AWS Cloudwatch - Not Tested
# ======================================================================================
task aws_cloudwatch_list_metrics {
  #if ($ns == "not_available") {
    $namespace = "AWS/EC2"
  #} else {
  #  $namespace = $ns
  #}
  aws cloudwatch list-metrics --namespace ${namespace} --profile ${_profile}

}

# https://github.com/ravsau/AWS-CLI-Commands/blob/master/cloudwatch/cloudwatch-cli-useful-commands.MD
task aws_get_metric_statistics_query_avg_cpu {
  #aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time 2018-06-01T23:18:00Z --end-time 2018-06-19T23:18:00Z --period 3600 --namespace AWS/EC2 --statistics Average --dimensions Name=InstanceId,Value=i-07442b7dca24a5740
}
task aws_get_metric_statistics_query_max_cpu {
  # aws cloudwatch get-metric-statistics --metric-name CPUUtilization --start-time 2018-06-01T23:18:00Z --end-time 2018-06-19T23:18:00Z --period 3600 --namespace AWS/EC2 --statistics Maximum --dimensions Name=InstanceId,Value=i-07442b7dca24a5740
}

task aws_put_metric_alarm {
  # aws cloudwatch put-metric-alarm --alarm-name cpu-mon --alarm-description "Test Alarm when CPU exceeds 70 percent" --metric-name CPUUtilization --namespace AWS/EC2 --statistic Average --period 300 --threshold 70 --comparison-operator GreaterThanThreshold  --dimensions "Name=InstanceId,Value=<instance-id>" --evaluation-periods 2 --alarm-actions <sns-arn> --unit Percent
  #
}

task aws_cloudwatch_describe_alarms {
  # aws cloudwatch describe-alarms --alarm-names cpu-mon
}

task aws_cloudwatch_set_alarm_state {
  # aws cloudwatch set-alarm-state --alarm-name "cpu-mon" --state-value ALARM --state-reason "testing purposes"
  #
}

task aws_cloudwatch_describe_alarm_history {
  # aws cloudwatch describe-alarm-history --alarm-name "cpu-mon" --history-item-type StateUpdate
}

task aws_cloudwatch_delete_alarms {
  # aws cloudwatch delete-alarms --alarm-names cpu-mon
}

task aws_cloudwatch_metric_widget_image {
  # https://docs.aws.amazon.com/AmazonCloudWatch/latest/APIReference/CloudWatch-Metric-Widget-Structure.html
  # returns base64 encoded image (png)
  #aws cloudwatch get-metric-widget-image --metric-widget <value> --output-format png
}

task aws_cloudwatch_list_metric_streams {
  # aws cloudwatch list-metric-streams --profile ${_profile}
}

task aws_cloudwatch_get_metric_data {
  # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudwatch/get-metric-data.html
  # aws cloudwatchget-metric-data --metric-data-queries <value> --start-time <value> --end-time <value>
}

task aws_cloudwatch_get_metric_stream {
  # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cloudwatch/get-metric-stream.html
  # aws cloudwatch get-metric-stream --name <value> --profile ${_profile}
}

