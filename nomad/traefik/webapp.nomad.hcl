variable "tag" {
  type        = string
  description = "Image tag version, v1, v2, v3 are valid"
}

job "demo-webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3

    update {
      max_parallel     = 1
      canary           = 1
      auto_revert      = true
      auto_promote     = false
    }

    network {
      port  "http" {
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

      canary_tags = [
        "traefik.enable=false",
      ]

      check {
        type     = "http"
        path     = "/"
        interval = "2s"
        timeout  = "2s"
      }
    }

    service {
      name = "demo-webapp-canary"
      port = "http"

      tags = []

      canary_tags = [
        "traefik.enable=true",
        "traefik.http.routers.http.rule=Path(`/myapp`)",
        "traefik.http.routers.http.rule=Header(`X-Canary`, `true`)",
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
        image = "ghcr.io/curtbushko/demo-webapp:${var.tag}"
        ports = ["http"]
      }
    }
  }
}
