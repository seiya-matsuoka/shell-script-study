#!/usr/bin/env bash

target_dir=${1:-.}

# variable 部分だけを quote し、*.log の glob expansion は残す。
for file in "$target_dir"/*.log; do
  # match が 0 件の場合、pattern 自体が残る Bash の挙動を考慮する。
  [[ -e $file ]] || continue
  printf 'file=%s\n' "$file"
done
