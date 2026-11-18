resource "yandex_vpc_network" "lab_net" {
  name        = "netology-053-vpc"
  description = "Dedicated VPC network for Netology 053 practice lab"
}

resource "yandex_vpc_subnet" "lab_subnet" {
  name           = "netology-053-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.lab_net.id
  v4_cidr_blocks = ["10.10.10.0/24"]
}

resource "yandex_vpc_security_group" "lab_sg" {
  name        = "netology-053-sg"
  description = "Security group restricting ingress to trusted CIDRs and allowing outbound traffic"
  network_id  = yandex_vpc_network.lab_net.id

  ingress {
    protocol       = "TCP"
    description    = "SSH access restricted to trusted operator IP"
    port           = 22
    v4_cidr_blocks = [var.trusted_ssh_cidr]
  }

  dynamic "ingress" {
    for_each = length(var.trusted_app_cidr) > 0 ? [1] : []
    content {
      protocol       = "TCP"
      description    = "Application ingress port 8090 restricted to trusted CIDRs"
      port           = 8090
      v4_cidr_blocks = var.trusted_app_cidr
    }
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic for OS updates and container image pulls"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

resource "yandex_compute_instance" "vm" {
  name        = "netology-053-vm"
  hostname    = "shvirtd-vm"
  platform_id = "standard-v2"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.lab_subnet.id
    security_group_ids = [yandex_vpc_security_group.lab_sg.id]
    nat                = true # Explicit public IP allocation for SSH reachability (incurs public IPv4 charges)
  }

  metadata = {
    user-data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
      ssh_public_key = jsonencode(trimspace(file(pathexpand(var.ssh_public_key_path))))
    })
  }
}
