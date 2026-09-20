#!/usr/bin/env bash

# stdout / stdin の基本的な redirect を、同じ file を使って比較する。

work_dir=$(mktemp -d)
output_file="$work_dir/output.txt"

# > は stdout を file へ向ける。既存内容がある場合は上書きする。
printf '%s\n' 'first line' >"$output_file"

# >> は stdout を同じ file の末尾へ追記する。
printf '%s\n' 'second line' >>"$output_file"

# < は file の内容を command の stdin として接続する。
cat <"$output_file"

rm -f -- "$output_file"
rmdir "$work_dir"
