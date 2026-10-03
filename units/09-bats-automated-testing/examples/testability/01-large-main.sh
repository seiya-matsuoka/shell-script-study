#!/usr/bin/env bash

# validation・data processing・file output が main flow に集まった例。
# 動作は単純でも、個々の判断だけを直接テストしにくい構造になる。
if (($# != 2)); then
  printf 'usage: %s INPUT_FILE OUTPUT_FILE\n' "$0" >&2
  exit 2
fi

input_file=$1
output_file=$2

if [[ ! -f $input_file ]]; then
  printf 'input file not found: %s\n' "$input_file" >&2
  exit 1
fi

line_count=$(wc -l <"$input_file")

if ((line_count == 0)); then
  status='EMPTY'
else
  status='READY'
fi

mkdir -p -- "$(dirname -- "$output_file")"

{
  printf 'status=%s\n' "$status"
  printf 'lines=%s\n' "$line_count"
} >"$output_file"

printf 'report=%s\n' "$output_file"
