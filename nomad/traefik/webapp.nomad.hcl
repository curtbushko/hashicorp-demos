
job "demo-webapp" {
  datacenters = ["dc1"]

  group "demo" {
    count = 3

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
        image = "hashicorp/demo-webapp-lb-guide"
        ports = ["http"]
        volumes = [
                    # Use absolute paths to mount arbitrary paths on the host
                    "/path/on/host:/path/in/container",
        ]
      }
    }
  }
}
