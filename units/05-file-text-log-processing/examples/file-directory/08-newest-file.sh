#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch -d '2 hours ago' "$work_dir/old.txt"
touch -d '1 hour ago' "$work_dir/middle.txt"
touch "$work_dir/new.txt"

# find で mtime を数値化し、sort → head → cut で最新 file を 1 件選ぶ。
newest=$(
  find "$work_dir" -maxdepth 1 -type f -name '*.txt' -printf '%T@ %p\n' |
    sort -nr |
    head -n 1 |
    cut -d ' ' -f 2-
)

printf 'newest=%s\n' "$(basename -- "$newest")"
rm -f -- "$work_dir/old.txt" "$work_dir/middle.txt" "$work_dir/new.txt"
rmdir "$work_dir"
