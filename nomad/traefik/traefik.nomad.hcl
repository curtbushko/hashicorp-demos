variable "consul_address" {
  type        = string
  description = "The address of the consul server."
}

job "traefik" {
  region      = "global"
  datacenters = ["dc1"]
  type        = "service"

  group "traefik" {
    count = 1

    network {
      port "http" {
        static = 8080
      }

      port "traefik" {
        static = 8081
      }
    }

    service {
      name = "traefik"
      provider = "nomad"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image        = "traefik:latest"
        ports = ["http", "traefik"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[log]
  level = "DEBUG"
[entryPoints]
    [entryPoints.http]
    address = ":8080"
    [entryPoints.traefik]
    address = ":8081"

[api]
    dashboard = true
    insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
    prefix           = "traefik"
    exposedByDefault = false
    # Adds `traefik.hcp.name` sourced from: https://github.com/hashicorp/cloud-traefik/blob/main/nomad/traefik.nomad#L401-L407
    # Beware. Typos kill the provider, but not Traefik daemon itself.
    # Also, `foo\n && bar` is a syntax error, where as `foo && \nbar` is not.
    defaultRule      = """\
      PathPrefix(`/{{"{{"}} default (normalize .Name) (index .Labels "traefik.hcp.name") {{"}}"}}`)\
        {{"{{"}} if default false (index .Labels "traefik.consulcatalog.canary") {{"}}"}} \
            && Header(`canary`,`true`)\
        {{"{{"}}end{{"}}"}}\
    """

    [providers.consulCatalog.endpoint]
      address = "${var.consul_address}:8500"
      scheme = "http"

EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}
