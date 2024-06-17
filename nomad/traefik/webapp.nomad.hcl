variable "tag" {
  type        = string
  description = "Image tag version, v1, v2, v3 are valid"
}

variable "promote" {
  type        = bool
  default = false
  description = "Whether to auto promote or not"
}

job "demo-webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 2

    update {
      max_parallel     = 1
      canary           = 1
      auto_revert      = true
      auto_promote     = "${var.promote}"
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
        "tag=${var.tag}",
        "traefik.enable=true",
        "traefik.http.routers.demo-webapp.rule=Path(`/myapp`)",
      ]
      canary_tags = [
        "tag=${var.tag}",
        "traefik.enable=true",
        "traefik.http.routers.demo-webapp-canary.rule=Path(`/myapp`) && Header(`canary`,`true`)",
        "traefik.consulcatalog.canary=true",
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
      # A delay allows the service to be deregistered before the task is killed.
      # Addresses gateway timeouts when hammering the server
      shutdown_delay = "10s"
    }
  }
}
