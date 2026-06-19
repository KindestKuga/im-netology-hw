# export-yc-env.zsh

Локальный helper для подготовки env перед Terraform в Yandex Cloud.

Скрипт берёт текущий `yc` profile, находит service account `netology`, выпускает временный IAM token через impersonation и экспортирует переменные для Terraform provider.

## Запуск

```zsh
cd <PROJECT_ROOT>

source scripts/export-yc-env.zsh
cd terraform

terraform init
terraform validate
terraform plan -out=tfplan
```

## Что экспортируется

```text
YC_CLI_INITIALIZATION_SILENCE
TF_CLI_CONFIG_FILE
YC_CLOUD_ID
YC_FOLDER_ID
YC_ZONE
YC_TERRAFORM_SA_NAME
YC_TERRAFORM_SA_ID
YC_USER_ID
YC_TOKEN
```

`YC_TOKEN` в терминал не печатается:

```text
YC_TOKEN=***hidden***
```

## Требования

```text
zsh
yc
jq
terraform/.terraformrc
configured yc profile
service account netology
iam.serviceAccounts.tokenCreator на service account
```

## Проверка

```zsh
source scripts/export-yc-env.zsh

yc compute instance list \
  --folder-id "$YC_FOLDER_ID" \
  --impersonate-service-account-id "$YC_TERRAFORM_SA_ID"
```

Пустой список VM — нормальный результат, если ресурсы ещё не созданы.

## Типовые ошибки

### `No configuration files`

Terraform запущен из корня проекта, а не из `terraform/`.

```zsh
cd <PROJECT_ROOT>
source scripts/export-yc-env.zsh
cd terraform
terraform plan
```

### `.terraformrc` not found

Локальный Terraform CLI config отсутствует.

```zsh
test -f terraform/.terraformrc && echo OK || echo MISSING
```

### `service account 'netology' not found`

`yc` смотрит не в тот folder или service account не создан.

```zsh
yc config list
yc iam service-account list --folder-id "$(yc config get folder-id)"
```

### `Permission denied` при impersonation

Текущему user account не выдана роль `iam.serviceAccounts.tokenCreator` на service account `netology`.
