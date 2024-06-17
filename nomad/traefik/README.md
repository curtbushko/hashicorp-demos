# Demo

Start dameons (in separate shells!)
```shell
make start-consul
make start-nomad
```

Consul is available at http://localhost:8500
Nomad at http://localhost:4646

Launch jobs
```shell
make start-traefik
```
Traefix is bound to http://localhost:8081 (for admin) and http://localhost:8080 (for webapp)

Launch webapp
```shell
make start-webapp-v1
```
Note: launching the same version will be automatically updated! 

```shell
make start-webapp-v2
```

Decision:
```shell
nomad deployment promote <deployment id>
nomad deployment fail <deployment id>
```

# FAQ

- Q: Containers are starting with IPv6 addresses on Mac.
- A: Your mac is returning what it things is the default ip address for your wireless network interface. To fix, System
  Settings -> Search for 'ipv6' -> Click on IPv6 -> TCPIP -> Configure IPv6 -> Change to 'Link-local Only'.
