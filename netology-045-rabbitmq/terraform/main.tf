locals {
  ssh_public_key = trimspace(
    file(pathexpand("~/.ssh/id_ed25519.pub"))
  )
}

resource "proxmox_download_file" "debian_13_cloud_image" {
  content_type = "import"
  datastore_id = var.file_datastore
  node_name    = var.proxmox_node

  url       = "https://cloud.debian.org/images/cloud/trixie/20260706-2531/debian-13-generic-amd64-20260706-2531.qcow2"
  file_name = "rabbitmq-debian-13-generic-amd64-20260706-2531.qcow2"

  checksum           = "aca6eefc7b87faddad617b197fb621c44cc2c440f7097d78ac06e113f78177f6b7a1a39a581fbb24c2513354ab6938e63e78730259ce204b53452e8186f53a37"
  checksum_algorithm = "sha512"

  overwrite           = false
  overwrite_unmanaged = false

  upload_timeout = 1200
  verify         = true
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  for_each = var.vms

  content_type = "snippets"
  datastore_id = var.file_datastore
  node_name    = var.proxmox_node

  overwrite   = true
  upload_mode = "sftp"

  source_raw {
    file_name = "netology-045-${each.key}-user-data.yaml"

    data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
      hostname       = each.value.hostname
      ssh_public_key = local.ssh_public_key
    })
  }
}

resource "proxmox_virtual_environment_vm" "rabbitmq" {
  for_each = var.vms

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  name      = each.value.name

  description = join("\n", [
    "Managed by Terraform.",
    "Netology RabbitMQ homework.",
    "RabbitMQ node: ${each.value.hostname}.",
    "Disposable lab VM.",
  ])

  tags = [
    "terraform",
    "netology",
    "rabbitmq",
    "debian",
  ]

  acpi          = true
  bios          = "seabios"
  machine       = "pc"
  scsi_hardware = "virtio-scsi-single"

  boot_order = ["scsi0"]

  on_boot = false
  started = true

  stop_on_destroy                      = true
  delete_unreferenced_disks_on_destroy = true
  purge_on_destroy                     = false
  reboot_after_update                  = false

  agent {
    enabled = true
    trim    = true
    type    = "virtio"

    wait_for_ip {
      disabled = true
    }
  }

  cpu {
    cores   = each.value.cpu_cores
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = each.value.memory_mb
    floating  = 0
  }

  disk {
    datastore_id = var.vm_datastore
    import_from  = proxmox_download_file.debian_13_cloud_image.id
    interface    = "scsi0"

    iothread = true
    discard  = "on"
    ssd      = true

    size = each.value.disk_size_gb

    backup    = false
    replicate = false
  }

  initialization {
    datastore_id      = var.vm_datastore
    interface         = "ide2"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init[each.key].id

    dns {
      servers = [var.dns_server]
    }

    ip_config {
      ipv4 {
        address = each.value.ipv4_cidr
        gateway = var.gateway
      }
    }
  }

  network_device {
    bridge = var.bridge
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }
}
