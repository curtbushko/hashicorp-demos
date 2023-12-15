WORKTREE="curtbushko/delete-all-resources"
TAG=delete-all-resources
#WORKTREE=main
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/$(WORKTREE)
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul-enterprise/$(WORKTREE)
CONSUL_DATAPLANE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-dataplane/$(WORKTREE)
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-k8s-control-plane:1.4.0-dev
#CONSUL_K8S_IMAGE=$(DOCKERHUB)/consul-k8s-control-plane-dev:$(TAG)
#CONSUL_IMAGE=$(DOCKERHUB)/consul-dev:latest
CONSUL_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul:1.18-dev
#CONSUL_DATAPLANE_IMAGE=$(DOCKERHUB)/consul-dataplane:latest
CONSUL_DATAPLANE_IMAGE=docker.mirror.hashicorp.services/hashicorppreview/consul-dataplane:1.4-dev

CUR_DIR=$(shell pwd)
KIND_VERSION="v1.27.1"

.PHONY: versions
versions:
	echo "Consul image: ${CONSUL_IMAGE}"
	echo "Consul-k8s image: ${CONSUL_K8S_IMAGE}"
	echo "Consul dataplane image: ${CONSUL_DATAPLANE_IMAGE}"

.PHONY: build
build: build-k8s build-consul build-consul-dataplane

.PHONY: build-k8s
build-k8s:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-k8s image ${CONSUL_K8S_IMAGE}"
	cd $(K8S_DIR) && REMOTE_DEV_IMAGE=${CONSUL_K8S_IMAGE} GOARCH=amd64 make control-plane-dev-docker-multi-arch

.PHONY: build-consul
build-consul:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image ${CONSUL_IMAGE}"
	@cd $(CONSUL_DIR) && REMOTE_DEV_IMAGE=${CONSUL_IMAGE} GOARCH=amd64 make remote-docker

.PHONY: build-dataplane
build-dataplane:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul-dataplane image ${CONSUL_DATAPLANE_IMAGE}"
	@cd $(CONSUL_DATAPLANE_DIR) && make bin
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/amd64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && mkdir -p dist/linux/amd64 && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/arm64/consul-dataplane ./cmd/consul-dataplane
	@cd $(CONSUL_DATAPLANE_DIR) && docker buildx build -t "${CONSUL_DATAPLANE_IMAGE}" --platform linux/amd64,linux/arm64 --push .

.PHONY: pull
pull:
	@docker pull ${CONSUL_K8S_IMAGE}
	@docker pull ${CONSUL_IMAGE}
	@docker pull ${CONSUL_DATAPLANE_IMAGE}
	@docker pull docker.mirror.hashicorp.services/hashicorp/http-echo:alpine
	@docker pull docker.mirror.hashicorp.services/hashicorp/http-echo:latest
	@docker pull ishustava/fake-service:0.7.0
	@docker pull anubhavmishra/tiny-tools:latest

.PHONY: load/%
load/%:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Loading images in $(*)"
	@kind load docker-image -n $(*) ${CONSUL_K8S_IMAGE} || true
	@kind load docker-image -n $(*) ${CONSUL_IMAGE} || true
	@kind load docker-image -n $(*) ${CONSUL_DATAPLANE_IMAGE} || true
	@kind load docker-image -n $(*) docker.mirror.hashicorp.services/hashicorp/http-echo:alpine || true
	@kind load docker-image -n $(*) docker.mirror.hashicorp.services/hashicorp/http-echo:latest || true
	@kind load docker-image -n $(*) ishustava/fake-service:0.7.0 || true
	@kind load docker-image -n $(*) anubhavmishra/tiny-tools:latest || true

.PHONY: load
load: load/dc1 load/dc2

.PHONY: license/%
license/%:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating enterprise license in kind-$(*)"
	@kubectl config set-context kind-$(*)
	@kubectl create namespace consul || true
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul || true

.PHONY: acceptance/% 
acceptance/%: create-cluster/dc1 create-cluster/dc2 pull license/dc1 license/dc2 load/dc1 load/dc2 ## acceptance/% help
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running $(*) acceptance tests"
	@kubectl config set-context kind-dc1
	@cd $(K8S_DIR)/acceptance/tests/$(*) && go test -v -p 1 -timeout 40m \
		-use-kind \
		-enable-enterprise \
		-enable-multi-cluster \
		-enable-transparent-proxy \
		-kube-contexts="kind-dc1,kind-dc2" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-dataplane-image=$(CONSUL_DATAPLANE_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE) \
		-no-cleanup-on-failure

.PHONE: acceptance/partitions
acceptance/partitions: create-cluster/dc1 create-cluster/dc2 pull license/dc1 license/dc2 load/dc1 load/dc2
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running partitions acceptance tests"
	@cd $(K8S_DIR)/acceptance/tests/partitions && go test -run TestPartitions_Connect -v -p 1 -timeout 40m \
		-use-kind \
		-enable-enterprise \
		-enable-multi-cluster \
		-enable-transparent-proxy \
		-kube-contexts="kind-dc1,kind-dc2,kind-dc3,kind-dc4" \
		-consul-image=$(CONSUL_IMAGE) \
		-consul-dataplane-image=$(CONSUL_DATAPLANE_IMAGE) \
		-consul-k8s-image=$(CONSUL_K8S_IMAGE)

.PHONY: packages
packages:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Kind test packages"
	@cat $(K8S_DIR)/acceptance/ci-inputs/kind_acceptance_test_packages.yaml

.PHONY: acceptance
acceptance: acceptance/partitions  ## acceptance help

.PHONY: create-cluster/%
create-cluster/%:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Creating Kind cluster $(*)"
	@kind create cluster --config=kind.config --image kindest/node:${KIND_VERSION} --name=$(*)

.PHONY: create-clusters
create-clusters: create-cluster/dc1 create-cluster/dc2

.PHONY: delete-cluster/%
delete-cluster/%:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Deleting Kind cluster $(*)"
	@kind delete cluster --name $(*)

.PHONY: delete-clusters
delete-clusters: delete-cluster/dc1 delete-cluster/dc2 delete-cluster/dc3 delete-cluster/dc4

.PHONY:
help: ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: all
all: delete-clusters build-k8s create-clusters pull load deploy-consul wait deploy-static
