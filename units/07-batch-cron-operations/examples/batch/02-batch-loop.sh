#!/usr/bin/env bash

work_dir=$(mktemp -d)

cleanup() {
  rm -rf -- "$work_dir"
}

trap cleanup EXIT

mkdir -p -- "$work_dir/input"

printf '%s\n' 'alpha' >"$work_dir/input/01.txt"
printf '%s\n' 'beta' >"$work_dir/input/02.txt"
printf '%s\n' 'gamma' >"$work_dir/input/03.txt"

# batch processing では、決められた input を順番に処理し、
# 人間の操作なしで最後まで完了できることが基本になる。
processed=0

for input_file in "$work_dir"/input/*.txt; do
  printf 'processing=%s\n' "$(basename -- "$input_file")"
  processed=$((processed + 1))
done

printf 'processed_count=%s\n' "$processed"
