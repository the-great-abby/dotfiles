# =======================================================
# ======================================================================================
# AWS SNS
# ======================================================================================
task aws_sns_list_topics {
  # https://www.howtoforge.com/how-to-manage-aws-cloudwatch-using-aws-cli/
  aws sns list-topics --profile ${_profile}
}


