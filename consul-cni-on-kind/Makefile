deploy-cni:
	kubectl create ns consul
	kubectl apply -f ./deployment -n consul

wait-cni:
	@echo "Waiting for CNI installer to be finished"
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
	@sleep 20
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

wait-calico:
	@echo "Waiting for Calico CNI installer to be finished"
	kubectl wait --for=condition=ready --timeout=360s pod -l k8s-app=calico-node -n calico-system 
	@echo "calico-node is ready!"

hashicups:
	kubectl apply -f ./hashicups/frontend.yaml -n consul

podstatus:
	kubectl ns consul 
	kubectl get pods 

exec:
	docker exec -it kind-control-plane /bin/bash

all: delete create deploy-calico wait-calico deploy-cni wait-cni podstatus 
