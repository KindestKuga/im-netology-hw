data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  instances = {
    bastion = {
      name              = "netology-032-bastion"
      hostname          = "bastion"
      subnet_id         = yandex_vpc_subnet.public.id
      ip_address        = "10.32.10.10"
      nat               = true
      security_group_id = yandex_vpc_security_group.bastion.id
    }

    web-a = {
      name              = "netology-032-web-a"
      hostname          = "web-a"
      subnet_id         = yandex_vpc_subnet.private.id
      ip_address        = "10.32.20.21"
      nat               = false
      security_group_id = yandex_vpc_security_group.web.id
    }

    web-b = {
      name              = "netology-032-web-b"
      hostname          = "web-b"
      subnet_id         = yandex_vpc_subnet.private.id
      ip_address        = "10.32.20.22"
      nat               = false
      security_group_id = yandex_vpc_security_group.web.id
    }

    db = {
      name              = "netology-032-db"
      hostname          = "db"
      subnet_id         = yandex_vpc_subnet.private.id
      ip_address        = "10.32.20.31"
      nat               = false
      security_group_id = yandex_vpc_security_group.db.id
    }
  }
}

resource "yandex_compute_instance" "vm" {
  for_each = local.instances

  name        = each.value.name
  hostname    = each.value.hostname
  platform_id = var.platform_id
  zone        = var.zone
  labels      = merge(var.common_labels, { role = each.key })

  allow_stopping_for_update = true

  resources {
    cores         = var.vm_resources.cores
    memory        = var.vm_resources.memory
    core_fraction = var.vm_resources.core_fraction
  }

  boot_disk {
    auto_delete = true

    initialize_params {
      name     = "${each.value.name}-boot"
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_resources.disk_size
      type     = var.vm_resources.disk_type
    }
  }

  network_interface {
    subnet_id          = each.value.subnet_id
    ip_address         = each.value.ip_address
    nat                = each.value.nat
    security_group_ids = [each.value.security_group_id]
  }

  scheduling_policy {
    preemptible = var.preemptible
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yml", {
      vm_user        = var.vm_user
      ssh_public_key = local.ssh_public_key
    })
  }
}
