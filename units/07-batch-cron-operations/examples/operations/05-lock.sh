#!/usr/bin/env bash

command -v flock >/dev/null || {
  printf '%s\n' 'flock is required' >&2
  exit 1
}

lock_file=${UNIT07_LOCK_FILE:-/tmp/unit07-batch.lock}

# file descriptor 9 を lock file に割り当て、
# non-blocking lock を取得できなければ「既に別 process が実行中」と判断する。
exec 9>"$lock_file"

if ! flock -n 9; then
  printf '%s\n' 'another instance is already running' >&2
  exit 1
fi

printf 'lock acquired pid=%s\n' "$$"
sleep "${UNIT07_LOCK_HOLD_SECONDS:-2}"
printf '%s\n' 'job finished'
