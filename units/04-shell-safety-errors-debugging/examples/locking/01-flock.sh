#!/usr/bin/env bash

work_dir=$(mktemp -d)
lock_file="$work_dir/job.lock"

if ! command -v flock >/dev/null 2>&1; then
  printf '%s\n' 'flock is not available' >&2
  rmdir "$work_dir"
  exit 1
fi

# fd 9 を lock file に接続し、この process が lock を保持する。
exec 9>"$lock_file"

if ! flock -n 9; then
  printf '%s\n' 'could not acquire first lock' >&2
  exit 1
fi

printf '%s\n' 'first lock acquired'

# 同じ lock file に対する別 process の non-blocking lock は失敗する。
if flock -n "$lock_file" -c 'printf "%s\n" "unexpected second lock"'; then
  printf '%s\n' 'second lock unexpectedly acquired' >&2
  exit 1
else
  printf '%s\n' 'second execution blocked by lock'
fi

flock -u 9
exec 9>&-

rm -f -- "$lock_file"
rmdir "$work_dir"
