HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
DOCKERHUB=curtbushko
GIT_REV=$(shell cd $(K8S_DIR) && git rev-parse --short HEAD)
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:$(GIT_REV)
CONSUL_IMAGE=hashicorp/consul:1.18.0-ubi
CONSUL_DATAPLANE_IMAGE=hashicorp/consul-dataplane:1.4.0-ubi
GOLANG_VERSION?=$(shell cd $(K8S_DIR) && head -n 1 .go-version)
CURRENT_CONTEXT?=$(shell kubectl config current-context)

CUR_DIR=$(shell pwd)

rev:
	echo "Gitrev: $(GIT_REV)"

build:
	touch $(K8S_DIR)/control-plane/LICENSE
	cd $(K8S_DIR)/control-plane && mkdir -p dist/linux/amd64 && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/amd64/consul-k8s-control-plane .
	cd $(K8S_DIR)/control-plane && mkdir -p dist/linux/arm64 && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o dist/linux/arm64/consul-k8s-control-plane .
	cd $(K8S_DIR)/control-plane && mkdir -p dist/cni/linux/amd64 && cd cni && GOARCH=amd64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o ../dist/cni/linux/amd64/consul-cni .
	cd $(K8S_DIR)/control-plane && mkdir -p dist/cni/linux/arm64 && cd cni && GOARCH=arm64 GOOS=linux CGO_ENABLED=0 go build -trimpath -buildvcs=false -ldflags="$(GOLDFLAGS)" -o ../dist/cni/linux/arm64/consul-cni .
	cd $(K8S_DIR)/control-plane && docker buildx create --use && docker buildx build -t '$(DOCKERHUB)/$(CONSUL_K8S_IMAGE)' \
       --platform linux/amd64,linux/arm64 \
       --build-arg 'GOLANG_VERSION=$(GOLANG_VERSION)' \
       --build-arg 'BIN_NAME=consul-k8s-control-plane' \
       --target=ubi \
       --push \
       -f $(K8S_DIR)/control-plane/Dockerfile $(K8S_DIR)/control-plane
	rm $(K8S_DIR)/control-plane/LICENSE

start:
	@crc start -m 18432

stop:
	@crc stop

login:
	@eval $(crc oc-env)
	@echo "Login using the kubeadmin credentials below:"
	@crc console --credentials

create-pull-secret:
	oc new-project consul || true
	kubectl create secret generic openshift-pull-secret \
		--from-file=.dockerconfigjson=${HOME}/Downloads/pull-secret \
		--type=kubernetes.io/dockerconfigjson \
		--namespace=default

deploy-consul: create-pull-secret
	kubectl ns consul || true
	cd $(HELM_CHART_DIR) && helm install consul -n consul -f $(CUR_DIR)/helm.values.yaml \
		--set global.imageK8S=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		--set global.image=$(CONSUL_IMAGE) \
		--set global.imageConsulDataplane=$(CONSUL_DATAPLANE_IMAGE) \
		--set fullnameOverride=consul \
		${K8S_DIR}/charts/consul

deploy-static:
	kubectl create ns static || true
	kubectl ns static || true
	kubectl apply -f cni-networkattachmentdefinition.yaml || true
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

delete-static:
	kubectl delete -f static-server.yaml -n static
	kubectl delete -f static-client.yaml -n static

acceptance:
	oc new-project consul || true
	kubectl ns consul || true
	#kubectl apply -f cni-networkattachmentdefinition.yaml || true
	kubectl create secret generic openshift-pull-secret \
		--from-file=.dockerconfigjson=${HOME}/Downloads/pull-secret \
		--type=kubernetes.io/dockerconfigjson \
		--namespace=consul
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && \
		go test -run TestConnectInject -v -p 1 -timeout 20m \
		-kube-contexts "$(CURRENT_CONTEXT)" \
		-enable-openshift \
		-enable-transparent-proxy \
		-enable-enterprise \
		-enable-cni \
		-kube-namespaces "consul" \
		-consul-k8s-image "$(DOCKERHUB)/$(CONSUL_K8S_IMAGE)" \
		-consul-image "$(CONSUL_IMAGE)" \
		-consul-dataplane-image "$(CONSUL_DATAPLANE_IMAGE)"

acceptance-api-gateway:
	oc new-project consul || true
	kubectl ns consul || true
	#kubectl apply -f cni-networkattachmentdefinition.yaml || true
	kubectl create secret generic openshift-pull-secret \
		--from-file=.dockerconfigjson=${HOME}/Downloads/pull-secret \
		--type=kubernetes.io/dockerconfigjson \
		--namespace=consul
	cd $(ACCEPTANCE_DIR)/acceptance/tests/api-gateway && \
		go test -run TestAPIGateway_KitchenSink -v -p 1 -timeout 20m \
		-kube-contexts "$(CURRENT_CONTEXT)" \
		-enable-openshift \
		-enable-transparent-proxy \
		-enable-enterprise \
		-enable-cni \
		-kube-namespaces "consul" \
		-consul-k8s-image "$(DOCKERHUB)/$(CONSUL_K8S_IMAGE)" \
		-consul-image "$(CONSUL_IMAGE)" \
		-consul-dataplane-image "$(CONSUL_DATAPLANE_IMAGE)"


podstatus:
	kubectl get pods 

wait:
	sleep 20

all: deploy-consul wait deploy-static podstatus

