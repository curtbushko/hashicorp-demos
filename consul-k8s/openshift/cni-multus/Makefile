#HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/release/1.4.x
#$K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
K8S_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/release/1.4.x
#ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/NET-4414/anyuid-openshift
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s/release/1.4.x
DOCKERHUB=curtbushko
GIT_REV=$(shell cd $(K8S_DIR) && git rev-parse --short HEAD)
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:$(GIT_REV)
#CONSUL_IMAGE=hashicorp/consul:1.18.0-ubi
#CONSUL_IMAGE=registry.connect.redhat.com/hashicorp/consul-enterprise:1.18.2-ent-ubi
CONSUL_IMAGE=hashicorp/consul-enterprise:1.18.2-ent-ubi
#CONSUL_DATAPLANE_IMAGE=hashicorp/consul-dataplane:1.4.0-ubi
#CONSUL_DATAPLANE_IMAGE=registry.connect.redhat.com/hashicorp/consul-dataplane:1.4.2-ubi
CONSUL_DATAPLANE_IMAGE=hashicorp/consul-dataplane:1.4.2-ubi
GOLANG_VERSION?=$(shell cd $(K8S_DIR) && head -n 1 .go-version)
CURRENT_CONTEXT?=$(shell kubectl config current-context)

CUR_DIR=$(shell pwd)

rev:
	echo "Gitrev: $(GIT_REV)"

pull:
	@docker pull $(CONSUL_IMAGE)
	@docker pull $(CONSUL_DATAPLANE_IMAGE)

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
	@echo "Starting crc:"
	@crc start -m 16384 -c 8 ||true

stop:
	@echo "Stopping crc:"
	@crc stop ||true

delete:
	@echo "Deleting crc instance:"
	@crc delete -f ||true

config:
	@crc config set cpus 8
	@crc config set memory 16384
	@crc config set pull-secret-file ${HOME}/Downloads/pull-secret

login:
	@eval $(crc oc-env)
	@echo "Login using the kubeadmin credentials:"
	@crc console --credentials |grep 'kubeadmin' |cut -d \' -f2 |bash

debug:
	@echo "Running debug container to get into node:"
	@oc debug node/crc

create-pull-secret:
	oc new-project consul || true
	kubectl create secret generic openshift-pull-secret \
		--from-file=.dockerconfigjson=${HOME}/Downloads/pull-secret \
		--type=kubernetes.io/dockerconfigjson \
		--namespace=consul || true

create-ent-license:
	@kubectl create secret generic consul-ent-license --from-literal="key=$$CONSUL_ENT_LICENSE" -n consul || true

deploy-consul: create-pull-secret create-ent-license
	kubectl ns consul || true
	cd $(HELM_CHART_DIR) && helm install consul -n consul -f $(CUR_DIR)/helm.values.yaml \
		--set global.enterpriseLicense.secretName="consul-ent-license" \
		--set global.enterpriseLicense.secretKey="key" \
		--set global.imageK8S=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		--set global.image=$(CONSUL_IMAGE) \
		--set global.imageConsulDataplane=$(CONSUL_DATAPLANE_IMAGE) \
		--set fullnameOverride=consul \
		${K8S_DIR}/charts/consul

deploy-fake:
	kubectl create ns fake || true
	kubectl ns fake || true
	kubectl apply -f cni-networkattachmentdefinition.yaml || true
	kubectl apply -f ./fake

curl:
	kubeclt exec 

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
reset: stop delete wait start login deploy-consul wait wait deploy-fake

