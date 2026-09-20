#!/usr/bin/env bash

# `>` は stdout を file へ書き出し、既存内容がある場合は上書きする。
# `>>` は stdout を file の末尾へ追記する。
# `<` は file を command の stdin として接続する。

work_dir=$(mktemp -d)
output_file="$work_dir/output.txt"

printf '%s\n' 'first line' >"$output_file"
printf '%s\n' 'second line' >>"$output_file"

cat <"$output_file"

rm -f -- "$output_file"
rmdir "$work_dir"
