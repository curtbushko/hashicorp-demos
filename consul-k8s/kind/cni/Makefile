CONSUL_WORKTREE=main
K8S_WORKTREE=main
CONSUL_DATAPLANE_WORKTREE=main
HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/$(K8S_WORKTREE)
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/$(K8S_WORKTREE)
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul/$(CONSUL_WORKTREE)
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane/$(CONSUL_DATAPLANE_WORKTREE)
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-k8s-control-plane:1.4-dev
#CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:latest
CONSUL_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-enterprise:1.18-dev
#CONSUL_IMAGE=$(DOCKERHUB)/consul-dev:latest
CONSUL_DATAPLANE_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-dataplane:1.4-dev
#CONSUL_DATAPLANE_IMAGE=$(DOCKERHUB)/consul-dataplane:latest

CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)
KIND_VERSION="v1.27.1"

build: build-k8s build-consul build-consul-dataplane

build-k8s:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-k8s image ${CONSUL_K8S_IMAGE}"
	cd $(K8S_DIR) && REMOTE_DEV_IMAGE=${CONSUL_K8S_IMAGE} GOARCH=amd64 make control-plane-dev-docker-multi-arch

build-consul:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image ${CONSUL_IMAGE}"
	@cd $(CONSUL_DIR) && REMOTE_DEV_IMAGE=${CONSUL_IMAGE} GOARCH=amd64 make remote-docker

build-dataplane:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-dataplane image ${CONSUL_DATAPLANE_IMAGE}"
	@cd $(CONSUL_DATAPLANE_DIR) && make bin
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/amd64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/arm64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && docker buildx build -t "${CONSUL_DATAPLANE_IMAGE}" --platform linux/amd64,linux/arm64 --push .

pull:
	@docker pull ${CONSUL_K8S_IMAGE}
	@docker pull ${CONSUL_IMAGE}
	@docker pull ${CONSUL_DATAPLANE_IMAGE}

load:
	@kind load docker-image -n dc1 ${CONSUL_K8S_IMAGE} || true
	@kind load docker-image -n dc1 ${CONSUL_IMAGE} || true
	@kind load docker-image -n dc1  ${CONSUL_DATAPLANE_IMAGE} || true

deploy-consul:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deploying consul"
	@kubectl create ns consul || true
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul
	cd $(HELM_CHART_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.image=$(CONSUL_IMAGE) --set global.imageK8S=$(CONSUL_K8S_IMAGE) --set global.imageConsulDataplane=$(CONSUL_DATAPLANE_IMAGE) --set global.enterpriseLicense.secretName="consul-ent-license" --set global.enterpriseLicense.secretKey="key" --set fullnameOverride=consul ./charts/consul
	@kubectl ns consul

acceptance:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running acceptance tests"
	@docker pull $(CONSUL_IMAGE)
	@kind load docker-image $(CONSUL_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_K8S_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_IMAGE) --name dc2 || true
	@kind load docker-image $(CONSUL_K8S_IMAGE) --name dc2 || true
	cd $(K8S_DIR)/acceptance/tests/peering && go test -run TestPeering_ConnectNamespaces -v -p 1 -timeout 120m \
		-use-kind \
		-enable-enterprise \
		-enable-transparent-proxy \
		-enable-cni \
		-enable-multi-cluster \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-no-cleanup-on-failure

nsenter:
	docker exec -it dc1-control-plane /bin/bash -c "export NS=$(ip netns | head -n 1 | awk '{print $1}');nsenter --net=/var/run/netns/${NS} -- iptables -t nat --list"

create-cluster: 
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind clusters"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc1
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc2

delete-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind clusters"
	@kind delete cluster --name dc1
	@kind delete cluster --name dc2

calico: deploy-calico

deploy-calico:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Installing calico on dc1"
	@kubectl config use-context kind-dc1
	kubectl create namespace calico-system ||true
	kubectl create -f $(K8S_DIR)/acceptance/framework/environment/cni-kind/tigera-operator.yaml
	# Sleeps are needed as installs can happen too quickly for Kind to handle it
	@sleep 30
	kubectl create -f $(K8S_DIR)/acceptance/framework/environment/cni-kind/custom-resources.yaml
	@sleep 20

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

all: delete-cluster create-cluster deploy-calico build deploy-consul wait deploy-static podstatus
reset: delete-cluster create-cluster deploy-calico wait deploy-consul wait deploy-static podstatus

