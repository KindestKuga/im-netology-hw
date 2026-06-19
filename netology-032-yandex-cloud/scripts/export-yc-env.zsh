#!/usr/bin/env zsh
# Source from homework root:
# source scripts/export-yc-env.zsh

if [[ -z "${ZSH_VERSION:-}" ]]; then
    echo "ERROR: source this script from zsh." >&2
    return 1 2>/dev/null || exit 1
fi

for cmd in yc jq; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "ERROR: command not found: $cmd" >&2
        return 1
    fi
done

export YC_CLI_INITIALIZATION_SILENCE=true

SCRIPT_PATH="${(%):-%x}"
SCRIPT_DIR="${SCRIPT_PATH:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"

export TF_CLI_CONFIG_FILE="${TERRAFORM_DIR}/.terraformrc"

if [[ ! -f "$TF_CLI_CONFIG_FILE" ]]; then
    echo "ERROR: Terraform CLI config not found: $TF_CLI_CONFIG_FILE" >&2
    return 1
fi

export YC_CLOUD_ID="$(yc config get cloud-id)"
export YC_FOLDER_ID="$(yc config get folder-id)"
export YC_ZONE="$(yc config get compute-default-zone)"

if [[ -z "$YC_CLOUD_ID" || -z "$YC_FOLDER_ID" ]]; then
    echo "ERROR: yc profile is not configured: cloud-id/folder-id is empty" >&2
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
    echo "ERROR: service account 'netology' not found in folder $YC_FOLDER_ID" >&2
    return 1
fi

export YC_USER_ID="$(yc iam whoami --format json | jq -r '.')"

export YC_TOKEN="$(
    yc iam create-token \
        --impersonate-service-account-id "$YC_TERRAFORM_SA_ID"
)"

if [[ -z "$YC_TOKEN" ]]; then
    echo "ERROR: failed to create IAM token for service account $YC_TERRAFORM_SA_NAME" >&2
    return 1
fi

echo "YC_CLI_INITIALIZATION_SILENCE=$YC_CLI_INITIALIZATION_SILENCE"
echo "YC_CLOUD_ID=$YC_CLOUD_ID"
echo "YC_FOLDER_ID=$YC_FOLDER_ID"
echo "YC_TERRAFORM_SA_NAME=$YC_TERRAFORM_SA_NAME"
echo "YC_TERRAFORM_SA_ID=$YC_TERRAFORM_SA_ID"
echo "YC_USER_ID=$YC_USER_ID"
echo "TF_CLI_CONFIG_FILE=$TF_CLI_CONFIG_FILE"
echo "YC_ZONE=$YC_ZONE"
echo "YC_TOKEN=***hidden***"