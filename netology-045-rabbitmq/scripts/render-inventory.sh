#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform"
OUT="$PROJECT_ROOT/ansible/inventory.yml"

for command in terraform jq; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command" >&2
    exit 1
  fi
done

if ! terraform -chdir="$TF_DIR" output -json vms >/dev/null 2>&1; then
  echo "ERROR: Terraform output 'vms' is unavailable." >&2
  echo "Run terraform apply first." >&2
  exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  cat <<'YAML'
all:
  children:
    rabbitmq:
      hosts:
YAML

  terraform -chdir="$TF_DIR" output -json vms \
    | jq -r '
        to_entries
        | sort_by(.key)[]
        | "        \(.key):\n" +
          "          ansible_host: \(.value.ip)\n" +
          "          rabbitmq_nodename: rabbit@\(.value.hostname)"
      '

  cat <<'YAML'
      vars:
        ansible_user: debian
        ansible_python_interpreter: /usr/bin/python3
YAML
} > "$tmp"

install -m 0600 "$tmp" "$OUT"

echo "Generated: $OUT"
