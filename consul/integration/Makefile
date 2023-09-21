CUR_DIR=$(shell pwd)
WORKTREE=curtbushko/net-4884-tgw-partitions
CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/consul-enterprise/$(WORKTREE)
#CONSUL_DIR=$(HOME)/workspace/github.com/hashicorp/sync/consul-enterprise
INTEGRATION_TEST_DIR=gateways
CONSUL_COMPAT_TEST_IMAGE=hashicorp/consul-enterprise

.PHONY: build 
build:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Building consul image"
	@docker context use default
	@cd $(CONSUL_DIR) && GOTAGS='consulent' make dev-docker

.PHONY: integration-setup
integration-setup:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running test-compat-integ-setup in $(CONSUL_DIR)"
	@docker context use default
	@cd $(CONSUL_DIR) && GOTAGS='consulent' make test-compat-integ-setup
	@docker tag consul-envoy:target-version consul-envoy:latest-version
	@docker tag hashicorp/consul-enterprise:local hashicorp/consul-enterprise:latest

.PHONY: integration
integration:
	@echo "-----------------------------------------------------------------------------------------------------"
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running integration tests for $(INTEGRATION_TEST_DIR)"
	@echo "-----------------------------------------------------------------------------------------------------"
	@cd $(CONSUL_DIR)/test/integration/consul-container/test/$(INTEGRATION_TEST_DIR) && \
		go test -run TestTerminatingGateway* -v -timeout=2m  \
		--target-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--target-version local \
		--latest-image $(CONSUL_COMPAT_TEST_IMAGE) \
		--latest-version latest \
		--tags consulent

.PHONY: bats

	#make test-envoy-integ GO_TEST_FLAGS="-run TestEnvoy/case-ent-terminating-gateway-namespaces"
bats:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Running bats test in $(CONSUL_DIR)"
	@cd $(CONSUL_DIR) && \
	make test-envoy-integ GO_TEST_FLAGS="-run TestEnvoy/case-ent-terminating-gateway-namespaces"
