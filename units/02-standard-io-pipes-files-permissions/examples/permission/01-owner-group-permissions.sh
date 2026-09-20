#!/usr/bin/env bash

# Linux の permission は owner / group / others に分けて確認する。
# stat で owner・group・numeric permission を確認し、ls -l で symbolic 表示も確認する。

work_dir=$(mktemp -d)
sample_file="$work_dir/sample.txt"

printf '%s\n' 'permission sample' >"$sample_file"

stat -c 'owner=%U group=%G mode=%a file=%n' "$sample_file"
ls -l "$sample_file"

rm -f -- "$sample_file"
rmdir "$work_dir"
