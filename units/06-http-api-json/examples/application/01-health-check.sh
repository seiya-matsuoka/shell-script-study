#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
body_file=$(mktemp)

cleanup() {
  rm -f -- "$body_file"
}

trap cleanup EXIT

# response body は application-level status の確認に使うため file へ保存し、
# HTTP status code は Shell variable として別に受け取る。
status_code=$(
  curl -sS \
    --max-time 2 \
    -o "$body_file" \
    -w '%{http_code}' \
    "$base_url/api/health"
)

# まず HTTP level で request が成功していることを確認する。
if [[ $status_code != 200 ]]; then
  printf 'health endpoint HTTP status=%s\n' "$status_code" >&2
  exit 1
fi

# HTTP 200 でも application が期待する状態とは限らないため、
# response JSON の status を jq で取得して二段階目の判定を行う。
health_status=$(jq -r '.status' "$body_file")

if [[ $health_status != UP ]]; then
  printf 'application health status=%s\n' "$health_status" >&2
  exit 1
fi

printf 'healthy: HTTP=%s application=%s\n' "$status_code" "$health_status"
