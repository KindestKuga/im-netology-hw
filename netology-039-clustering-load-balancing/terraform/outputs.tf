output "vms" {
  value = {
    for key, vm in local.vms : key => {
      name  = vm.name
      vm_id = vm.vm_id
      ip    = vm.ip
    }
  }
}
