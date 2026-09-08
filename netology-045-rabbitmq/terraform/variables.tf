variable "proxmox_endpoint" {
  description = "Proxmox VE API endpoint."
  type        = string
}

variable "proxmox_insecure" {
  description = "Disable TLS certificate verification for the Proxmox API. Use only when the API certificate is not trusted by the local system."
  type        = bool
  default     = false
}

variable "proxmox_ssh_address" {
  description = "SSH address of the Proxmox node."
  type        = string
}

variable "proxmox_node" {
  description = "Target Proxmox node."
  type        = string
}

variable "file_datastore" {
  description = "Datastore for cloud images and snippets."
  type        = string
}

variable "vm_datastore" {
  description = "Datastore for VM disks and cloud-init disks."
  type        = string
}

variable "bridge" {
  description = "Proxmox network bridge."
  type        = string
}

variable "gateway" {
  description = "IPv4 gateway for lab VMs."
  type        = string
}

variable "dns_server" {
  description = "DNS server for lab VMs."
  type        = string
}

variable "vms" {
  description = "RabbitMQ nodes. Add or remove map entries to change the cluster size."

  type = map(object({
    name         = string
    hostname     = string
    vm_id        = number
    ipv4_cidr    = string
    cpu_cores    = number
    memory_mb    = number
    disk_size_gb = number
  }))

  validation {
    condition     = length(var.vms) >= 1
    error_message = "At least one RabbitMQ VM must be defined."
  }

  validation {
    condition = alltrue([
      for key, vm in var.vms :
      key == vm.hostname
    ])
    error_message = "Each key in the vms map must match the VM hostname."
  }

  validation {
    condition = length(distinct([
      for vm in values(var.vms) : vm.vm_id
    ])) == length(var.vms)
    error_message = "Every RabbitMQ VM must have a unique vm_id."
  }

  validation {
    condition = length(distinct([
      for vm in values(var.vms) : vm.name
    ])) == length(var.vms)
    error_message = "Every RabbitMQ VM must have a unique Proxmox VM name."
  }

  validation {
    condition = length(distinct([
      for vm in values(var.vms) : vm.hostname
    ])) == length(var.vms)
    error_message = "Every RabbitMQ VM must have a unique hostname."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      can(cidrnetmask(vm.ipv4_cidr))
    ])
    error_message = "Every RabbitMQ VM must have a valid IPv4 CIDR."
  }

  validation {
    condition = length(distinct([
      for vm in values(var.vms) :
      split("/", vm.ipv4_cidr)[0]
    ])) == length(var.vms)
    error_message = "Every RabbitMQ VM must have a unique IPv4 address."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.cpu_cores >= 1
    ])
    error_message = "Every RabbitMQ VM must have at least one CPU core."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.memory_mb >= 512
    ])
    error_message = "Every RabbitMQ VM must have at least 512 MiB of RAM."
  }

  validation {
    condition = alltrue([
      for vm in values(var.vms) :
      vm.disk_size_gb >= 4
    ])
    error_message = "Every RabbitMQ VM must have at least 4 GiB of disk space."
  }
}
