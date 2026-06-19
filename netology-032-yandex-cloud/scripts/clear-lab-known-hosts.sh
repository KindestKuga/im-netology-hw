#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
KNOWN_HOSTS="${HOME}/.ssh/known_hosts"

if [[ $# -gt 0 ]]; then
  echo "ERROR: no arguments supported." >&2
  exit 1
fi

for cmd in terraform jq ssh-keygen; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  fi
done

if [[ ! -f "$KNOWN_HOSTS" ]]; then
  echo "known_hosts not found: $KNOWN_HOSTS"
  echo "Nothing to remove."
  exit 0
fi

hosts_tmp="$(mktemp)"
matched_tmp="$(mktemp)"
trap 'rm -f "$hosts_tmp" "$matched_tmp"' EXIT

if ! terraform -chdir="$TERRAFORM_DIR" output -json ansible_inventory |
  jq -r '.. | objects | .ansible_host? // empty' |
  awk 'NF && !seen[$0]++' > "$hosts_tmp"; then
  echo "ERROR: failed to read Terraform output ansible_inventory." >&2
  echo "Run terraform apply first." >&2
  exit 1
fi

if [[ ! -s "$hosts_tmp" ]]; then
  echo "No lab hosts found in Terraform output."
  exit 0
fi

while IFS= read -r host; do
  if ssh-keygen -F "$host" -f "$KNOWN_HOSTS" >/dev/null 2>&1; then
    printf '%s\n' "$host" >> "$matched_tmp"
  fi
done < "$hosts_tmp"

if [[ ! -s "$matched_tmp" ]]; then
  echo "No lab entries found in known_hosts."
  exit 0
fi

echo "known_hosts: $KNOWN_HOSTS"
echo
echo "Lab entries to remove:"
sed 's/^/  - /' "$matched_tmp"
echo

read -r -p "Remove these entries? [y/N] " answer

case "$answer" in
  y|Y|yes|YES) ;;
  *)
    echo "Canceled."
    exit 0
    ;;
esac

while IFS= read -r host; do
  echo "Removing: $host"
  ssh-keygen -R "$host" -f "$KNOWN_HOSTS" >/dev/null
done < "$matched_tmp"

echo "Done."