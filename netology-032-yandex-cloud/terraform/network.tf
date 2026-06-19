resource "yandex_vpc_network" "main" {
  name        = "netology-032-network"
  description = "VPC network for Netology homework 032"
  labels      = var.common_labels
}

resource "yandex_vpc_gateway" "nat" {
  name        = "netology-032-nat-gateway"
  description = "Shared egress NAT gateway for private web servers"
  labels      = var.common_labels

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_nat" {
  name        = "netology-032-private-nat-rt"
  description = "Default route from private subnet to NAT gateway"
  network_id  = yandex_vpc_network.main.id
  labels      = var.common_labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "public" {
  name           = "netology-032-public-a"
  description    = "Public subnet for bastion host"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.32.10.0/24"]
  labels         = var.common_labels
}

resource "yandex_vpc_subnet" "private" {
  name           = "netology-032-private-a"
  description    = "Private subnet for web servers"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.32.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_nat.id
  labels         = var.common_labels
}

resource "yandex_vpc_security_group" "bastion" {
  name        = "netology-032-bastion-sg"
  description = "Allow SSH to bastion only from trusted IPv4"
  network_id  = yandex_vpc_network.main.id
  labels      = var.common_labels

  ingress {
    protocol       = "TCP"
    description    = "SSH from trusted public IPv4"
    v4_cidr_blocks = [var.trusted_ssh_cidr]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic from bastion"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web" {
  name        = "netology-032-web-sg"
  description = "Allow SSH and HTTP to web servers only from bastion subnet"
  network_id  = yandex_vpc_network.main.id
  labels      = var.common_labels

  ingress {
    protocol       = "TCP"
    description    = "SSH from bastion private IP"
    v4_cidr_blocks = ["10.32.10.10/32"]
    port           = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP from bastion subnet for nginx checks"
    v4_cidr_blocks = ["10.32.10.0/24"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic for apt and updates via NAT gateway"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "db" {
  name        = "netology-032-db-sg"
  description = "SSH from bastion, PostgreSQL from private subnet"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.common_labels, { role = "db" })

  ingress {
    description    = "SSH from bastion"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["10.32.10.10/32"]
  }

  ingress {
    description    = "PostgreSQL from private subnet"
    protocol       = "TCP"
    port           = 5432
    v4_cidr_blocks = ["10.32.20.0/24"]
  }

  egress {
    description    = "Outbound via NAT"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
