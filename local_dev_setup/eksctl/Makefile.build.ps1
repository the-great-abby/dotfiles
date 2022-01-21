# https://eksctl.io/introduction/
task list_cluster {
  # eksctl get cluster [--name=<name>][--region=<region>]
}

task create_cluster {
  # eksctl create cluster --config-file=<path>
}

task get_cluster_credentials {
  # eksctl utils write-kubeconfig --cluster=<name> [--kubeconfig=<path>][--set-kubeconfig-context=<bool>]
}

task enable_credential_cache {
  # export EKSCTL_ENABLE_CREDENTIAL_CACHE=1
}

task autoscaling {
  eksctl create cluster --name=cluster-5 --nodes-min=3 --nodes-max=5
}

task ssh_access {
  #eksctl create cluster --ssh-access --ssh-public-key=my_eks_node_id.pub
}
task ssm_access {
  # eksctl create cluster --enable-ssm
}

task delete_cluster {
  # eksctl delete cluster --name=<name> [--region=<region>]
}

task install_eksctl {
  scoop install eksctl
  #curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
  #sudo mv /tmp/eksctl /usr/local/bin
}

task enable_completion {
  eksctl completion powershell > C:\Users\Documents\WindowsPowerShell\Scripts\eksctl.ps1
}
