datacenter = "dc1"
node_name = "host01"

bind_addr = "0.0.0.0"

addresses {
    http = "{{ GetInterfaceIP \"en0\" }} {{ GetInterfaceIP \"lo0\" }}"
    https = "{{ GetInterfaceIP \"en0\" }} {{ GetInterfaceIP \"lo0\" }}"
    grpc = "{{ GetInterfaceIP \"en0\" }}"
}

advertise_addr = "{{ GetInterfaceIP \"en0\" }}"
