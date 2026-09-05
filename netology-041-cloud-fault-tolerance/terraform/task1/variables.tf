variable "zone" {
  description = "Yandex Cloud availability zone."
  type        = string
  default     = "ru-central1-a"
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
}

variable "preemptible" {
  description = "Use preemptible VMs for the lab."
  type        = bool
  default     = true
}

variable "vm_resources" {
  description = "Small inexpensive VM profile."
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
}
