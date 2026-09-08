terraform {
  required_version = ">= 1.15.0, < 1.16.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.109.0"
    }
  }
}
