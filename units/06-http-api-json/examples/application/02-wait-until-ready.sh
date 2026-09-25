#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
max_attempts=5

# READY になるまで有限回 polling する。
for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  if ! response=$(curl -sS --max-time 2 "$base_url/api/ready"); then
    printf 'request failed on attempt=%s\n' "$attempt" >&2
    exit 1
  fi

  status=$(jq -r '.status' <<<"$response")

  if [[ $status == READY ]]; then
    printf 'application ready on attempt=%s\n' "$attempt"
    exit 0
  fi

  printf 'attempt=%s status=%s\n' "$attempt" "$status"

  if ((attempt < max_attempts)); then
    sleep 1
  fi
done

printf '%s\n' 'application did not become ready' >&2
exit 1
