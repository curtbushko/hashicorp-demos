HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-k8s-control-plane:1.3.0-dev
CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:latest
#CONSUL_IMAGE=$(DOCKERHUB)/consul-dev:latest
CONSUL_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul:1.17-dev
#CONSUL_DATAPLANE_IMAGE=$(DOCKERHUB)/consul-dataplane:latest
CONSUL_DATAPLANE_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-dataplane:1.3-dev

CUR_DIR=$(shell pwd)
KIND_VERSION="v1.27.1"

versions:
	echo "Consul image: ${CONSUL_IMAGE}"
	echo "Consul-k8s image: ${CONSUL_K8S_IMAGE}"
	echo "Consul dataplane image: ${CONSUL_DATAPLANE_IMAGE}"

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

acceptance-tproxy:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running acceptance tests"
	@docker pull $(CONSUL_IMAGE)
	@kind load docker-image $(CONSUL_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_K8S_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_DATAPLANE_IMAGE) --name dc1 || true
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul
	cd $(ACCEPTANCE_DIR)/acceptance/tests/api-gateway && go test -run TestAPIGateway_ExternalServers -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-enable-multi-cluster \
		-enable-transparent-proxy \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-no-cleanup-on-failure

acceptance:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running acceptance tests"
	@docker pull $(CONSUL_IMAGE)
	@kind load docker-image $(CONSUL_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_K8S_IMAGE) --name dc1 || true
	@kind load docker-image $(CONSUL_DATAPLANE_IMAGE) --name dc1 || true
	cd $(ACCEPTANCE_DIR)/acceptance/tests/api-gateway && go test -run TestAPIGateway_ExternalServers -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-enable-multi-cluster \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-consul-dataplane-image=$(CONSUL_DATAPLANE_IMAGE) \
		-no-cleanup-on-failure

create-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind cluster dc1"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc1

create-clusters:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind cluster dc1"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc1
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind cluster dc2"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc2

delete-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind cluster dc1"
	@kind delete cluster --name dc1

delete-clusters:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind cluster dc1"
	@kind delete cluster --name dc1
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind cluster dc2"
	@kind delete cluster --name dc2

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
reset: delete-cluster create-cluster status
acc: delete-clusters create-clusters pull load acceptance
