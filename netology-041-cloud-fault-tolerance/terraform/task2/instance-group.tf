data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_compute_instance_group" "web" {
  name               = "netology-041-web-group"
  service_account_id = var.service_account_id

  instance_template {
    name     = "netology-041-group-{instance.index}"
    hostname = "netology-041-group-{instance.index}"

    platform_id = var.platform_id

    resources {
      cores         = var.vm_resources.cores
      memory        = var.vm_resources.memory
      core_fraction = var.vm_resources.core_fraction
    }

    boot_disk {
      mode = "READ_WRITE"

      initialize_params {
        image_id = data.yandex_compute_image.ubuntu.id
        size     = var.vm_resources.disk_size
        type     = var.vm_resources.disk_type
      }
    }

    network_interface {
      network_id         = yandex_vpc_network.main.id
      subnet_ids         = [yandex_vpc_subnet.main.id]
      nat                = true
      security_group_ids = [yandex_vpc_security_group.web.id]
    }

    scheduling_policy {
      preemptible = var.preemptible
    }

    metadata = {
      user-data = file("${path.module}/templates/nginx-cloud-init.yml")
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    zones = [var.zone]
  }

  deploy_policy {
    max_unavailable = 1
    max_expansion   = 0
  }

  load_balancer {
    target_group_name        = "netology-041-task2-target-group"
    target_group_description = "Target group created by Compute Instance Group"
  }
}
