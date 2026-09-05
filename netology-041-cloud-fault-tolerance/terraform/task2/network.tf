resource "yandex_vpc_network" "main" {
  name = "netology-041-task2-network"
}

resource "yandex_vpc_subnet" "main" {
  name           = "netology-041-task2-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.41.20.0/24"]
}

resource "yandex_vpc_security_group" "web" {
  name       = "netology-041-task2-web-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    description    = "HTTP for NLB"
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
