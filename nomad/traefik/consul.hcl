datacenter = "dc1"
node_name = "host01"

addresses {
    http = "{{ GetInterfaceIP \"docker0\" }}"
}
