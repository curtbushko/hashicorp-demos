CUR_DIR=$(shell pwd)

# Policies are needed 
POLICY_SCOPE=$(az group show --name 'PolicyLab' --output tsv --query id)
SKU_POLICY='{ "listOfAllowedSKUs": { "value": ["Standard_D2s_v3", "Standard_D4s_v3", "Standard_DS1_v2", "Standard_DS2_v2"]}}'
POLICY_DEFINITION_ID='cccc23c7-8427-4f53-ad12-b6a63eb452b3'

azlogin:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Logging into Azure with subscription: $(ARM_SUBSCRIPTION_ID) in tenant: $(ARM_TENANT_ID)" 
ifndef ARM_SUBSCRIPTION_ID 
	$(error ARM_SUBSCRIPTION_ID is required)
endif
ifndef ARM_TENANT_ID 
	$(error ARM_TENANT_ID is required)
endif
	az account set --subscription $(ARM_SUBSCRIPTION_ID)
	az login --tenant $(ARM_TENANT_ID) --allow-no-subscriptions

register:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Registering Redhat OpenShift provider with Azure Tenant" 
	az provider register --namespace "Microsoft.RedHatOpenShift"
	az provider register --namespace "Microsoft.PolicyInsights"

show-registrations:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Show Redhat OpenShift and PolicyInsights provider states. Might need to wait a bit" 
	az provider show -n "Microsoft.RedHatOpenShift" |grep registrationState
	az provider show -n "Microsoft.PolicyInsights" |grep registrationState

create-resource-group:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Create consul-k8s-RG resource group"
	az group create -l westus -n consul-k8s-RG

vars:
	echo $(POLICY_SCOPE)

create-sku-policy:
	@echo "[`date -u +'%Y-%m-%dT%H:%M:%SZ'`] Create SKU policy so that OpenShift can create VMs"
	az policy assignment create --name 'consul-k8s-openshift: Allowed Virtual Machine SKUs' --display-name 'consul-k8s-openshift: Allowed Virtual Machine SKUs' --scope '/subscriptions/$(ARM_SUBSCRIPTION_ID)/resourcegroups/consul-k8s-RG' --policy $(POLICY_DEFINITION_ID) --params $(SKU_POLICY) --output jsonc

init:
ifndef K8S_DIR 
	$(error K8S_DIR is required)
endif
	cd $(K8S_DIR)/charts/consul/test/terraform/openshift && terraform init

plan:
ifndef K8S_DIR 
	$(error K8S_DIR is required)
endif
	cd $(K8S_DIR)/charts/consul/test/terraform/openshift && terraform plan

apply:
ifndef K8S_DIR 
	$(error K8S_DIR is required)
endif
	cd $(K8S_DIR)/charts/consul/test/terraform/openshift && terraform apply -y

acceptance:

