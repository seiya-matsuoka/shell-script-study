#!/usr/bin/env bash

if [[ -n ${UNIT07_WORK_DIR:-} ]]; then
  work_dir=$UNIT07_WORK_DIR
  created_temp_dir=false
  mkdir -p -- "$work_dir"
else
  work_dir=$(mktemp -d)
  created_temp_dir=true
fi

cleanup() {
  if [[ $created_temp_dir == true ]]; then
    rm -rf -- "$work_dir"
  fi
}

trap cleanup EXIT

output_file="$work_dir/status.txt"

# append ではなく「期待する最終状態」を書き直すことで、
# 同じ Script を再実行しても duplicate data が増えない形を作る。
printf '%s\n' 'status=completed' >"$output_file"

printf 'output=%s\n' "$output_file"
cat "$output_file"
