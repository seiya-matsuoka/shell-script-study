#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
response=$(curl -sS "$base_url/api/health")
status=$(jq -r '.status' <<<"$response")

# JSON から取得した value を Shell condition へつなげる。
if [[ $status == UP ]]; then
  printf '%s\n' 'application is healthy'
else
  printf 'application is not healthy: %s\n' "$status" >&2
  exit 1
fi
