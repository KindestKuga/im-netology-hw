resource "yandex_lb_target_group" "web" {
  name = "netology-041-target-group"

  target {
    subnet_id = yandex_vpc_subnet.main.id
    address   = yandex_compute_instance.web[0].network_interface[0].ip_address
  }

  target {
    subnet_id = yandex_vpc_subnet.main.id
    address   = yandex_compute_instance.web[1].network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "web" {
  name = "netology-041-nlb"

  listener {
    name        = "http"
    port        = 80
    target_port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.web.id

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
