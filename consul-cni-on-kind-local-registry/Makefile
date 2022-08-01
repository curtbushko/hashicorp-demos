HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/cni-proxyconfig
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/cni-proxyconfig
DOCKERHUB=localhost:5001
RELEASE=consul
CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && GOARCH=arm64 make control-plane-dev-docker
	docker tag consul-k8s-control-plane-dev $(DOCKERHUB)/consul-k8s-control-plane-dev:latest
	docker push $(DOCKERHUB)/consul-k8s-control-plane-dev:latest

load:
	kind load docker-image envoyproxy/envoy:v1.22.2
	kind load docker-image curlimages/curl:7.77.0 || true
	kind load docker-image docker.mirror.hashicorp.services/hashicorp/http-echo:alpine || true
	kind load docker-image hashicorp/consul:1.12.3 || true
	kind load docker-image calico/cni:v3.23.3 || true
	kind load docker-image calico/kube-controllers:v3.23.3 || true
	kind load docker-image calico/node:v3.23.3 || true
	kind load docker-image calico/pod2daemon-flexvol:v3.23.3 || true
	kind load docker-image calico/typha:v3.23.3 || true
	kind load docker-image quay.io/tigera/operator:v1.27.12 || true

# Pull all the images that are need for calico to speed things up.
pull-all:
	docker pull envoyproxy/envoy:v1.22.2
	docker pull curlimages/curl:7.77.0
	docker pull docker.mirror.hashicorp.services/hashicorp/http-echo:alpine || true
	docker pull hashicorp/consul:1.12.3
	docker pull calico/cni:v3.23.3
	docker pull calico/kube-controllers:v3.23.3
	docker pull calico/node:v3.23.3
	docker pull calico/pod2daemon-flexvol:v3.23.3
	docker pull calico/typha:v3.23.3
	docker pull quay.io/tigera/operator:v1.27.12

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.imageK8S=$(DOCKERHUB)/consul-k8s-control-plane-dev:latest --set fullnameOverride=consul ./charts/consul

create-cluster: 
	./kind-with-registry.sh	

delete-cluster:
	kind delete cluster

calico: deploy-calico

deploy-calico:
	kubectl create namespace calico-system ||true
	kubectl create -f https://docs.projectcalico.org/manifests/tigera-operator.yaml
	kubectl apply -f ./calico-config.yaml
	@sleep 60
	kubectl -n calico-system set env daemonset/calico-node FELIX_IGNORELOOSERPF=true

deploy-static:
	kubectl apply -f static-server.yaml -n default
	kubectl apply -f static-client.yaml -n default

podstatus:
	kubectl get pods -n consul
	kubectl get pods -n default

exec:
	docker exec -it kind-control-plane /bin/bash

show-host:
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Showing CNI files on in /etc/cni/net.d"
	@docker exec kind-control-plane /bin/bash -c "ls /etc/cni/net.d"
	@echo "[$(shell date +'%d/%b/%Y:%H:%M:%S %z')] Showing CNI files on in /opt/cni/bin"
	@docker exec kind-control-plane /bin/bash -c "ls /opt/cni/bin"

wait:
	sleep 60

delete-consul:
	echo "Deleteing helm release: ${RELEASE}"
	kubectl ns consul
	helm del --debug ${RELEASE}
	kubectl delete pvc -l release="${RELEASE}"
	kubectl get secret | grep --color=auto "${RELEASE}" | grep --color=auto Opaque | grep --color=auto token | awk '{print $1}' | xargs kubectl delete secret

delete-static:
	echo "Deleteing static services"
	kubectl delete deployment static-server -n default || true
	kubectl delete deployment static-client -n default || true
	
all: delete-cluster create-cluster load deploy-calico build deploy-consul wait deploy-static podstatus
reset: delete-static delete-consul build deploy-consul wait deploy-static podstatus

