#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://127.0.0.1:8080}"
REQUESTS="${REQUESTS:-5}"

request() {
  local path="$1"
  local code
  code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 5 "$BASE_URL$path" || true)"
  printf '%-24s -> %s\n' "$path" "$code"
}

for _ in $(seq 1 "$REQUESTS"); do
  request /
  request /api/ok
  request /missing
  request /api/error
  request /broken-upstream
  request /api/slow
done
