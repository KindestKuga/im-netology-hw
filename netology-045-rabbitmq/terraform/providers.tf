provider "proxmox" {
  endpoint = var.proxmox_endpoint
  insecure = var.proxmox_insecure

  ssh {
    username = "terraform"
    agent    = true

    node {
      name    = var.proxmox_node
      address = var.proxmox_ssh_address
    }
  }
}
