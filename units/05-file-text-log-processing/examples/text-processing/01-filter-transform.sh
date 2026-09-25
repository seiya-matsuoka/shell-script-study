#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
INFO user=alice action=login
ERROR user=bob action=upload
ERROR user=carol action=delete
DATA

# grep で対象行を絞り、sed で prefix を除去し、tr で文字種を変換する。
grep '^ERROR ' "$input_file" |
  sed 's/^ERROR //' |
  tr '[:upper:]' '[:lower:]'

rm -f -- "$input_file"
