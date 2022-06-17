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

hashicups:
	kubectl apply -f ./hashicups/frontend.yaml -n consul

zzz:
	@echo "Sleeping..."
	sleep 30

deploy-multus:
	kubectl apply -f multus-daemonset.yml

podstatus:
	kubectl ns consul 
	kubectl get pods 

exec:
	docker exec -it kind-control-plane /bin/bash

all: delete-cluster create-cluster deploy-multus deploy-cni podstatus
	
