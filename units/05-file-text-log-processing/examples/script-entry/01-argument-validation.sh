#!/usr/bin/env bash

# Script の入口で required argument を検証し、本処理の前に不足を明確にする。
input_file=${1:-}

if [[ -z $input_file ]]; then
  printf 'usage: %s <input-file>\n' "$0" >&2
  exit 2
fi

if [[ ! -f $input_file ]]; then
  printf 'input file not found: %s\n' "$input_file" >&2
  exit 1
fi

printf 'validated input=%s\n' "$input_file"
