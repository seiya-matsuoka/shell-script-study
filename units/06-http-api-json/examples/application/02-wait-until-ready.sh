#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
max_attempts=5

# READY になるまで有限回 polling する。
for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  # 各 request に timeout を設定し、1 回の確認で長時間停止しないようにする。
  if ! response=$(curl -sS --max-time 2 "$base_url/api/ready"); then
    printf 'request failed on attempt=%s\n' "$attempt" >&2
    exit 1
  fi

  # response 全体ではなく readiness 判定に必要な property だけを取得する。
  status=$(jq -r '.status' <<<"$response")

  if [[ $status == READY ]]; then
    printf 'application ready on attempt=%s\n' "$attempt"
    exit 0
  fi

  printf 'attempt=%s status=%s\n' "$attempt" "$status"

  # 最大試行回数に達するまでは、次の polling まで少し待機する。
  if ((attempt < max_attempts)); then
    sleep 1
  fi
done

printf '%s\n' 'application did not become ready' >&2
exit 1
