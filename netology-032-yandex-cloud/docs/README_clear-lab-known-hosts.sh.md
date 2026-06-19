# clear-lab-known-hosts.sh

Чистит `known_hosts` от SSH host keys текущей lab-инфры.

Нужно после `terraform destroy/apply`, если SSH или Ansible ругается на изменившийся host key.

## Запуск

```zsh
cd <PROJECT_ROOT>
./scripts/clear-lab-known-hosts.sh
```

Скрипт берёт адреса из Terraform output `ansible_inventory`, показывает найденные записи в `known_hosts` и спрашивает подтверждение.

## Требования

```text
terraform apply уже выполнен
output ansible_inventory есть в Terraform state
jq установлен
```

## После очистки

```zsh
cd ansible
ansible all -m ping
```
