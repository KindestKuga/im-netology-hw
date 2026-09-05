locals {
  ssh_public_key = trimspace(
    file(pathexpand("~/.ssh/id_ed25519.pub"))
  )

  vms = {
    lb = {
      name      = "netology-039-lb"
      vm_id     = var.lb_vm_id
      ip        = var.lb_ip
      cores     = 1
      memory_mb = 1536
      disk_gb   = 10
    }

    app = {
      name      = "netology-039-app"
      vm_id     = var.app_vm_id
      ip        = var.app_ip
      cores     = 1
      memory_mb = 1536
      disk_gb   = 10
    }
  }
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  for_each = local.vms

  content_type = "snippets"
  datastore_id = var.file_datastore
  node_name    = var.proxmox_node

  overwrite   = true
  upload_mode = "sftp"

  source_raw {
    file_name = "netology-039-${each.key}-user-data.yaml"

    data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
      hostname       = each.value.name
      ssh_public_key = local.ssh_public_key
    })
  }
}

resource "proxmox_virtual_environment_vm" "lab" {
  for_each = local.vms

  node_name = var.proxmox_node
  vm_id     = each.value.vm_id
  name      = each.value.name

  started = true

  agent {
    enabled = true

    wait_for_ip {
      disabled = true
    }
  }

  cpu {
    cores = each.value.cores
    type  = "host"
  }

  memory {
    dedicated = each.value.memory_mb
    floating  = 0
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = var.vm_datastore
    import_from  = var.debian_image_id
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  initialization {
    datastore_id      = var.vm_datastore
    user_data_file_id = proxmox_virtual_environment_file.cloud_init[each.key].id

    dns {
      servers = [var.dns_server]
    }

    ip_config {
      ipv4 {
        address = each.value.ip
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
