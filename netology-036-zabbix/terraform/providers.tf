provider "proxmox" {
  endpoint = "https://10.11.11.12:8006/"
  insecure = true

  ssh {
    username = "terraform"
    agent    = true

    node {
      name    = "vault"
      address = "10.11.11.12"
    }
  }
}
