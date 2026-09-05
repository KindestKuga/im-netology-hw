output "web_instances" {
  description = "Web VM names and addresses."
  value = [
    for vm in yandex_compute_instance.web : {
      name        = vm.name
      internal_ip = vm.network_interface[0].ip_address
      external_ip = vm.network_interface[0].nat_ip_address
    }
  ]
}

output "load_balancer_ip" {
  description = "External IPv4 address of the Network Load Balancer."
  value = one(
    one(yandex_lb_network_load_balancer.web.listener).external_address_spec
  ).address
}

output "target_group_id" {
  value = yandex_lb_target_group.web.id
}
