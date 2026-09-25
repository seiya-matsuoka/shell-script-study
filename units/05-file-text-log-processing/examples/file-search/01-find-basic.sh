#!/usr/bin/env bash

work_dir=$(mktemp -d)
mkdir "$work_dir/sub"
touch "$work_dir/a.txt" "$work_dir/b.log" "$work_dir/sub/c.txt"

# find で directory tree から条件に一致する file を探索する。
find "$work_dir" -type f -name '*.txt' -print | sort

rm -f -- "$work_dir/a.txt" "$work_dir/b.log" "$work_dir/sub/c.txt"
rmdir "$work_dir/sub" "$work_dir"
