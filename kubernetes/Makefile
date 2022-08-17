# https://kubernetes.io/docs/setup/
# https://kubernetes.io/docs/tutorials/kubernetes-basics/
#
# Question:
# * Does minikube work on m1 mac?

kube-version:
	minikube version

kube-testme:
	echo $(myvar)

kube-readme:
	echo $(notes)

kind-install:
	brew install kind
	# choco install kind

kind-quick-cluster:
	docker ps
	kind create cluster # Default cluster context name is "kind"

kind-cluster-with-name:
	docker ps
	kind create cluster --name devopslife-kind

kind-cluster-info:
	kubectl cluster-info --context kind-kind

kind-remove-cluster:
	kind delete cluster
	# kind delete cluster --name devopslife-kind

kind-load-image:
	# kind load docker-image my-custom-image-0 my-custom-image-1
	# kind load docker-image my-custom-image-0 my-custom-image-1 --name kind-2

kind-load-archive:
	# kind load image-archive /my-archive-archive.tar
	# docker build -t my-custom-image:unique-tag ./my-image-dir
	# kind load docker-image my-custom-image:unique-tag
	# kubectl apply -f my-manifest-user-my-image:unique-tag

kind-config-nginx-ingress-step1:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

kind-config-nginx-ingress-step2:
	kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

kind-config-nginx-ingress-step3:
	kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/usage.yaml

kind-config-nginx-ingress-test:
	# should output "foo"
	curl localhost/foo
	# should output "bar"
	curl localhost/bar

kind-config-load-balancer-step1:
	# Create the namespace
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/namespace.yaml

kind-config-load-balancer-step2:
	# Apply the manifest
	kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/master/manifests/metallb.yaml
kind-config-load-balancer-test:
	# Watch for running pods
	kubectl get pods -n metallb-system --watch

docker-network-inspect:
	# https://kind.sigs.k8s.io/docs/user/loadbalancer/#setup-address-pool-used-by-loadbalancers
	docker network inspect -f '{{.IPAM.Config}}' kind

kind-setup-local-registry:
	# https://kind.sigs.k8s.io/docs/user/local-registry/#using-the-registry
	./kind-with-registry.sh
	# Notes about this is that everything that we are creating lately is being deployed to the
	# default namespace, so we want to make sure that we are not putting everything in the default namespace ...

kind-registry-test:
	docker pull gcr.io/google-samples/hello-app:1.0
	docker tag gcr.io/google-samples/hello-app:1.0 localhost:5001/hello-app:1.0
	docker push localhost:5001/hello-app:1.0
	kubectl create deployment hello-server --image=localhost:5001/hello-app:1.0

kind-config-load-balancer-step4:
	kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/metallb-configmap.yaml

kind-config-load-balancer-split-traffic:
	kubectl apply -f https://kind.sigs.k8s.io/examples/loadbalancer/usage.yaml

kind-verify-load-balancer-split-traffic:
	LB_IP=$(kubectl get svc/foo-service -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')
	# should output foo and bar on separate lines
	for _ in {1..10}; do
		curl ${LB_IP}:5678
	done

help:
	https://kind.sigs.k8s.io/docs/user/quick-start/

kind-create-config-cluster:
	kind create cluster --config kind-example-config.yaml

kube-start:
	minikube start

kube-start-2-cluster:
	minikube start --nodes 2 -p multinode-demo

kube-sample-deployment:
	kubectl create deployment hello-minikube --image=docker/getting-started --replicas=2
	kubectl expose deployment hello-minikube --type=NodePort --port=80

kube-get-deployments:
	kubectl get deployments

kube-get-rollout-status:
	kubectl rollout status deployment/hello-minikube

kube-get-info:
	kubectl get rs,pods,service

check-docker-running:
	docker ps

kubectl-version:
	kubectl version

kubectl-cluster-info:
	kubectl cluster-info

kubectl-get-nodes:
	kubectl get nodes

show-docker-kube:
	echo $(install-docker)

# ==============
# Overview
# ==============
# Cluster Architecture
# ==============
# Containers
# ==============
# Workloads
# ==============
# Services, Load Balancing, and Networking
# ==============
# Storage
# ==============
# Configuration
# ==============
# Security
# ==============
# Policies
# ==============
# Scheduling, Preepmption, Evicition
# ==============
# Cluster Administration
# ==============
# Extending Kubernetes
# ==============
# ==============
# Tasks
# ==============
# ==============
# Install Tools
# ==============
# Administer a Cluster
# ==============
# Configure Pods and Containers
# ==============
# Manage Kubernetes Objects
# ==============
# Manage Secrets
# ==============
# Inject Data into Applications
# ==============
# Run Applications
# ==============
# Run Jobs
# ==============
# Access Applications in a Cluster
# ==============
# Monitoring and Logging and Debugging
# ==============
# Extend Kubernetes
# ==============
# TLS
# ==============
# Manage Cluster Daemons
# ==============
# Service Catelog
# ==============
# Networking
# ==============
# Configure kubelet image credential provider
# ==============
# Extend kubectl with plugins
# ==============
# Manage Hugepages
# ==============
# Schedule GPUs
# ==============
