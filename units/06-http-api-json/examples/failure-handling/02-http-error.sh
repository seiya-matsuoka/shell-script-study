#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}

# -f により HTTP 4xx / 5xx を curl failure として扱う。
if curl -sS -f "$base_url/api/status/404" >/dev/null; then
  printf '%s\n' 'unexpected HTTP success' >&2
  exit 1
else
  status=$?
  printf 'HTTP error detected by curl: exit status=%s\n' "$status"
fi
