variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_ssh_address" {
  type = string
}

variable "proxmox_node" {
  type = string
}

variable "file_datastore" {
  type = string
}

variable "vm_datastore" {
  type = string
}

variable "bridge" {
  type = string
}

variable "gateway" {
  type = string
}

variable "dns_server" {
  type = string
}

variable "debian_image_id" {
  type = string
}

variable "lb_vm_id" {
  type = number
}

variable "app_vm_id" {
  type = number
}

variable "lb_ip" {
  type = string
}

variable "app_ip" {
  type = string
}
