#!/usr/bin/env bash

attempt=0
max_attempts=3

unstable_command() {
  ((attempt += 1))
  # 学習用に最初の 2 回だけ failure を返し、3 回目で success にする。
  ((attempt >= 3))
}

while ((attempt < max_attempts)); do
  if unstable_command; then
    printf 'succeeded on attempt=%s\n' "$attempt"
    break
  fi

  printf 'failed attempt=%s\n' "$attempt" >&2

  if ((attempt >= max_attempts)); then
    printf '%s\n' 'retry limit reached' >&2
    exit 1
  fi

  sleep 1
done
