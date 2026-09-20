#!/usr/bin/env bash

# Linux の permission を owner / group / others の区分と表示形式から確認する。

work_dir=$(mktemp -d)
sample_file="$work_dir/sample.txt"

printf '%s\n' 'permission sample' >"$sample_file"

# stat では owner・group と numeric notation の mode を確認する。
stat -c 'owner=%U group=%G mode=%a file=%n' "$sample_file"

# ls -l では owner / group と rwx の symbolic 表示をまとめて確認できる。
ls -l "$sample_file"

rm -f -- "$sample_file"
rmdir "$work_dir"
