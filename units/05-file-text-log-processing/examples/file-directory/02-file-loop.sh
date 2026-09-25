#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/alpha.txt" "$work_dir/beta.txt" "$work_dir/gamma.log"

# fixed directory 部分は quote し、glob 部分だけ pathname expansion させる。
for file_path in "$work_dir"/*.txt; do
  printf 'txt file=%s\n' "$(basename -- "$file_path")"
done

rm -f -- "$work_dir/alpha.txt" "$work_dir/beta.txt" "$work_dir/gamma.log"
rmdir "$work_dir"
