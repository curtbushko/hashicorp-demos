# Consul-k8s OpenShift

# THIS IS A WORK IN PROGRESS AND ALL EFFORTS TO GET THIS WORKING HAVE STOPPED

The makefile provided in this directory helps you create an OpenShift cluster using terraform.

## Requirements

1) Access to an Azure tenant (Doormat -> Azure -> Request Subscription Access) to hashicorp02
2) A temporary subscription on that tenant (Doormat -> Accounts -> Azure -> Create Temporary Subscription)

Note: Above does not have all of the permissions to create an OpenShift cluster.

## Instructions

1) In a shell, export the environment variables:

    `export ARM_SUBSCRIPTION_ID=`
    `export ARM_TENANT_ID=`

with the values from the approval in Requirements

2) Set, K8S_DIR with the directory of the consul-k8s repository that you are testing against


