HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:latest
CONSUL_IMAGE=consul-dev:latest
CONSUL_DATAPLANE_IMAGE=consul-dataplane:latest
CUR_DIR=$(shell pwd)

build: build-k8s build-consul build-consul-dataplane

build-k8s:
	echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-k8s"
	@cd $(K8S_DIR) && GOARCH=amd64 make control-plane-dev-docker-multi-arch

build-consul:
	echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul"
	@cd $(CONSUL_DIR) && REMOTE_DEV_IMAGE=${DOCKERHUB}/${CONSUL_IMAGE} GOARCH=amd64 make remote-docker

build-consul-dataplane:
	echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-dataplane"
	@cd $(CONSUL_DATAPLANE_DIR) && make bin
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/amd64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/arm64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && docker buildx build -t "${DOCKERHUB}/${CONSUL_DATAPLANE_IMAGE}" --platform linux/amd64,linux/arm64 --push .

pull:
	docker pull ${DOCKERHUB}/${CONSUL_K8S_IMAGE}
	docker pull ${DOCKERHUB}/${CONSUL_IMAGE}
	docker pull ${DOCKERHUB}/${CONSUL_DATAPLANE_IMAGE}

load:
	kind load docker-image $(DOCKERHUB)/${CONSUL_K8S_IMAGE} ||true
	kind load docker-image $(DOCKERHUB)/${CONSUL_IMAGE} ||true
	kind load docker-image $(DOCKERHUB)/${CONSUL_DATAPLANE_IMAGE} ||true

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.imageK8S=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) --set global.imageConsulDataplane=${DOCKERHUB}/${CONSUL_DATAPLANE_IMAGE} --set fullnameOverride=consul ./charts/consul

acceptance:
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInject -v -p 1 -timeout 20m \
		-use-kind \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-enterprise \
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE)

acceptance-no-cleanup:
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInjectNamespace -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-cni \
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		-no-cleanup-on-failure

nsenter:
	docker exec -it dc1-control-plane /bin/bash -c "export NS=$(ip netns | head -n 1 | awk '{print $1}');nsenter --net=/var/run/netns/${NS} -- iptables -t nat --list"

create-cluster: 
	kind create cluster --config=kind.config --image kindest/node:v1.23.6 --name=dc1

delete-cluster:
	kind delete cluster --name dc1

deploy-static:
	kubectl create namespace static || true
	kubectl ns static || true
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

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

all: delete-cluster create-cluster build pull load deploy-consul wait deploy-static podstatus
reset: delete-cluster create-cluster wait deploy-consul wait deploy-static podstatus

