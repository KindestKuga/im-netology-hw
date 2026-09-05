resource "yandex_lb_network_load_balancer" "web" {
  name = "netology-041-task2-nlb"

  listener {
    name        = "http"
    port        = 80
    target_port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_compute_instance_group.web.load_balancer[0].target_group_id

    healthcheck {
      name                = "http"
      interval            = 2
      timeout             = 1
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
