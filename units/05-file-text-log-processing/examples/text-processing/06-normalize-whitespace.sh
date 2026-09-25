#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
  alpha      beta
gamma	delta
DATA

# sed で行頭・行末の whitespace を削除し、tr -s で連続 horizontal whitespace をまとめる。
sed 's/^[[:space:]]*//; s/[[:space:]]*$//' "$input_file" |
  tr -s '[:blank:]' ' '

rm -f -- "$input_file"
