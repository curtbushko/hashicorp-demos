WEBAPP_IMAGE=ghcr.io/curtbushko/demo-webapp
OS := $(shell uname | tr '[:upper:]' '[:lower:]')
HOSTNAME := $(shell hostname |tr '[:upper:]' '[:lower:]')
TMPDIR = $(CURDIR)/tmp
NOMAD_ADDR = http://localhost:4646
DARWIN_IP=$(shell route -n get default | grep "interface:" | cut -d ' ' -f4 | xargs -n1 ipconfig getifaddr)
LINUX_IP=$(shell route | grep '^default' | tr -s ' ' | cut -d ' ' -f8 | xargs ifconfig |grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

getip:
ifeq ($(OS), darwin)
	@echo "$(DARWIN_IP)"
else
	@echo "$(LINUX_IP)"
endif

.PHONY: start-consul
start-consul:
ifeq ($(OS), darwin)
	consul agent -dev -config-file consul.darwin.hcl
else
	sudo consul agent -dev -config-file consul.linux.hcl
endif

.PHONY: stop-consul
stop-consul:
	@echo "Stopping consul"
	kill -9 $(shell ps -ef | grep 'consul agent' | grep -v grep | cut -d' ' -f4)
	@echo "Listing running consul (should not show anything)"
	@ps -ef | grep 'consul agent' | grep -v grep || true

.PHONY: start-nomad
start-nomad:
	@echo "Starting local Nomad"
	rm -rf $(TMPDIR)/nomad-data
	mkdir -p $(TMPDIR)/nomad-data/alloc
ifeq ($(OS), darwin)
	nomad agent -dev \
	-consul-address '$(DARWIN_IP):8500' \
	-network-interface '{{GetDefaultInterfaces | attr "name"}}' \
	-data-dir=$(TMPDIR)/nomad-data \
	-bind 0.0.0.0
else
	sudo nomad agent -dev \
	-consul-address '$(LINUX_IP):8500' \
	-network-interface '{{GetDefaultInterfaces | attr "name"}}' \
	-data-dir=$(TMPDIR)/nomad-data \
	-bind 0.0.0.0
endif
	@echo "In another shell run: export NOMAD_ADDR=http://localhost:4646"

.PHONY: stop-nomad
stop-nomad:
	@echo "Stopping nomad"
	kill -9 $(shell ps -ef | grep 'nomad' | grep -v grep | cut -d' ' -f4)
	@echo "Listing running nomad (should not show anything)"
	@ps -ef | grep 'nomad' | grep -v grep || true

.PHONY: run-traefik
run-traefik:
	NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -var="consul_address=${DARWIN_IP}" traefik.nomad.hcl

.PHONY: run-webapp-v1
run-webapp-v1:
	NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -var="tag=v1" webapp.nomad.hcl

.PHONY: run-webapp-v2
run-webapp-v2:
	NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -var="tag=v2" webapp.nomad.hcl

.PHONY: run-webapp-v3
run-webapp-v3:
	NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -var="tag=v3" webapp.nomad.hcl

.PHONY: curl
curl:
	@echo "Curl'ing webapp endpoint"
	@while true; do \
		curl http://${DARWIN_IP}:8080/myapp; \
	    sleep 2; \
	    done 

.PHONY: canary-curl
canary-curl:
	@echo "Canary curl'ing webapp endpoint"
	@while true; do \
		curl http://${DARWIN_IP}:8080/myapp -H 'Canary: true'; \
	    sleep 2; \
	    done 


.PHONY:build-webapp
build-webapp:
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v1 -t "${WEBAPP_IMAGE}:v1" --platform linux/amd64,linux/arm64 --push .
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v2 -t "${WEBAPP_IMAGE}:v2" --platform linux/amd64,linux/arm64 --push .
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v3 -t "${WEBAPP_IMAGE}:v3" --platform linux/amd64,linux/arm64 --push .

