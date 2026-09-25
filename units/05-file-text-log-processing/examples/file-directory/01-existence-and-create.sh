#!/usr/bin/env bash

work_dir=$(mktemp -d)
target_dir="$work_dir/output"
target_file="$target_dir/result.txt"

# directory が存在しなければ作成する。
if [[ ! -d $target_dir ]]; then
  mkdir -p -- "$target_dir"
fi

printf '%s\n' 'result data' >"$target_file"

if [[ -f $target_file ]]; then
  printf 'created file=%s\n' "$target_file"
fi

rm -f -- "$target_file"
rmdir "$target_dir"
rmdir "$work_dir"
