#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
body_file=$(mktemp)
cleanup() { rm -f -- "$body_file"; }
trap cleanup EXIT

# HTTP status と application-level status の両方を確認する。
status_code=$(
  curl -sS --max-time 2 -o "$body_file" -w '%{http_code}' "$base_url/api/health"
)

if [[ $status_code != 200 ]]; then
  printf 'health endpoint HTTP status=%s\n' "$status_code" >&2
  exit 1
fi

health_status=$(jq -r '.status' "$body_file")
if [[ $health_status != UP ]]; then
  printf 'application health status=%s\n' "$health_status" >&2
  exit 1
fi

printf 'healthy: HTTP=%s application=%s\n' "$status_code" "$health_status"
