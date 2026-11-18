output "vm_public_ip" {
  description = "Public NAT IPv4 address assigned to the virtual machine"
  value       = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "vm_private_ip" {
  description = "Internal IPv4 address within the dedicated VPC subnet"
  value       = yandex_compute_instance.vm.network_interface[0].ip_address
}

output "ssh_command" {
  description = "Convenience SSH command to connect to the deployed instance"
  value       = "ssh lab@${yandex_compute_instance.vm.network_interface[0].nat_ip_address}"
}
