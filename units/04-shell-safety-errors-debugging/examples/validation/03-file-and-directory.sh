#!/usr/bin/env bash

work_dir=$(mktemp -d)
input_file="$work_dir/input.txt"
output_dir="$work_dir/output"

printf '%s\n' 'sample' >"$input_file"
mkdir "$output_dir"

# file / directory は「path があるか」だけでなく、期待する種類かを確認する。
if [[ ! -f $input_file ]]; then
  printf 'input file not found: %s\n' "$input_file" >&2
  exit 1
fi

if [[ ! -d $output_dir ]]; then
  printf 'output directory not found: %s\n' "$output_dir" >&2
  exit 1
fi

printf '%s\n' 'file and directory validation passed'

rm -f -- "$input_file"
rmdir "$output_dir"
rmdir "$work_dir"
