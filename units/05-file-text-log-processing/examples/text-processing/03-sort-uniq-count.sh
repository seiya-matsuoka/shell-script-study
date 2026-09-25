#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
WARN
INFO
ERROR
WARN
ERROR
ERROR
DATA

# uniq は連続重複を扱うため、全体を grouping する場合は先に sort する。
sort "$input_file" |
  uniq -c |
  sort -nr

printf 'total lines=%s\n' "$(wc -l <"$input_file")"
rm -f -- "$input_file"
