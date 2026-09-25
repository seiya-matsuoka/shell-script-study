#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}

# server は 2 秒待つため、--max-time 1 で timeout する。
if curl -sS --max-time 1 "$base_url/api/slow" >/dev/null; then
  printf '%s\n' 'unexpected completion before timeout' >&2
  exit 1
else
  status=$?
  printf 'curl timeout/failure status=%s\n' "$status"
fi
