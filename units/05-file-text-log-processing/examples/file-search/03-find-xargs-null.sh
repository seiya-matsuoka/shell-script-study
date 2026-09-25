#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/alpha.txt" "$work_dir/report 2026.txt"

# -print0 と xargs -0 で NUL delimiter を共有し、空白を含む filename の境界を保持する。
find "$work_dir" -type f -name '*.txt' -print0 |
  xargs -0 -r printf 'found=<%s>\n'

rm -f -- "$work_dir/alpha.txt" "$work_dir/report 2026.txt"
rmdir "$work_dir"
