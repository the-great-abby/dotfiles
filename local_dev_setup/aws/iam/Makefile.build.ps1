# ----
# IAM roles
task list_iam_roles {
  aws iam list-roles --endpoint-url $env:end_point_url
  # aws iam list-instance-profiles-for-role --role-name role-name --endpoint-url $env:end_point_url
  # aws iam remove-role-from-instance-profile --instance-profile-name instance-profile-name --role-name role-name --endpoint-url $env:end_point_url
  # aws iam list-role-policies --role-name role-name --endpoint-url $env:end_point_url
  # aws iam delete-role --role-name role-name --endpoint-url $env:end_point_url
}

