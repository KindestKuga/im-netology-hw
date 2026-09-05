#!/usr/bin/env bash

if [[ -z "${BASH_VERSION:-}" ]]; then
    echo "ERROR: source this script from bash." >&2
    return 1 2>/dev/null || exit 1
fi

for cmd in yc jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: command not found: $cmd" >&2
        return 1
    fi
done

export YC_CLI_INITIALIZATION_SILENCE=true

SCRIPT_DIR="$(
    builtin cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"
PROJECT_ROOT="$(
    builtin cd -- "$SCRIPT_DIR/.."
    pwd
)"

export TF_CLI_CONFIG_FILE="${PROJECT_ROOT}/terraform/.terraformrc"

if [[ ! -f "$TF_CLI_CONFIG_FILE" ]]; then
    echo "ERROR: Terraform CLI config not found: $TF_CLI_CONFIG_FILE" >&2
    return 1
fi

export YC_CLOUD_ID="$(yc config get cloud-id)"
export YC_FOLDER_ID="$(yc config get folder-id)"
export YC_ZONE="$(yc config get compute-default-zone)"

if [[ -z "$YC_CLOUD_ID" || -z "$YC_FOLDER_ID" ]]; then
    echo "ERROR: yc profile is not configured." >&2
    return 1
fi

export YC_TERRAFORM_SA_NAME="netology"

export YC_TERRAFORM_SA_ID="$(
    yc iam service-account list \
        --folder-id "$YC_FOLDER_ID" \
        --format json |
        jq -r '.[] | select(.name == "netology") | .id' |
        head -n 1
)"

if [[ -z "$YC_TERRAFORM_SA_ID" ]]; then
    echo "ERROR: service account 'netology' not found." >&2
    return 1
fi

export YC_TOKEN="$(
    yc iam create-token \
        --impersonate-service-account-id "$YC_TERRAFORM_SA_ID"
)"

if [[ -z "$YC_TOKEN" ]]; then
    echo "ERROR: failed to create IAM token." >&2
    return 1
fi

# Terraform variables used by both homework tasks.
export TF_VAR_zone="$YC_ZONE"
export TF_VAR_service_account_id="$YC_TERRAFORM_SA_ID"

echo "YC_CLOUD_ID=$YC_CLOUD_ID"
echo "YC_FOLDER_ID=$YC_FOLDER_ID"
echo "YC_ZONE=$YC_ZONE"
echo "YC_TERRAFORM_SA_NAME=$YC_TERRAFORM_SA_NAME"
echo "YC_TERRAFORM_SA_ID=$YC_TERRAFORM_SA_ID"
echo "TF_CLI_CONFIG_FILE=$TF_CLI_CONFIG_FILE"
echo "YC_TOKEN=***hidden***"
