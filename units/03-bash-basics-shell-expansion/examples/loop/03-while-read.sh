#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
first line
second line with spaces
backslash \ stays
DATA

# `IFS=` は行頭・行末の空白を IFS によって削らないために使う。
# `read -r` は backslash を escape として処理せず、そのまま読み取る。
while IFS= read -r line; do
  printf '<%s>\n' "$line"
done <"$input_file"

rm -f -- "$input_file"
