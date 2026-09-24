#!/usr/bin/env bash

work_dir=$(mktemp -d)
target_dir="$work_dir/target"
other_dir="$work_dir/other"

mkdir "$target_dir" "$other_dir"
touch "$target_dir/a.tmp" "$target_dir/b.tmp" "$target_dir/keep.txt"
touch "$other_dir/do-not-touch.tmp"

# destructive operation に wildcard を使う場合は、対象 directory を明示して scope を狭くする。
# 固定 directory 部分だけを quote し、glob 部分だけ Shell に展開させる。
rm -f -- "$target_dir"/*.tmp

printf 'target tmp count=%s\n' "$(find "$target_dir" -maxdepth 1 -name '*.tmp' -type f | wc -l)"
printf 'other tmp count=%s\n' "$(find "$other_dir" -maxdepth 1 -name '*.tmp' -type f | wc -l)"

rm -f -- "$target_dir/keep.txt" "$other_dir/do-not-touch.tmp"
rmdir "$target_dir" "$other_dir" "$work_dir"
