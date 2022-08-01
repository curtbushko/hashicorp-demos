# cni-demo
Makefiles and scripts for using consul-cni plugin in different environments

# Consul CNI on Kind

Consul CNI on Kind requires that Calico is installed and the Kind pod subnet is set to the same value that Calico is expecting. These settings are located in the consul-cni-on-kind subdirectory.

There are make targets in `consul-cni-on-kind` that make this easier to run.

## To Use:

1) In the Makefile, change the values of HELM_CHART_DIR and CNI_DIR to point to your local repository with your CNI branch.
2) Change DOCKERHUB to match your dockerhub account
3) `make all` will rebuild everything from scratch.
4) There are make targets for each step of `make all` that you can use individually.

`make all` will:
        - delete your kind cluster
        - create a new kind cluster 
        - deploy Calico
        - build a multi-arch re-build of the image, push it to dockerub
        - deploy consul 
        - deploy deploy static server and client
        - change your context to the consul namespace and show the status of the pods

NOTE: All config files are located in the directory.


# Consul CNI on GKE

GKE requires that Network Policy Enforcement be enabled for your cluster. This installs Calico.


1) Turn on Network Policy Enforcement by running one set of the following commands:

For a new cluster, run the command:

`gcloud container clusters create CLUSTER_NAME --enable-network-policy`

For an existing cluster, run the commands:

`gcloud container clusters update CLUSTER_NAME --update-addons=NetworkPolicy=ENABLED`
and
`gcloud container clusters update CLUSTER_NAME --enable-network-policy`

2) In the `consul-cni-on-gke/Makefile` replace the values of HELM_CHART_DIR and CNI_DIR to point to your local repository with your CNI branch.
3) Change DOCKERHUB to match your dockerhub account
4) `make all` will rebuild everything from scratch.
        - delete your consul install 
        - build a multi-arch re-build of the image, push it to dockerub
        - deploy consul 
        - deploy deploy static server and client
        - change your context to the consul namespace and show the status of the pods

5) There are make targets for each step of `make all` that you can use individually.


# Consul on Kind with Local Registry

This tends to be a faster local setup of using kind as it does not pull down all the images on every rebuild of the 
kind cluster.
 
1) In the `consul-cni-on-kind-local-registry/Makefile` replace the values of HELM_CHART_DIR and CNI_DIR to point to
your local repository with your CNI branch. Leave DOCKERHUB set as localhost:5001
2) Run `make pull`. This will pull all of the calico images into your local docker image cache.
3) Run `make all`. This will:
        - create a Kind cluster with a registry container and configure Kind to use that registry.
        - load all of the calico images into Kind.
        - deploy calico.
        - build the control-plane-dev image, tag it with localhost:5001 and push it to the running docker registry on
          your machine.
        - deploy consul.
        - deploy static server and client.
