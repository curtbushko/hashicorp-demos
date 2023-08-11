CUR_DIR=$(shell pwd)
WORKTREE=curtbushko/net-4884-tgw-partitions
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul-enterprise/$(WORKTREE)
INTEGRATION_TEST_DIR=gateways
CONSUL_COMPAT_TEST_IMAGE=hashicorp/consul-enterprise

.PHONY: build 
build:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image"
	@docker context use default
	@cd $(CONSUL_DIR) && make dev-docker

.PHONY: integration-setup
integration-setup:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running test-compat-integ-setup in $(CONSUL_DIR)"
	@cd $(CONSUL_DIR) && make test-compat-integ-setup

.PHONY: integration
integration:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running integration tests for $(INTEGRATION_TEST_DIR)"
	@cd $(CONSUL_DIR)/test/integration/consul-container/test/$(INTEGRATION_TEST_DIR) && \
		go test -run TestTerminatingGatewayBasic -v -timeout=2m  \
		--target-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--target-version local \
		--latest-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--latest-version latest
