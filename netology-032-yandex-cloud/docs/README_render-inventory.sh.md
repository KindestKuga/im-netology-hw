# render-inventory.sh

Генерирует `ansible/inventory.yml` из Terraform output `ansible_inventory`.

Нужен после `terraform apply`, чтобы Ansible получил актуальные адреса VM и current public IP bastion.

## Что делает

Скрипт читает Terraform output:

```text
terraform output -json ansible_inventory
```

Проверяет, что output похож на Ansible inventory:

```text
.all.children
.all.vars
```

Потом конвертирует JSON в YAML и записывает:

```text
ansible/inventory.yml
```

## Почему так

`ansible_inventory` уже формируется в Terraform в готовой Ansible-структуре.

Terraform отвечает за адреса и SSH параметры:

```text
bastion public IP
private IP web-a/web-b/db
ProxyJump через bastion
SSH user
private key path
Python interpreter
```

`render-inventory.sh` не собирает inventory вручную, а только рендерит готовый output в YAML.

## Запуск

```zsh
cd <PROJECT_ROOT>
./scripts/render-inventory.sh
```

## Требования

```text
terraform apply уже выполнен
output ansible_inventory есть в Terraform state
jq установлен
python установлен
PyYAML доступен
```

`PyYAML` обычно уже есть вместе с Ansible.

## Проверка

```zsh
cd ansible
ansible-inventory --graph
ansible all -m ping
```

Ожидаемые группы:

```text
yc_bastion
yc_web
yc_db
```

## Типовые проблемы

### Terraform output недоступен

Причина: `terraform apply` ещё не выполнен или state отсутствует.

Проверка:

```zsh
terraform -chdir=terraform output
```

### Unexpected structure

Причина: изменилась структура output `ansible_inventory`.

Нужно проверить:

```zsh
terraform -chdir=terraform output -json ansible_inventory | jq 'keys'
```

Ожидается:

```text
all
```

### Ansible идёт на старый bastion IP

Причина: `ansible/inventory.yml` не был перегенерирован после нового `terraform apply`.

Решение:

```zsh
./scripts/render-inventory.sh
cat ansible/inventory.yml
```
