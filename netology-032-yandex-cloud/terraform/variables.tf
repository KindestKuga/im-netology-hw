variable "zone" {
  description = "YC zone."
  type        = string
  default     = "ru-central1-a"

  validation {
    condition     = contains(["ru-central1-a", "ru-central1-b", "ru-central1-d"], var.zone)
    error_message = "zone must be one of ru-central1-a, ru-central1-b, ru-central1-d."
  }
}

variable "trusted_ssh_cidr" {
  description = "CIDR allowed to SSH to bastion."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.trusted_ssh_cidr)) && var.trusted_ssh_cidr != "0.0.0.0/0"
    error_message = "trusted_ssh_cidr must be a valid IPv4 CIDR and must not be 0.0.0.0/0. Example: 203.0.113.10/32."
  }
}

variable "vm_user" {
  description = "VM SSH user."
  type        = string
  default     = "yc-user"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]*[$]?$", var.vm_user)) && var.vm_user != "root"
    error_message = "vm_user must be a valid Linux username and must not be root."
  }
}

variable "ssh_public_key_path" {
  description = "SSH public key path."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = endswith(var.ssh_public_key_path, ".pub")
    error_message = "ssh_public_key_path must point to a public SSH key file ending with .pub."
  }
}

variable "image_family" {
  description = "VM image family."
  type        = string
  default     = "ubuntu-2404-lts"
}

variable "platform_id" {
  description = "Compute platform."
  type        = string
  default     = "standard-v2"

  validation {
    condition     = var.platform_id == "standard-v2"
    error_message = "platform_id must be standard-v2 for this lab."
  }
}

variable "preemptible" {
  description = "Use preemptible VMs."
  type        = bool
  default     = true
}

variable "common_labels" {
  description = "Resource labels."
  type        = map(string)
  default = {
    project     = "netology"
    lesson      = "032"
    homework    = "yc-infra"
    environment = "dev"
    managed_by  = "terraform"
    owner       = "im"
  }
}

variable "vm_resources" {
  description = "VM size."
  type = object({
    cores         = number
    memory        = number
    core_fraction = number
    disk_size     = number
    disk_type     = string
  })

  default = {
    cores         = 2
    memory        = 1
    core_fraction = 5
    disk_size     = 10
    disk_type     = "network-hdd"
  }

  validation {
    condition = (
      var.vm_resources.cores >= 2 &&
      var.vm_resources.memory >= 1 &&
      contains([5, 20, 50, 100], var.vm_resources.core_fraction) &&
      var.vm_resources.disk_size >= 10 &&
      contains(["network-hdd", "network-ssd"], var.vm_resources.disk_type)
    )
    error_message = "vm_resources must use cores >= 2, memory >= 1, core_fraction 5/20/50/100, disk_size >= 10, and disk_type network-hdd or network-ssd."
  }
}
