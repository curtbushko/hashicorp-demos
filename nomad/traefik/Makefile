OS := $(shell uname | tr '[:upper:]' '[:lower:]')
HOSTNAME := $(shell hostname |tr '[:upper:]' '[:lower:]')
TMPDIR = $(CURDIR)/tmp
NOMAD_ADDR = http://localhost:4646
DARWIN_IP=$(shell ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2 )
LINUX_IP=$(shell ifconfig eno1 | grep inet | grep -v inet6 | cut -d ' ' -f2 )

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
	-consul-address '$(DARWIN_IP):8500'  \
	-network-interface '{{GetDefaultInterfaces | attr "name"}}' \
	-data-dir=$(TMPDIR)/nomad-data \
	-bind 0.0.0.0
else
	sudo nomad agent -dev \
	-consul-address '$(LINUX_IP):8500'  \
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
ifeq ($(OS), darwin)
	export TRAEFIK_ADDR=$(ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2)
else
	export TRAEFIK_ADDR=$(ifconfig eno1 | grep inet | grep -v inet6 | cut -d ' ' -f2)
endif
	nomad run traefik.nomad.hcl

.PHONY: run-webapp
run-webapp:
	nomad run webapp.nomad.hcl
