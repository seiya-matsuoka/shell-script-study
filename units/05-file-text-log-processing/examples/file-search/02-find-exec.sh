#!/usr/bin/env bash

work_dir=$(mktemp -d)
mkdir "$work_dir/sub"
printf '%s\n' 'alpha' >"$work_dir/a.txt"
printf '%s\n' 'beta' >"$work_dir/sub/b.txt"

# -exec ... {} + は、find の検索結果をまとめて command の arguments として渡す。
find "$work_dir" -type f -name '*.txt' -exec wc -l -- {} +

rm -f -- "$work_dir/a.txt" "$work_dir/sub/b.txt"
rmdir "$work_dir/sub" "$work_dir"
