#!/usr/bin/env bash

# 定期実行される Script は、実行途中で人間の入力を待つのではなく、
# argument や environment variable などから必要な情報を受け取れる形にする。
input_file=${1:-}

if [[ -z $input_file ]]; then
  printf 'usage: %s INPUT_FILE\n' "$0" >&2
  exit 2
fi

if [[ ! -f $input_file ]]; then
  printf 'input file not found: %s\n' "$input_file" >&2
  exit 1
fi

line_count=$(wc -l <"$input_file")
printf 'processed file=%s lines=%s\n' "$input_file" "$line_count"
