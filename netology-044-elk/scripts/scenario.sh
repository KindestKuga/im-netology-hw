#!/usr/bin/env bash
set -euo pipefail

NGINX_URL="${NGINX_URL:-http://127.0.0.1:8080}"
SYSTEM_URL="${SYSTEM_URL:-http://127.0.0.1:9101}"
AGENT_URL="${AGENT_URL:-http://127.0.0.1:9102}"

curl_status() {
  local url="$1"
  curl -sS -o /dev/null -w '%{http_code}' --max-time 6 "$url" || true
}

printf '=== HW44 mixed incident scenario ===\n'
printf 'nginx healthy        %s\n' "$(curl_status "$NGINX_URL/api/ok")"
printf 'nginx 404            %s\n' "$(curl_status "$NGINX_URL/missing")"
printf 'nginx app 500        %s\n' "$(curl_status "$NGINX_URL/api/error")"
printf 'nginx broken upstream %s\n' "$(curl_status "$NGINX_URL/broken-upstream")"
printf 'nginx timeout        %s\n' "$(curl_status "$NGINX_URL/api/slow")"

if curl -fsS "$SYSTEM_URL/health" >/dev/null 2>&1; then
  curl -fsS "$SYSTEM_URL/event/warn" >/dev/null
  curl -sS "$SYSTEM_URL/event/error" >/dev/null || true
  curl -fsS "$SYSTEM_URL/load/cpu?seconds=15&workers=2" >/dev/null
  curl -fsS "$SYSTEM_URL/load/memory?seconds=15&mb=128" >/dev/null
  echo 'system-lab: warning/error + CPU/memory load started'
else
  echo 'system-lab: profile journal/metrics is not running; skipped'
fi

if curl -fsS "$AGENT_URL/health" >/dev/null 2>&1; then
  curl -fsS "$AGENT_URL/work" >/dev/null
  curl -sS "$AGENT_URL/error" >/dev/null || true
  curl -fsS "$AGENT_URL/slow" >/dev/null
  echo 'agent-demo: work/error/slow events generated'
else
  echo 'agent-demo: profile agent is not running; skipped'
fi

echo 'Scenario submitted. Keep Kibana on the last 15 minutes and watch datasets together.'
