HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:latest

CUR_DIR=$(shell pwd)

GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && GOARCH=amd64 make control-plane-dev-docker-multi-arch

create-cluster: 
	kind create cluster --config=kind.config --image kindest/node:v1.24.4

delete-cluster:
	kind delete cluster

deploy-consul:
	kubectl create namespace consul || true
	kubectl ns consul || true
	cd $(HELM_CHART_DIR) && helm install consul -n consul -f $(CUR_DIR)/helm.values.yaml \
		--set global.imageK8S=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		--set fullnameOverride=consul \
		./charts/consul

acceptance:
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInject -v -p 1 -timeout 20m \
		-use-kind \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-enterprise \
		-enable-cni \
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE)

nsenter:
	docker exec -it kind-control-plane /bin/bash -c "NS=`ip netns | head -n 1 | awk '{print $1}'` && nsenter --net=/var/run/netns/${NS} -- iptables -t nat --list"

multus: deploy-multus
calico: deploy-calico

deploy-multus:
	kubectl apply -f multus-daemonset.yml -n kube-system

deploy-calico:
	kubectl create namespace calico-system ||true
	kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.24.0/manifests/tigera-operator.yaml
	kubectl apply -f ./calico-config.yaml
	@sleep 60
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

deploy-static:
	kubectl create ns static || true
	kubectl ns static || true
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

delete-static:
	kubectl delete -f static-server.yaml -n static
	kubectl delete -f static-client.yaml -n static

podstatus:
	kubectl get pods 

exec:
	docker exec -it kind-control-plane /bin/bash

show-host:
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Showing CNI files on in /etc/cni/net.d"
	@docker exec kind-control-plane /bin/bash -c "ls /etc/cni/net.d"
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Showing CNI files on in /opt/cni/bin"
	@docker exec kind-control-plane /bin/bash -c "ls /opt/cni/bin"

wait:
	sleep 60

all: delete-cluster create-cluster deploy-multus wait deploy-calico wait deploy-consul wait deploy-static podstatus

