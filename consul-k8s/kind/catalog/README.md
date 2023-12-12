Used in the case where services were being left behind in the consul catalog.


From the PR to fix this:
- In the past, kubernetes nodes were used as the source of truth to determine the list of services that should exist in Consul.
- In most cases this was ok but becomes a problem when nodes are quickly deleted from kubernetes such as the case when using spot instances.
- Instead, use consul synthetic-nodes to get the list of services and deregister the services that do not have endpoint addresses.

To reproduce:
- Created a multi-node kind cluster, deployed several static apps to it with a nodeSelector and deleted nodes.
- When the node is deleted, endpoints controller detects an endpoint change and deregisters
- Adding the node back re-registers the service
- Note: You can simulate node deletions using a combination of kubectl delete node + docker stop <image>. docker start <image> will re-register the node.
