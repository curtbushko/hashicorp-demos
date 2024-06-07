datacenter = "dc1"
node_name = "host01"

bind_addr = "0.0.0.0"

addresses {
    http = "{{ GetInterfaceIP \"eno1\" }} {{ GetInterfaceIP \"lo0\" }}"
    https = "{{ GetInterfaceIP \"eno1\" }} {{ GetInterfaceIP \"lo0\" }}"
    grpc = "{{ GetInterfaceIP \"eno1\" }}"
}

advertise_addr = "{{ GetInterfaceIP \"eno1\" }}"
