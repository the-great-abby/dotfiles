 param(
   $dir = "not_available"
)
task install_helper_files {
  cp Makefile.build.ps1_terraform ${dir}/Makefile.build.ps1
  cp local_test.tfvars ${dir}/local_test.tfvars
  cp provider.tf_local ${dir}/provider.tf_local
}
task install_octopus_deploy {
  cp terraform-provider-octopusdeploy_v0.5.0.exe ${dir}/terraform-provider-octopusdeploy_v0.5.0.exe
}
