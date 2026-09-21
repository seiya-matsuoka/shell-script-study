#!/usr/bin/env bash

# 複数の temporary file をまとめて扱う例として、mktemp -d で temporary directory を作成する。

# mktemp -d は名前の衝突を避けた unique な temporary directory を作成し、その path を返す。
temp_dir=$(mktemp -d)
first_file="$temp_dir/first.txt"
second_file="$temp_dir/second.txt"

printf 'temporary directory=%s\n' "$temp_dir"

# 一つの temporary directory 配下で複数 file を管理する。
printf '%s\n' 'first' >"$first_file"
printf '%s\n' 'second' >"$second_file"

ls -la "$temp_dir"

# directory を削除する前に、配下の temporary file を削除する。
rm -f -- "$first_file" "$second_file"
rmdir "$temp_dir"
