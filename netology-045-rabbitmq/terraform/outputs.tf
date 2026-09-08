output "rabbitmq_node_count" {
  description = "Number of RabbitMQ nodes managed by this stack."
  value       = length(var.vms)
}

output "rabbitmq_node_names" {
  description = "Ordered list of RabbitMQ hostnames."

  value = [
    for key in sort(keys(var.vms)) :
    var.vms[key].hostname
  ]
}

output "vms" {
  description = "RabbitMQ lab VM connection data."

  value = {
    for key, vm in var.vms :
    key => {
      name     = vm.name
      hostname = vm.hostname
      vm_id    = vm.vm_id
      ip       = split("/", vm.ipv4_cidr)[0]
    }
  }
}

output "ssh_commands" {
  description = "SSH commands for RabbitMQ lab nodes."

  value = {
    for key, vm in var.vms :
    key => "ssh debian@${split("/", vm.ipv4_cidr)[0]}"
  }
}
