HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
DOCKERHUB=curtbushko
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:ubi

CUR_DIR=$(shell pwd)

GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

build:
	cd $(CNI_DIR) && GOARCH=amd64 make control-plane-dev-docker-multi-arch

deploy-consul:
	oc new-project consul || true
	kubectl ns consul || true
	cd $(HELM_CHART_DIR) && helm install consul -n consul -f $(CUR_DIR)/helm.values.yaml \
		--set fullnameOverride=consul \
		./charts/consul

acceptance:
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInject -v -p 1 -timeout 20m \
		-use-kind \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-enterprise \
		-enable-cni \
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE)

deploy-static:
	kubectl create ns static || true
	kubectl ns static || true
	kubectl apply -f cni-networkattachmentdefinition.yaml || true
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

delete-static:
	kubectl delete -f static-server.yaml -n static
	kubectl delete -f static-client.yaml -n static

podstatus:
	kubectl get pods 

wait:
	sleep 20

all: deploy-consul wait deploy-static podstatus

