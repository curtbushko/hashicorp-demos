HELM_CHART_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
CNI_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
ACCEPTANCE_DIR=$(HOME)/workspace/github.com/hashicorp/consul-k8s
#DOCKERHUB=registry.connect.redhat.com
DOCKERHUB=curtbushko
DOCKERHUB2=registry.connect.redhat.com
CONSUL_IMAGE=hashicorp/consul:1.13.1-ubi
#CONSUL_K8S_IMAGE=hashicorp/consul-k8s-control-plane:0.48.0-ubi
CONSUL_K8S_IMAGE=consul-k8s-control-plane-dev:latest

CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)

load:
	oc import-image $(CONSUL_IMAGE) --from=$(DOCKERHUB2)/$(CONSUL_IMAGE) --confirm
	oc import-image $(CONSUL_K8S_IMAGE) --from=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) --confirm

deploy-consul:
	cd $(HELM_CHART_DIR) && helm install consul -n consul -f $(CUR_DIR)/helm.values.yaml \
		--set global.imageK8S=$(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		--set global.image=$(DOCKERHUB2)/$(CONSUL_IMAGE) \
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
		-consul-k8s-image $(DOCKERHUB)/$(CONSUL_K8S_IMAGE) \
		-consul-image $(DOCKERHUB)/$(CONSUL_IMAGE)

acceptance-no-cleanup:
	cd $(ACCEPTANCE_DIR)/acceptance/tests/connect && go test -run TestConnectInjectNamespace -v -p 1 -timeout 20m \
		-use-kind \
		-enable-enterprise \
		-kubecontext="kind-dc1" \
		-secondary-kubecontext="kind-dc2" \
		-enable-transparent-proxy \
		-enable-cni \
		-consul-k8s-image $(DOCKERHUB)/$(DOCKER_IMAGE) \
		-consul-image $(DOCKERHUB)/$(CONSUL_IMAGE) \
		-no-cleanup-on-failure

deploy-static:
	oc new-project static || true
	oc adm policy add-scc-to-group anyuid system:serviceaccounts:static || true
	oc annotate ns static consu.hashicorp.com/connect-inject=true || true
	kubectl ns static
	kubectl apply -f static-server.yaml -n static
	kubectl apply -f static-client.yaml -n static

delete-static:
	kubectl delete -f static-server.yaml -n static
	kubectl delete -f static-client.yaml -n static

deploy-linkerd:
	kubectl delete ClusterRoleBinding linkerd-cni || true
	kubectl delete ClusterRole linkerd-cni || true
	oc new-project linkerd-cni || true
	oc annotate ns linkerd-cni linkerd.io/inject=disabled || true
	oc adm policy add-scc-to-user privileged -z linkerd-cni -n linkerd-cni || true
	oc adm policy add-scc-to-group anyuid system:serviceaccounts:linkerd-cni || true
	helm install linkerd2-cni \
          --set installNamespace=false \
          --set destCNIBinDir=/var/lib/cni/bin \
          --set destCNINetDir=/etc/kubernetes/cni/net.d \
          linkerd/linkerd2-cni

podstatus:
	kubectl ns consul 
	kubectl get pods 

wait:
	sleep 60 

all: deploy-consul wait deploy-static podstatus

