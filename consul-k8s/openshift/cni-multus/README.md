## OpenShift with Multus


This demo directory attempts to run OpenShift locally using CodeReady Containers (CRC).

# References

[HashiCorp Developer: Deploy Consul on RedHat OpenShift](https://developer.hashicorp.com/consul/tutorials/kubernetes/kubernetes-openshift-red-hat)
[Getting started with Red Hat CodeReady Containers](https://access.redhat.com/documentation/en-us/red_hat_codeready_containers/1.0/html/getting_started_guide/getting-started-with-codeready-containers_gsg)
Reference: [Install OpenShift on Azure](https://gist.github.com/david-yu/9a636d909bc45efe072968c37dc8c615)


# Setup

- Download the crc binary (link above)
- Run `crc setup` (this will take a while to download images)
- Make sure to get a pull secret from Redhat. You need to register a personal account and [download](https://console.redhat.com/openshift/create/local) the pull secret. The Makefile assumes that you save the 'pull-secret' file to ~/Downloads.
- Run `crc start` (this will take a while to start many operators)
- Login `make login` to get login credentials and login as 'admin'
- Build the consul-k8s image `make build`
- Deploy consul with `make deploy-consul`
