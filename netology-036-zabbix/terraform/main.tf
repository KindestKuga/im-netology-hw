locals {
  ssh_public_key = trimspace(
    file(pathexpand("~/.ssh/id_ed25519.pub"))
  )

  vms = {
    server = {
      name      = "mosiichukii-1"
      vm_id     = 592
      ip        = "10.11.11.163/24"
      cores     = 2
      memory_mb = 3072
      disk_gb   = 20
    }

    agent = {
      name      = "mosiichukii-2"
      vm_id     = 593
      ip        = "10.11.11.164/24"
      cores     = 1
      memory_mb = 1024
      disk_gb   = 10
    }
  }
}

resource "proxmox_download_file" "debian" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "vault"

  url       = "https://cloud.debian.org/images/cloud/trixie/20260706-2531/debian-13-generic-amd64-20260706-2531.qcow2"
  file_name = "zabbix-debian-13-generic-amd64-20260706-2531.qcow2"

  checksum           = "aca6eefc7b87faddad617b197fb621c44cc2c440f7097d78ac06e113f78177f6b7a1a39a581fbb24c2513354ab6938e63e78730259ce204b53452e8186f53a37"
  checksum_algorithm = "sha512"

  overwrite           = false
  overwrite_unmanaged = false
}

resource "proxmox_virtual_environment_file" "cloud_init" {
  for_each = local.vms

  content_type = "snippets"
  datastore_id = "local"
  node_name    = "vault"

  overwrite   = true
  upload_mode = "sftp"

  source_raw {
    file_name = "zabbix-${each.key}-user-data.yaml"

    data = templatefile("${path.module}/templates/user-data.yaml.tftpl", {
      hostname       = each.value.name
      ssh_public_key = local.ssh_public_key
    })
  }
}

resource "proxmox_virtual_environment_vm" "zabbix" {
  for_each = local.vms

  node_name = "vault"
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
    datastore_id = "local-scratch-degraded-980pro"
    import_from  = proxmox_download_file.debian.id
    interface    = "scsi0"
    size         = each.value.disk_gb
  }

  initialization {
    datastore_id      = "local-scratch-degraded-980pro"
    user_data_file_id = proxmox_virtual_environment_file.cloud_init[each.key].id

    dns {
      servers = ["10.11.11.1"]
    }

    ip_config {
      ipv4 {
        address = each.value.ip
        gateway = "10.11.11.1"
      }
    }
  }

  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }

  operating_system {
    type = "l26"
  }
}
