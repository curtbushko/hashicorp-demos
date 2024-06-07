OS := $(shell uname | tr '[:upper:]' '[:lower:]')
HOSTNAME := $(shell hostname |tr '[:upper:]' '[:lower:]')
TMPDIR = $(CURDIR)/tmp
NOMAD_ADDR = http://localhost:4646

.PHONY: start-consul
start-consul:
ifeq ($(OS), darwin)
	consul agent -dev -config-file consul.hcl.darwin
else
	sudo consul agent -dev -config-file consul.hcl.linux
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
	mkdir -p $(TMPDIR)/nomad-data/alloc
	nomad agent -dev \
	-consul-address '10.0.0.63:8500'  \
	-network-interface '{{GetDefaultInterfaces | attr "name"}}' \
	-data-dir=$(TMPDIR)/nomad-data \
	-bind 0.0.0.0
	@echo "In another shell run: export NOMAD_ADDR=http://localhost:4646"

.PHONY: stop-nomad
stop-nomad:
	@echo "Stopping nomad"
	kill -9 $(shell ps -ef | grep 'nomad' | grep -v grep | cut -d' ' -f4)
	@echo "Listing running nomad (should not show anything)"
	@ps -ef | grep 'nomad' | grep -v grep || true

.PHONY: run-traefik
run-traefik:
	nomad run traefik.nomad.hcl

.PHONY: run-webapp
run-webapp:
	nomad run webapp.nomad.hcl
