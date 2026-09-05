#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)"

project_root="$(
  cd "$script_dir/.."
  pwd
)"

terraform_dir="$project_root/terraform"
inventory="$project_root/ansible/inventory.yml"

tmp="$(mktemp "${inventory}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

terraform -chdir="$terraform_dir" output -json vms |
python3 -c '
import json
import sys

vms = json.load(sys.stdin)

required = {"lb", "app"}
missing = required - set(vms)

if missing:
    raise SystemExit(
        "Missing Terraform VM outputs: " + ", ".join(sorted(missing))
    )

def strip_cidr(value):
    return value.split("/", 1)[0]

print("all:")
print("  vars:")
print("    ansible_user: debian")
print("    ansible_python_interpreter: /usr/bin/python3")
print("  children:")

for group in ("lb", "app"):
    vm = vms[group]
    name = vm["name"]
    address = strip_cidr(vm["ip"])

    print("    {}:".format(group))
    print("      hosts:")
    print("        {}:".format(name))
    print("          ansible_host: {}".format(address))
' > "$tmp"

mv "$tmp" "$inventory"
trap - EXIT

echo "Rendered: $inventory"
