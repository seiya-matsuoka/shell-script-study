#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
max_attempts=3

for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  body_file=$(mktemp)

  if status_code=$(
    curl -sS --max-time 2 -o "$body_file" -w '%{http_code}' "$base_url/api/unstable"
  ); then
    :
  else
    curl_status=$?
    rm -f -- "$body_file"
    printf 'connection-level failure: curl status=%s\n' "$curl_status" >&2
    exit "$curl_status"
  fi

  if [[ $status_code == 200 ]]; then
    printf 'success on attempt=%s\n' "$attempt"
    cat "$body_file"
    printf '\n'
    rm -f -- "$body_file"
    exit 0
  fi

  printf 'attempt=%s HTTP status=%s\n' "$attempt" "$status_code" >&2
  rm -f -- "$body_file"

  if [[ $status_code != 503 || $attempt -eq $max_attempts ]]; then
    printf '%s\n' 'retry stopped' >&2
    exit 1
  fi

  sleep 1
done
