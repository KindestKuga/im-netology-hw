#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$PROJECT_ROOT/terraform"
PKI_DIR="$PROJECT_ROOT/ansible/pki"

for command in terraform jq openssl; do
  if ! command -v "$command" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $command" >&2
    exit 1
  fi
done

mapfile -t nodes < <(
  terraform -chdir="$TF_DIR" output -json vms |
    jq -r '
      to_entries
      | sort_by(.key)[]
      | "\(.value.hostname) \(.value.ip)"
    '
)

if ((${#nodes[@]} == 0)); then
  echo "ERROR: Terraform output contains no RabbitMQ nodes." >&2
  exit 1
fi

rm -rf "$PKI_DIR"
install -d -m 0700 "$PKI_DIR"

#
# Lab root CA
#
openssl genrsa \
  -out "$PKI_DIR/ca.key.pem" \
  4096 >/dev/null 2>&1

openssl req \
  -x509 \
  -new \
  -sha256 \
  -days 30 \
  -key "$PKI_DIR/ca.key.pem" \
  -subj "/CN=Netology RabbitMQ Lab CA" \
  -addext "basicConstraints=critical,CA:TRUE,pathlen:0" \
  -addext "keyUsage=critical,keyCertSign,cRLSign" \
  -addext "subjectKeyIdentifier=hash" \
  -out "$PKI_DIR/ca.crt.pem"

chmod 0600 "$PKI_DIR/ca.key.pem"
chmod 0644 "$PKI_DIR/ca.crt.pem"

#
# Per-node server certificates
#
for node in "${nodes[@]}"; do
  read -r hostname ip <<< "$node"

  key="$PKI_DIR/${hostname}.key.pem"
  csr="$PKI_DIR/${hostname}.csr.pem"
  cert="$PKI_DIR/${hostname}.crt.pem"
  ext="$PKI_DIR/${hostname}.ext"

  openssl genrsa \
    -out "$key" \
    2048 >/dev/null 2>&1

  openssl req \
    -new \
    -sha256 \
    -key "$key" \
    -subj "/CN=${hostname}" \
    -out "$csr"

  cat > "$ext" <<EXT
basicConstraints=critical,CA:FALSE
keyUsage=critical,digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectKeyIdentifier=hash
authorityKeyIdentifier=keyid,issuer
subjectAltName=DNS:${hostname},IP:${ip}
EXT

  openssl x509 \
    -req \
    -sha256 \
    -days 30 \
    -in "$csr" \
    -CA "$PKI_DIR/ca.crt.pem" \
    -CAkey "$PKI_DIR/ca.key.pem" \
    -set_serial "0x$(openssl rand -hex 16)" \
    -extfile "$ext" \
    -out "$cert" \
    >/dev/null 2>&1

  rm -f "$csr" "$ext"

  chmod 0600 "$key"
  chmod 0644 "$cert"

  openssl verify \
    -x509_strict \
    -purpose sslserver \
    -CAfile "$PKI_DIR/ca.crt.pem" \
    "$cert"
done

echo "Generated RFC 5280-compatible PKI for ${#nodes[@]} RabbitMQ node(s)."
