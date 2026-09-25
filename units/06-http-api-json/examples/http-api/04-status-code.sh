#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
body_file=$(mktemp)
cleanup() { rm -f -- "$body_file"; }
trap cleanup EXIT

# response body と HTTP status code は別の情報として扱える。
status_code=$(
  curl -sS -o "$body_file" -w '%{http_code}' "$base_url/api/user"
)

printf 'status=%s\n' "$status_code"
printf '%s\n' 'body:'
cat "$body_file"
