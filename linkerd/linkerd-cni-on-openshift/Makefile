CUR_DIR=$(shell pwd)
GIT_REV=$(shell cd $(CNI_DIR) && git rev-parse --short HEAD)
EXPIRY=$(shell date -v+8760H +"%Y-%m-%dT%H:%M:%SZ")

deploy-linkerd: deploy-cni deploy-control-plane generate-certs helm-install

deploy-cni:
	kubectl delete ClusterRoleBinding linkerd-cni || true
	kubectl delete ClusterRole linkerd-cni || true
	oc new-project linkerd-cni || true
	kubectl ns linkerd-cni
	oc annotate ns linkerd-cni linkerd.io/inject=disabled || true
	oc adm policy add-scc-to-user privileged -z linkerd-cni -n linkerd-cni || true
	oc adm policy add-scc-to-group anyuid system:serviceaccounts:linkerd-cni || true
	helm install linkerd2-cni \
          --set installNamespace=false \
          --set destCNIBinDir=/var/lib/cni/bin \
          --set destCNINetDir=/etc/kubernetes/cni/net.d \
          linkerd/linkerd2-cni

deploy-control-plane:
	oc new-project linkerd || true
	kubectl ns linkerd
	oc annotate ns linkerd linkerd.io/inject=disabled ||true
	oc label ns linkerd linkerd.io/control-plane-ns=linkerd \
           linkerd.io/is-control-plane=true \
           config.linkerd.io/admission-webhooks=disabled || true
	oc adm policy add-scc-to-user privileged -z default -n linkerd || true
	oc adm policy add-scc-to-user privileged -z linkerd-destination -n linkerd || true
	oc adm policy add-scc-to-user privileged -z linkerd-identity -n linkerd || true
	oc adm policy add-scc-to-user privileged -z linkerd-proxy-injector -n linkerd || true
	oc adm policy add-scc-to-user privileged -z linkerd-heartbeat -n linkerd || true

generate-certs:
	mkdir -p certs
	step certificate create root.linkerd.cluster.local certs/ca.crt certs/ca.key \
          --profile root-ca --no-password --insecure
	step certificate create identity.linkerd.cluster.local certs/issuer.crt certs/issuer.key \
          --profile intermediate-ca --not-after 8760h --no-password --insecure \
          --ca certs/ca.crt --ca-key certs/ca.key

helm-install:
	kubectl ns linkerd
	helm install linkerd2 \
          --set cniEnabled=true \
          --set installNamespace=false \
          --set-file identityTrustAnchorsPEM=certs/ca.crt \
          --set-file identity.issuer.tls.crtPEM=certs/issuer.crt \
          --set-file identity.issuer.tls.keyPEM=certs/issuer.key \
          --set identity.issuer.crtExpiry=$(EXPIRY) \
          linkerd/linkerd2

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

wait:
	sleep 60 

all: deploy-linkerd wait deploy-static

