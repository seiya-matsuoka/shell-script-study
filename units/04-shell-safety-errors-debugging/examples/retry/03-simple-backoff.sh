#!/usr/bin/env bash

attempt=0
max_attempts=3
delay=1

unstable_command() {
  ((attempt += 1))
  ((attempt >= 3))
}

while ((attempt < max_attempts)); do
  if unstable_command; then
    printf 'succeeded on attempt=%s\n' "$attempt"
    break
  fi

  printf 'failed attempt=%s; retry after %ss\n' "$attempt" "$delay" >&2

  # 高度な backoff ではなく、回数に応じて待ち時間を増やす基本だけを確認する。
  sleep "$delay"
  ((delay += 1))
done
