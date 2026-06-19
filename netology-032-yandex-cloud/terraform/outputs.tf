output "bastion_external_ip" {
  description = "Bastion public IP."
  value       = yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address
}

output "bastion_internal_ip" {
  description = "Bastion private IP."
  value       = yandex_compute_instance.vm["bastion"].network_interface[0].ip_address
}

output "web_internal_ips" {
  description = "Web private IPs."
  value = {
    web-a = yandex_compute_instance.vm["web-a"].network_interface[0].ip_address
    web-b = yandex_compute_instance.vm["web-b"].network_interface[0].ip_address
  }
}

output "db_internal_ip" {
  description = "DB private IP."
  value       = yandex_compute_instance.vm["db"].network_interface[0].ip_address
}

output "ssh_bastion_command" {
  description = "SSH to bastion."
  value       = "ssh ${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address}"
}

output "ssh_web_a_command" {
  description = "SSH to web-a through bastion."
  value       = "ssh -J ${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} ${var.vm_user}@${yandex_compute_instance.vm["web-a"].network_interface[0].ip_address}"
}

output "ssh_web_b_command" {
  description = "SSH to web-b through bastion."
  value       = "ssh -J ${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} ${var.vm_user}@${yandex_compute_instance.vm["web-b"].network_interface[0].ip_address}"
}

output "ssh_db_command" {
  description = "SSH to DB through bastion."
  value       = "ssh -J ${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} ${var.vm_user}@${yandex_compute_instance.vm["db"].network_interface[0].ip_address}"
}
