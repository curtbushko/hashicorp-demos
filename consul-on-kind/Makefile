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
KIND_VERSION="v1.27.1"

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
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInject -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-cni \
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		-no-cleanup-on-failure

create-cluster: 
	kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc1

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

wait:
	sleep 60 

show-injector-logs:
	@kubectl logs -f -l component=connect-injector -n consul

show-services:
	@kubectl exec consul-server-0 -n consul -- curl -s -XGET localhost:8500/v1/catalog/services

show-discovery-chain:
	@kubectl exec consul-server-0 -n consul -- curl -s -XGET localhost:8500/v1/discovery-chain/static-client

show-static-client:
	@kubectl exec consul-server-0 -n consul -- curl -s -XGET localhost:8500/v1/catalog/service/static-client | jq

show-static-client-sidecar-proxy:
	@kubectl exec consul-server-0 -n consul -- curl -s -XGET localhost:8500/v1/catalog/service/static-client-sidecar-proxy | jq

ui:
	@kubectl port-forward service/consul-ui -n consul 8080:80


all: delete-cluster create-cluster build pull load deploy-consul wait deploy-static podstatus
reset: delete-cluster create-cluster wait deploy-consul wait deploy-static podstatus

