# This setup attempts to make it easy to run all of the acceptance tests. It pulls values
# from the makefile in the root of the consul-k8s directory
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
ACCEPTANCE_DIR=$(K8S_DIR)/acceptance
#CONSUL_K8S_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-k8s-control-plane:1.2.0-dev
DOCKERHUB=curtbushko
K8S_VERSION=$(shell cd ${K8S_DIR} && make version)
CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:${K8S_VERSION}
CONSUL_IMAGE=$(shell cd ${K8S_DIR} && make consul-enterprise-version)
CONSUL_DATAPLANE_IMAGE=$(shell cd ${K8S_DIR} && make consul-dataplane-version)

CUR_DIR=$(shell pwd)
KIND_VERSION="v1.27.1"

versions:
	@echo "Consul image: ${CONSUL_IMAGE}"
	@echo "Consul-k8s image: ${CONSUL_K8S_IMAGE}"
	@echo "Consul dataplane image: ${CONSUL_DATAPLANE_IMAGE}"

build: build-k8s

build-k8s:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-k8s image ${CONSUL_K8S_IMAGE}"
	cd $(K8S_DIR) && REMOTE_DEV_IMAGE=${CONSUL_K8S_IMAGE} GOARCH=amd64 make control-plane-dev-docker-multi-arch

pull:
	@docker pull ${CONSUL_K8S_IMAGE}
	@docker pull ${CONSUL_IMAGE}
	@docker pull ${CONSUL_DATAPLANE_IMAGE}

load:
	@kind load docker-image -n dc1 ${CONSUL_K8S_IMAGE} || true
	@kind load docker-image -n dc1 ${CONSUL_IMAGE} || true
	@kind load docker-image -n dc1  ${CONSUL_DATAPLANE_IMAGE} || true
	@kind load docker-image -n dc2 ${CONSUL_K8S_IMAGE} || true
	@kind load docker-image -n dc2 ${CONSUL_IMAGE} || true
	@kind load docker-image -n dc2  ${CONSUL_DATAPLANE_IMAGE} || true

acceptance:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running acceptance tests"
	cd $(ACCEPTANCE_DIR)/tests && gotestsum --format=testname -- \
		./... \
		-p 1 -timeout 2h -failfast \
		-use-kind \
		-enable-enterprise \
		-enable-multi-cluster \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-consul-dataplane-image=$(CONSUL_DATAPLANE_IMAGE) \
		-no-cleanup-on-failure

create-clusters: create-cluster
create-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind clusters dc1 & dc2"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc1
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=dc2

delete-clusters: delete-cluster
delete-cluster:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind clusters dc1 & dc2"
	@kind delete cluster --name dc1
	@kind delete cluster --name dc2

podstatus:
	kubectl ns consul 
	kubectl get pods 

wait:
	sleep 60

show-injector-logs:
	@kubectl logs -f -l component=connect-injector -n consul

ui:
	@kubectl port-forward service/consul-ui -n consul 8080:80


all: delete-cluster create-cluster build pull load acceptance

