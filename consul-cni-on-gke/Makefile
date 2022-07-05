HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/cni-helm
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/cni
CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && DOCKER_DEFAULT_PLATFORM=linux/amd64 make control-plane-dev-docker
	docker tag consul-k8s-control-plane-dev:latest curtbushko/consul-k8s-control-plane-dev:$(GIT_REV)
	docker push curtbushko/consul-k8s-control-plane-dev:$(GIT_REV)

load:
	kind load docker-image curtbushko/consul-k8s-control-plane-dev:latest ||true

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.imageK8S=curtbushko/consul-k8s-control-plane-dev:$(GIT_REV) ./charts/consul

wait-cni:
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Sleeping while waiting for CNI installer to be finished"
	@sleep 60

create-cluster: 
	kind create cluster --config=kind.config

delete-cluster:
	kind delete cluster

calico: deploy-calico

deploy-calico:
	kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
	kubectl apply -f ./calico-config.yaml
	@sleep 60
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

.PHONY: hashicups
hashicups:
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
	sleep 30

reset: delete-cluster create-cluster build load deploy-calico deploy-consul podstatus

all: delete-cluster create-cluster deploy-calico wait deploy-consul podstatus 
