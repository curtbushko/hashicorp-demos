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
	@NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -detach -var="tag=v1" webapp.nomad.hcl

.PHONY: run-webapp-v2
run-webapp-v2:
	@NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -detach -var="tag=v2" webapp.nomad.hcl

.PHONY: run-webapp-v3
run-webapp-v3:
	@NOMAD_ADDR=http://${DARWIN_IP}:4646 nomad run -detach -var="tag=v3" webapp.nomad.hcl

.PHONY: curl
curl:
	@n=0; \
    while [ $${n} -lt 5 ] ; do \
    	curl -s --connect-timeout 1 http://${DARWIN_IP}:8080/myapp | gum style --border normal --margin "0 0" --padding "0 1" --border-foreground=#FFD814; \
	    sleep 2; \
    	n=`expr $$n + 1`; \
    done; \
    true

.PHONY: canary-curl
canary-curl:
	@n=0; \
    while [ $${n} -lt 5 ] ; do \
    	curl -s --connect-timeout 1 http://${DARWIN_IP}:8080/myapp -H 'canary:true' | gum style --border normal --margin "0 0" --padding "0 1" --border-foreground=#FFD814; \
	    sleep 2; \
    	n=`expr $$n + 1`; \
    done; \
    true

.PHONY: promote
promote:
	@nomad job promote -detach demo-webapp || true


.PHONY: purge
purge:
	@nomad job stop -detach -purge demo-webapp || true

.PHONY: demo
demo:
	@echo "Canary deploys in a local setup. \n\n \
In this demo we start with a nomad cluster with only traefik running for load balancing. We then deploy a v1 demo webapp and send traffic to it using curl to verify that it is working. \n \
We then canary deploy a v2 version of the demo web app. We curl and it should only show traffic going to the v1 webapp. \n \
To send traffic to the v2 webapp we will need to use a header (canary: true). \n\n \
This shows us traffic splitting. Normal traffic goes to v1 demoapp while specific canary traffic goes to v2 demoapp. \n \
We then promote the canary deployment manually and the demo webapp becomes v2. \n \
" | gum style --border normal --margin "1" --padding "2 2" --border-foreground=#E03875
	@sleep 7

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "What jobs does nomad have running? Should only show traefik. $(shell gum style --foreground=#00CA8E '(command: nomad job status)')" --show-output -- sleep 2
	@sleep 3
	@nomad job status | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Deploy $(shell gum style --foreground=#00CA8E 'v1') of demo app. Takes a bit of time... $(shell gum style --foreground=#00CA8E '(command: nomad run -detach -var="tag=v1" webapp.nomad.hcl)')" --show-output -- sleep 2
	@make run-webapp-v1 | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E
	@sleep 12

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Check job status. Should show 2 jobs. $(shell gum style --foreground=#00CA8E '(command: nomad job status demo-webapp)')" --show-output -- sleep 2
	@nomad job status | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E
	@sleep 2
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Curl $(shell gum style --foreground=#00CA8E 'v1') endpoint. Should return welcome v1 message. $(shell gum style --foreground=#FFD814 '(command: curl http://<local ip>:8080/myapp)')" --show-output -- sleep 2
	@make curl

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Deploy $(shell gum style --foreground=#00CA8E 'v2') of demo app. $(shell gum style --foreground=#00CA8E '(command: nomad run -detach -var="tag=v2" webapp.nomad.hcl)')" --show-output -- sleep 2
	@make run-webapp-v2 | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E
	@sleep 5
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Check job status. $(shell gum style --foreground=#00CA8E '(command: nomad job status demo-webapp)')" --show-output -- sleep 5
	@nomad job status | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Curl $(shell gum style --foreground=#00CA8E 'v1') endpoint. Should show welcome v1 message as traffic is going to the original v1 container. $(shell gum style --foreground=#FFD814 '(command: curl http://<local ip>:8080/myapp)')" --show-output -- sleep 2
	@make curl
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Curl $(shell gum style --foreground=#00CA8E 'v2') endpoint with Header. Should show welcome v2 message as traffic is only going to v2 container. $(shell gum style --foreground=#FFD814 '(command: curl http://<local ip>:8080/myapp -H 'canary: true')')" --show-output -- sleep 2
	@make canary-curl

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Notice how traffic is now splitting between two containers." --show-output -- sleep 5
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Promote the $(shell gum style --foreground=#00CA8E 'v2') canary deploy. The v1 container should go away while v2 takes its place. $(shell gum style --foreground=#00CA8E '(command: nomad job promote demo-webapp)')" --show-output -- sleep 2
	@make promote | gum style --border normal --margin "1" --padding "1 1" --border-foreground=#00CA8E
	@sleep 10

	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Curl $(shell gum style --foreground=#00CA8E 'v1') endpoint. Should return welcome v2 message. $(shell gum style --foreground=#FFD814 '(command: curl http://<local ip>:8080/myapp)')" --show-output -- sleep 2
	@make curl
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Curl $(shell gum style --foreground=#00CA8E 'v2') endpoint with Header. Should return welcome v2 message as only the v2 container exists now. $(shell gum style --foreground=#FFD814 '(command: curl http://<local ip>:8080/myapp -H 'canary: true')')" --show-output -- sleep 2
	@make canary-curl
	@gum spin --spinner dot --spinner.foreground=#E03875 --title "Fini." --show-output -- sleep 5

.PHONY:build-webapp
build-webapp:
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v1 -t "${WEBAPP_IMAGE}:v1" --platform linux/amd64,linux/arm64 --push .
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v2 -t "${WEBAPP_IMAGE}:v2" --platform linux/amd64,linux/arm64 --push .
	@cd demo-webapp && docker buildx build --build-arg DOCKER_TAG=v3 -t "${WEBAPP_IMAGE}:v3" --platform linux/amd64,linux/arm64 --push .

