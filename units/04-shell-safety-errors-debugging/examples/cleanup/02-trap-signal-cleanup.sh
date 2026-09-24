#!/usr/bin/env bash

temp_dir=$(mktemp -d)
marker_file="$temp_dir/marker"

cleanup() {
  rm -f -- "$marker_file"
  rmdir -- "$temp_dir" 2>/dev/null || true
}

handle_term() {
  # signal handler では cleanup を重複実行せず、exit して EXIT trap に cleanup を一元化する。
  printf '%s\n' 'received SIGTERM' >&2
  exit 143
}

trap cleanup EXIT
trap handle_term TERM

printf '%s\n' 'temporary data' >"$marker_file"
printf 'PID=%s temp_dir=%s\n' "$BASHPID" "$temp_dir"

# README では UNIT04_WAIT_FOR_SIGNAL=true で待機させ、SIGTERM 時の cleanup も確認できる。
if [[ ${UNIT04_WAIT_FOR_SIGNAL:-false} == true ]]; then
  while :; do
    sleep 1
  done
fi
