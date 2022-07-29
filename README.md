# cni-demo
Makefiles and scripts for using consul-cni plugin in different environments

# Consul CNI on KiND

Consul CNI on KiND requires that Calico is installed and the KiND pod subnet is set to the same value that Calico is expecting. These settings are located in the consul-cni-on-kind subdirectory.

There are make targets in `consul-cni-on-kind` that make this easier to run.

## To Use:

1) In the Makefile, chang0e the values of HELM_CHART_DIR and CNI_DIR to point to your local repository with your CNI branch.
2) Replace `curtbushko` with the name of your Dockerhub repo.
3) `make all` will rebuild everything from scratch.
4) There are make targets for each step of `make all` that you can use individually.

`make all` will:
        - delete your kind cluster
        - create a new kind cluster 
        - deploy Calico
        - build a multi-arch re-build of the image, push it to dockerub
        - deploy consul 
        - deploy hashicups
        - change your context to the consul namespace and show the status of the pods

NOTE: All config files are located in the directory.


# Consul CNI on GKE

GKE requires that Network Policy Enforcement be enabled for your cluster. This installs Calico.


1) Turn on Network Policy Enforcement by running one set of the following commands:

## For a new cluster, run the command:

`gcloud container clusters create CLUSTER_NAME --enable-network-policy`

## For an existing cluster, run the commands:

`gcloud container clusters update CLUSTER_NAME --update-addons=NetworkPolicy=ENABLED`
and
`gcloud container clusters update CLUSTER_NAME --enable-network-policy`

2) In the `consul-cni-on-gke/Makefile` replace the values of HELM_CHART_DIR and CNI_DIR to point to your local repository with your CNI branch.
3) Replace `curtbushko` with the name of your Dockerhub repo.
4) `make all` will rebuild everything from scratch.
        - delete your consul install 
        - build a multi-arch re-build of the image, push it to dockerub
        - deploy consul 
        - deploy hashicups
        - change your context to the consul namespace and show the status of the pods

5) There are make targets for each step of `make all` that you can use individually.

