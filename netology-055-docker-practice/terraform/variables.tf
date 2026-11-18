variable "folder_id" {
  type        = string
  description = "Yandex Cloud Target Folder ID"
}

variable "zone" {
  type        = string
  default     = "ru-central1-a"
  description = "Target availability zone for compute resources"
}

variable "trusted_ssh_cidr" {
  type        = string
  description = "Trusted IPv4 CIDR allowed SSH ingress (e.g., 203.0.113.50/32). Wide-open 0.0.0.0/0 is strictly rejected."

  validation {
    condition     = var.trusted_ssh_cidr != "0.0.0.0/0" && can(cidrnetmask(var.trusted_ssh_cidr))
    error_message = "trusted_ssh_cidr must be a valid CIDR and must not allow universal access 0.0.0.0/0."
  }
}

variable "trusted_app_cidr" {
  type        = list(string)
  default     = []
  description = "Trusted CIDR blocks allowed to access web port 8090. Defaults to empty (no outside ingress)."
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to public SSH key file for provisioning the lab user (must end in .pub)"

  validation {
    condition     = endswith(var.ssh_public_key_path, ".pub")
    error_message = "ssh_public_key_path must reference a public key file ending in .pub."
  }
}
