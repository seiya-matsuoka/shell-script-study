#!/usr/bin/env bash

temp_dir=$(mktemp -d)
temp_file="$temp_dir/data.txt"

cleanup() {
  # EXIT trap では正常終了・error 終了のどちらでも cleanup を実行できる。
  rm -f -- "$temp_file"
  rmdir -- "$temp_dir" 2>/dev/null || true
}

trap cleanup EXIT

printf '%s\n' 'temporary data' >"$temp_file"
printf 'created=%s\n' "$temp_file"

# この Script は正常終了するが、途中で exit しても EXIT trap は実行される。
