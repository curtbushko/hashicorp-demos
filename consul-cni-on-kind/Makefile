HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/cni-helm
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/cni
CUR_DIR=$(shell pwd)

build:
	cd $(CNI_DIR) && make control-plane-dev-docker
	docker tag consul-k8s-control-plane-dev curtbushko/consul-k8s-control-plane-dev
	docker push curtbushko/consul-k8s-control-plane-dev

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml ./charts/consul

wait-cni:
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Waiting for CNI installer to be finished"
	kubectl wait --for=condition=ready --timeout=360s pod -l k8s-app=consul-cni-node -n consul
	@echo "consul-cni-node is ready!"

create-cluster: 
	kind create cluster --config=kind.config

delete-cluster:
	kind delete cluster

calico: deploy-calico wait-calico

deploy-calico:
	kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
	kubectl apply -f ./calico-config.yaml
	@sleep 30 
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

wait-calico:
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Waiting for Calico CNI installer to be finished"
	kubectl wait --for=condition=ready --timeout=360s pod -l k8s-app=calico-node -n calico-system 
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] calico-node is ready!"

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



all: delete create deploy-calico wait-calico deploy-cni wait-cni podstatus 
