resource "yandex_vpc_network" "main" {
  name = "netology-041-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "netology-041-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.41.10.0/24"]
}

resource "yandex_vpc_security_group" "web" {
  name       = "netology-041-web-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "HTTP for NLB and lab checks"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Outbound traffic for package installation"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
