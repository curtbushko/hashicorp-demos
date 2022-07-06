HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/cni-helm
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/cni
CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && make control-plane-dev-docker

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.imageK8S=curtbushko/consul-k8s-control-plane-dev:latest --set fullnameOverride=consul ./charts/consul
	#cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set fullnameOverride=consul ./charts/consul

.PHONY: hashicups
hashicups:
	kubectl apply -f ./hashicups/frontend.yaml -n consul

podstatus:
	kubectl ns consul 
	kubectl get pods 

wait:
	sleep 60 

hdel:
	hdel consul

reset:  hdel build deploy-consul wait hashicups podstatus
