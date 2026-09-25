#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
max_attempts=3

for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  body_file=$(mktemp)

  # response body と HTTP status code を分離して受け取り、
  # connection-level failure と HTTP-level failure を別々に判断する。
  if status_code=$(
    curl -sS \
      --max-time 2 \
      -o "$body_file" \
      -w '%{http_code}' \
      "$base_url/api/unstable"
  ); then
    :
  else
    curl_status=$?
    rm -f -- "$body_file"
    printf 'connection-level failure: curl status=%s\n' "$curl_status" >&2
    exit "$curl_status"
  fi

  # HTTP 200 なら response body を利用して正常終了する。
  if [[ $status_code == 200 ]]; then
    printf 'success on attempt=%s\n' "$attempt"
    cat "$body_file"
    printf '\n'
    rm -f -- "$body_file"
    exit 0
  fi

  printf 'attempt=%s HTTP status=%s\n' "$attempt" "$status_code" >&2
  rm -f -- "$body_file"

  # この学習例では temporary failure として 503 だけを retry 対象にする。
  # 503 以外、または最大回数に達した場合は retry を終了する。
  if [[ $status_code != 503 || $attempt -eq $max_attempts ]]; then
    printf '%s\n' 'retry stopped' >&2
    exit 1
  fi

  # failure 直後に request を連打しないよう、次の試行まで待機する。
  sleep 1
done
