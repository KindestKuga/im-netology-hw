#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
ES_URL="${ES_URL:-http://127.0.0.1:9200}"
KIBANA_URL="${KIBANA_URL:-http://127.0.0.1:5601}"

wait_http() {
  local name="$1" url="$2"
  printf 'Waiting for %s' "$name"
  for _ in $(seq 1 120); do
    if curl -fsS "$url" >/dev/null 2>&1; then
      echo ' OK'
      return 0
    fi
    printf '.'
    sleep 1
  done
  echo
  echo "$name did not become ready: $url" >&2
  return 1
}

put_json() {
  local url="$1" file="$2"
  curl -fsS -X PUT "$url" \
    -H 'Content-Type: application/json' \
    --data-binary "@$file" >/dev/null
}

wait_http Elasticsearch "$ES_URL/_cluster/health"
wait_http Kibana "$KIBANA_URL/api/status"

printf '\nInstalling data-stream templates and ingest pipeline...\n'
put_json "$ES_URL/_index_template/netology44-logs" \
  "$ROOT_DIR/elasticsearch/bootstrap/logs-template.json"
put_json "$ES_URL/_index_template/netology44-metrics" \
  "$ROOT_DIR/elasticsearch/bootstrap/metrics-template.json"
put_json "$ES_URL/_ingest/pipeline/netology44-nginx-error" \
  "$ROOT_DIR/elasticsearch/bootstrap/nginx-error-pipeline.json"

streams=(
  logs-nginx.access-netology44
  logs-nginx.error-netology44
  logs-demoapi.application-netology44
  logs-system.journal-netology44
  logs-agentdemo.application-netology44
  metrics-system.container-netology44
  metrics-agentdemo.prometheus-netology44
)

printf 'Ensuring data streams exist...\n'
for stream in "${streams[@]}"; do
  if curl -fsS "$ES_URL/_data_stream/$stream" >/dev/null 2>&1; then
    printf '  exists  %s\n' "$stream"
  else
    curl -fsS -X PUT "$ES_URL/_data_stream/$stream" >/dev/null
    printf '  created %s\n' "$stream"
  fi
done

printf 'Creating Kibana data views...\n'
create_view() {
  local id="$1" title="$2" name="$3"
  curl -fsS -X POST "$KIBANA_URL/api/data_views/data_view" \
    -H 'kbn-xsrf: true' \
    -H 'Content-Type: application/json' \
    -d "{\"data_view\":{\"id\":\"$id\",\"title\":\"$title\",\"name\":\"$name\",\"timeFieldName\":\"@timestamp\",\"allowNoIndex\":true},\"override\":true}" \
    >/dev/null
}

create_view netology44-logs 'logs-*-netology44' 'HW44 Logs'
create_view netology44-metrics 'metrics-*-netology44' 'HW44 Metrics'
create_view netology44-all '*-*-netology44' 'HW44 All telemetry'

curl -fsS -X POST "$KIBANA_URL/api/data_views/default" \
  -H 'kbn-xsrf: true' \
  -H 'Content-Type: application/json' \
  -d '{"data_view_id":"netology44-all","force":true}' >/dev/null

printf '\nBootstrap complete.\n'
printf 'Elasticsearch: %s\n' "$ES_URL"
printf 'Kibana:        %s\n' "$KIBANA_URL"
