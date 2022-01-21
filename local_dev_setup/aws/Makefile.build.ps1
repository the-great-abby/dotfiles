# ----
# AWS General

task set_aws_cli_auto_prompt_off {
  $env:aws_cli_auto_prompt = "off"
}

task set_aws_cli_auto_prompt_on {
  $env:aws_cli_auto_prompt = "on"
}


