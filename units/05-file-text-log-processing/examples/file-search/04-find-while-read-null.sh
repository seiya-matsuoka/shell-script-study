#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/alpha.txt" "$work_dir/report 2026.txt"

# read -d '' で NUL-delimited path を 1 件ずつ読む。
find "$work_dir" -type f -name '*.txt' -print0 |
  while IFS= read -r -d '' file_path; do
    printf 'file=<%s>\n' "$(basename -- "$file_path")"
  done

rm -f -- "$work_dir/alpha.txt" "$work_dir/report 2026.txt"
rmdir "$work_dir"
