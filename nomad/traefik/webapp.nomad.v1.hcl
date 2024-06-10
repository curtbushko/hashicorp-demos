
job "demo-webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3

    update {
      max_parallel     = 1
      canary           = 3
      auto_revert      = true
      auto_promote     = false
    }

    network {
      port  "http"{
        to = -1
      }
    }

    service {
      name = "demo-webapp"
      port = "http"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Path(`/myapp`)",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    task "server" {
      driver = "docker"
      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }
      config {
        image = "ghcr.io/curtbushko/demo-webapp:v1"
        ports = ["http"]
      }
    }
  }
}
