output "ansible_inventory" {
  description = "Ansible inventory data."
  value = {
    all = {
      children = {
        yc_bastion = {
          hosts = {
            bastion = {
              ansible_host               = yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address
              ansible_user               = var.vm_user
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o StrictHostKeyChecking=accept-new"
            }
          }
        }

        yc_web = {
          hosts = {
            "web-a" = {
              ansible_host               = yandex_compute_instance.vm["web-a"].network_interface[0].ip_address
              ansible_user               = var.vm_user
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o ProxyJump=${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} -o StrictHostKeyChecking=accept-new"
            }

            "web-b" = {
              ansible_host               = yandex_compute_instance.vm["web-b"].network_interface[0].ip_address
              ansible_user               = var.vm_user
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o ProxyJump=${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} -o StrictHostKeyChecking=accept-new"
            }
          }
        }

        yc_db = {
          hosts = {
            db = {
              ansible_host               = yandex_compute_instance.vm["db"].network_interface[0].ip_address
              ansible_user               = var.vm_user
              ansible_python_interpreter = "/usr/bin/python3"
              ansible_ssh_common_args    = "-o ProxyJump=${var.vm_user}@${yandex_compute_instance.vm["bastion"].network_interface[0].nat_ip_address} -o StrictHostKeyChecking=accept-new"
            }
          }
        }
      }

      vars = {
        ansible_ssh_private_key_file = trimsuffix(var.ssh_public_key_path, ".pub")
      }
    }
  }
}
