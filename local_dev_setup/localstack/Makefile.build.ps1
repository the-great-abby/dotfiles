# -------------------------------------------------------------------------------------
# Local Dev Work
# -------------------------------------------------------------------------------------
# ----
# General
task set_endpoint_url {
  $env:end_point_url = "http://127.0.0.1:4566"
}

task initiate_localstack {
  Write-Output "initate localstack"
  docker-compose up localstack --build
}

task initiate_localdev {
  Write-Output "initate local dev"
  remove-item -force -recurse local_dev/iac/current-iac-data/
  mkdir local_dev/iac/current-iac-data/
  copy-item -recurse -force -Path ./iac/terraform/bad_setup/* -Destination local_dev/iac/current-iac-data
  Set-Location local_dev/iac/current-iac-data
  invoke-build save-octopus
  invoke-build set-localdev
  # cp local_provider.tfinfo local_dev/iac/current-iac-data/provider.tf -force
  invoke-build init
  invoke-build localdev_plan
  invoke-build localdev_apply
}
# -------------------------------------------------------------------------------------


