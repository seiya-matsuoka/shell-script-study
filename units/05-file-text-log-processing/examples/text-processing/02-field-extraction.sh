#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
alice,engineering,120
bob,sales,95
carol,engineering,130
DATA

# cut は単純な delimiter-separated data から field を取り出す。
printf '%s\n' 'departments:'
cut -d ',' -f 2 "$input_file" | sort -u

# awk は field の抽出・条件・集計を一つの処理として表現できる。
printf '%s\n' 'engineering total:'
awk -F ',' '$2 == "engineering" { total += $3 } END { print total }' "$input_file"

rm -f -- "$input_file"
