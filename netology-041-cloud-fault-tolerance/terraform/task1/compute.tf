data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

resource "yandex_compute_instance" "web" {
  count = 2

  name        = "netology-041-web-${count.index + 1}"
  hostname    = "netology-041-web-${count.index + 1}"
  platform_id = var.platform_id
  zone        = var.zone

  allow_stopping_for_update = true

  resources {
    cores         = var.vm_resources.cores
    memory        = var.vm_resources.memory
    core_fraction = var.vm_resources.core_fraction
  }

  boot_disk {
    auto_delete = true

    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_resources.disk_size
      type     = var.vm_resources.disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.main.id
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
