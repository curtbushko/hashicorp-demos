datacenter = "dc1"
node_name = "host01"

bind_addr = "0.0.0.0"

addresses {
  http = "0.0.0.0"
  https = "0.0.0.0"
  grpc = "0.0.0.0"
}

advertise_addr = "{{ GetInterfaceIP \"en0\" }}"
