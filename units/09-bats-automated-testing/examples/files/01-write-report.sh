#!/usr/bin/env bash

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

output_dir=$(dirname -- "$output_file")
mkdir -p -- "$output_dir"

line_count=$(wc -l <"$input_file")
first_line=$(head -n 1 -- "$input_file")

{
  printf 'source=%s\n' "$(basename -- "$input_file")"
  printf 'lines=%s\n' "$line_count"
  printf 'first=%s\n' "$first_line"
} >"$output_file"

printf 'report=%s\n' "$output_file"
