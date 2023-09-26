# WARNING: ! THIS IS THE VERSION YOU WANT TO CERTIFY AGAINST!
CHART_VERSION="1.2"

# WARNING: ! THIS IS THE VERSION YOU WANT TO CERTIFY AGAINST!
TEMPLATE_FILE=consul-k8s-gke-autopilot.yaml
K8S_WORKTREE=curtbushko/gke-autopilot-acceptance
CONSUL_WORKTREE=main
CONSUL_DATAPLANE_WORKTREE=main
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/$(K8S_WORKTREE)
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul/$(CONSUL_WORKTREE)
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane/$(CONSUL_DATAPLANE_WORKTREE)
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-k8s-control-plane:1.3.0-dev
#CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:latest
#CONSUL_IMAGE=$(DOCKERHUB)/consul-dev:latest
CONSUL_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul:1.17-dev
CONSUL_DATAPLANE_IMAGE=$(DOCKERHUB)/consul-dataplane:latest
#CONSUL_DATAPLANE_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-dataplane:1.3-dev

CUR_DIR=$(shell pwd)
KIND_VERSION="v1.27.1"

# GKE specific things
context:
	gcloud container clusters get-credentials autopilot-cluster-2 --region us-central1 --project ${GCP_CONSUL_K8S_DEV_PROJECT}

# The cluster needs to be updated to allow NET_ADMIN to work
allow-net-admin:
	gcloud container clusters update autopilot-cluster-2 --region us-central1 --workload-policies=allow-net-admin

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
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/amd64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/arm64/consul-dataplane ./cmd/consul-dataplane
	@docker buildx create --use default
	@cd $(CONSUL_DATAPLANE_DIR) && docker buildx build -t "${CONSUL_DATAPLANE_IMAGE}" --platform linux/amd64,linux/arm64 --push .

gke-clean:
	kubectl delete crd gateways.gateway.networking.k8s.io
	kubectl delete crd gatewayclasses.gateway.networking.k8s.io
	kubectl delete gateways.gateway.networking.k8s.io

secret:
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul || true

deploy-consul:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deploying consul"
	@kubectl create ns consul || true
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul || true
	cd $(K8S_DIR) && helm install consul --create-namespace -n consul -f $(CUR_DIR)/helm.values.yaml --set global.enterpriseLicense.secretName="consul-ent-license" --set global.enterpriseLicense.secretKey="key" --set fullnameOverride=consul ./charts/consul
	@kubectl ns consul

generate-helm-template:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Generating helm template from chart ${CHART_VERSION}"
	@helm repo add hashicorp https://helm.releases.hashicorp.com && helm repo update && helm search repo hashicorp --version ${CHART_VERSION}
	helm template consul hashicorp/consul -f $(CUR_DIR)/helm.values.yaml --version ${CHART_VERSION} --create-namespace --namespace consul --set global.enterpriseLicense.secretName="consul-ent-license" --set global.enterpriseLicense.secretKey="key" --set fullnameOverride=consul > ${TEMPLATE_FILE}
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Template generated to ${TEMPLATE_FILE}"

acceptance: pull load
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running acceptance tests"
	cd $(K8S_DIR)/acceptance/tests/connect && go test -run TestConnectInjectNamespaces -v -p 1 -timeout 20m \
		-enable-enterprise \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-consul-dataplane-image=$(CONSUL_DATAPLANE_IMAGE)

deploy-static:
	kubectl create namespace static || true
	kubectl ns static || true
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

delete-static:
	kubectl delete -f static-server.yaml -n static
	kubectl delete -f static-client.yaml -n static
	kubectl delete ns static || true

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

