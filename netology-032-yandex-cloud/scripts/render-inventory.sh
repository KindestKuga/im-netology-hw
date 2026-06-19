#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
INVENTORY_FILE="${ANSIBLE_DIR}/inventory.yml"

for cmd in terraform jq python; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  fi
done

if [[ ! -d "$TERRAFORM_DIR" || ! -d "$ANSIBLE_DIR" ]]; then
  echo "ERROR: expected terraform/ and ansible/ directories under: $PROJECT_ROOT" >&2
  exit 1
fi

inventory_json="$(mktemp)"
trap 'rm -f "$inventory_json"' EXIT

if ! terraform -chdir="$TERRAFORM_DIR" output -json ansible_inventory > "$inventory_json"; then
  echo "ERROR: failed to read Terraform output ansible_inventory." >&2
  echo "Run terraform apply first." >&2
  exit 1
fi

if ! jq -e '.all.children and .all.vars' "$inventory_json" >/dev/null; then
  echo "ERROR: Terraform output ansible_inventory has unexpected structure." >&2
  jq '.' "$inventory_json" >&2
  exit 1
fi

python - "$inventory_json" "$INVENTORY_FILE" <<'PY'
from pathlib import Path
import json
import sys
import yaml

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

data = json.loads(src.read_text())
dst.write_text("---\n" + yaml.safe_dump(data, sort_keys=False), encoding="utf-8")
PY

echo "Generated inventory: ${INVENTORY_FILE}"
echo
cat "$INVENTORY_FILE"
