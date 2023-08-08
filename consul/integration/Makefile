CUR_DIR=$(shell pwd)
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul-enterprise/curtbushko/net-4884-tgw-partitions
INTEGRATION_TEST_DIR=partitions
CONSUL_COMPAT_TEST_IMAGE=hashicorp/consul-enterprise

.PHONY: build 
build:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image"
	@cd $(CONSUL_DIR) && make dev-docker

.PHONY: integration-setup
integration-setup:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running test-compat-integ-setup in $(CONSUL_DIR)"
	@cd $(CONSUL_DIR) && make test-compat-integ-setup

.PHONY: integration
integration:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running integration tests for $(INTEGRATION_TEST_DIR)"
	@cd $(CONSUL_DIR)/test/integration/consul-container && \
		go test -v -timeout=7m ./test/$(INTEGRATION_TEST_DIR) \
		--target-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--target-version local \
		--latest-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--latest-version latest
