#!/usr/bin/env bash

max_attempts=3
timeout_seconds=1
attempt_file=$(mktemp)

cleanup() {
  rm -f -- "$attempt_file"
}

trap cleanup EXIT
printf '0\n' >"$attempt_file"

run_once() {
  local current

  current=$(<"$attempt_file")
  current=$((current + 1))
  printf '%s\n' "$current" >"$attempt_file"

  # 1・2 回目は timeout を超える処理、3 回目はすぐ成功する処理を再現する。
  if ((current < 3)); then
    sleep 2
  else
    printf 'completed on attempt=%s\n' "$current"
  fi
}

for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  # 1 回の処理が長時間停止しないよう timeout で上限を設ける。
  if timeout "$timeout_seconds" bash -c "$(declare -f run_once); attempt_file=$(printf '%q' "$attempt_file"); run_once"; then
    printf 'job success attempt=%s\n' "$attempt"
    exit 0
  fi

  status=$?
  printf 'attempt=%s failed status=%s\n' "$attempt" "$status" >&2

  if ((attempt < max_attempts)); then
    sleep 1
  fi
done

printf '%s\n' 'job failed after retries' >&2
exit 1
