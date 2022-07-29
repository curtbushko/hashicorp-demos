HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/cni-proxyconfig
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/cni-proxyconfig
CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && GOARCH=amd64 make control-plane-dev-docker-multi-arch
load:
	kind load docker-image curtbushko/consul-k8s-control-plane-dev:latest ||true

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.imageK8S=curtbushko/consul-k8s-control-plane-dev:latest --set fullnameOverride=consul ./charts/consul
	#cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set fullnameOverride=consul ./charts/consul

create-cluster: 
	kind create cluster --config=kind.config

delete-cluster:
	kind delete cluster

calico: deploy-calico

deploy-calico:
	kubectl create namespace calico-system
	kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
	kubectl apply -f ./calico-config.yaml
	@sleep 60
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

.PHONY: hashicups
hashicups:
	#kubectl apply -f ./hashicups -n consul
	kubectl apply -f ./hashicups/frontend.yaml -n consul

podstatus:
	kubectl ns consul 
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

all: delete-cluster create-cluster deploy-calico build deploy-consul wait hashicups podstatus
reset: delete-cluster create-cluster deploy-calico wait deploy-consul wait hashicups podstatus

