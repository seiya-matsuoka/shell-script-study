#!/usr/bin/env bash

if (($# != 2)); then
  printf 'usage: %s FILE VALUE\n' "$0" >&2
  exit 2
fi

target_file=$1
value=$2

if [[ ! -f $target_file ]]; then
  printf 'target file not found: %s\n' "$target_file" >&2
  exit 1
fi

printf '%s\n' "$value" >>"$target_file"
