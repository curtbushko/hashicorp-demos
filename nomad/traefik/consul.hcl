datacenter = "dc1"
node_name = "host01"

addresses {
    http = "127.0.0.1 {{ GetInterfaceIP \"docker0\" }}"
}
