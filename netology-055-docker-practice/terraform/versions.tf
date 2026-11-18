terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.206.0"
    }
  }
}

provider "yandex" {
  # Authentication credentials and folder/cloud scope are supplied via standard
  # environment variables: YC_TOKEN (or YC_SERVICE_ACCOUNT_KEY_FILE), YC_CLOUD_ID, YC_FOLDER_ID.
  # Provider block remains unpolluted with hardcoded credentials or literal secrets.
  folder_id = var.folder_id
  zone      = var.zone
}
