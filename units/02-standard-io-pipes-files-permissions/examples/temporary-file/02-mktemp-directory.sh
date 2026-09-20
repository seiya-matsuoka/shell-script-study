#!/usr/bin/env bash

# `mktemp -d` は unique な temporary directory を作成する。
# 複数の temporary file をまとめて扱う場合などに利用できる。

temp_dir=$(mktemp -d)
first_file="$temp_dir/first.txt"
second_file="$temp_dir/second.txt"

printf 'temporary directory=%s\n' "$temp_dir"

printf '%s\n' 'first' >"$first_file"
printf '%s\n' 'second' >"$second_file"

ls -la "$temp_dir"

rm -f -- "$first_file" "$second_file"
rmdir "$temp_dir"
