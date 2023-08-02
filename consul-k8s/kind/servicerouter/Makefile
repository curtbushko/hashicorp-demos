HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul-enterprise
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:latest
CONSUL_IMAGE=$(DOCKERHUB)/consul-dev:latest
CONSUL_DATAPLANE_IMAGE=$(DOCKERHUB)/consul-dataplane:latest
CUR_DIR=$(shell pwd)

# -- for fun
PURPLE='\033[0;35m'       # Purple

build: build-k8s build-consul build-consul-dataplane

build-k8s:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-k8s image ${CONSUL_K8S_IMAGE}"
	cd $(K8S_DIR) && REMOTE_DEV_IMAGE=${CONSUL_K8S_IMAGE} GOARCH=amd64 make control-plane-dev-docker-multi-arch

build-consul:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image ${CONSUL_IMAGE}"
	@cd $(CONSUL_DIR) && REMOTE_DEV_IMAGE=${CONSUL_IMAGE} GOARCH=amd64 make remote-docker

build-consul-dataplane:
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

create-cluster: 
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind cluster dc1"
	@kind create cluster --config=kind.config --image kindest/node:v1.24.13 --name=dc1

delete-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind cluster dc1"
	@kind delete cluster --name dc1

acceptance-no-cleanup:
	kind load docker-image docker.mirror.hashicorp.services/hashicorppreview/consul-enterprise:1.15-dev --name dc1 || true
	cd $(ACCEPTANCE_DIR)/acceptance/tests/config-entries && go test -run TestControllerNamespaces -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-consul-image="docker.mirror.hashicorp.services/hashicorppreview/consul-enterprise:1.15-dev" \
		-consul-k8s-image=${CONSUL_K8S_IMAGE} \
		-no-cleanup-on-failure

deploy-hashicups:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deploying hashicups"
	@kubectl create ns hashicups || true
	@kubectl apply -f ./hashicups -n hashicups

deploy-coffee:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deploying coffee service, view the ui on localhost:8080"
	@kubectl apply -f ./coffee-service/service.yaml -n hashicups
	@kubectl apply -f ./coffee-service/v1/deployment.yaml -n hashicups

show-product-api-logs:
	@kubectl logs -f deploy/product-api product-api -n hashicups

show-cofee-service-logs:
	@kubectl logs -f deploy/coffee-service coffee-service -n hashicups

make deploy-service-router:
	@kubectl apply -f ./service-router.yaml

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

frontend-ui:
	@kubectl port-forward service/frontend -n hashicups 8081:80



wait:
	sleep 30

all: delete-cluster create-cluster build pull load deploy-consul
demo: delete-cluster create-cluster pull load deploy-consul wait deploy-hashicups deploy-coffee

