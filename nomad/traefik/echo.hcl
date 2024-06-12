
job "echo" {
  datacenters = ["dc1"]
  type = "service"

  group "apis" {
    count = 3

    update {
      max_parallel = 1
      canary = 1
    }
    network {
      port  "http" {
        to = -1
      }
    }

    task "echo" {
      driver = "docker"

      config {
        image = "ghcr.io/curtbushko/demo-webapp:v2"

        ports = ["http"]
      }

      env {
        PORT    = "${NOMAD_PORT_http}"
        NODE_IP = "${NOMAD_IP_http}"
      }

      service {
        name = "echo-canary"
        port = "http"

        tags = []
        canary_tags = [
          "traefik.enable=true",
          "traefik.http.routers.http.rule=Path(`/myapp`)",
          "traefik.http.routers.http.rule=Headers: Canary,true"
        ]

        check {
          type = "http"
          path = "/"
          interval = "5s"
          timeout = "1s"
        }
      }

      service {
        name = "echo"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.http.routers.http.rule=Path(`/myapp`)",
        ]
        canary_tags = [
          "traefik.enable=false"
        ]

        check {
          type = "http"
          path = "/"
          interval = "5s"
          timeout = "1s"
        }
      }
    }
  }
}
