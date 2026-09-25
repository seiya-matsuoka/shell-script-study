#!/usr/bin/env bash

csv_file=$(mktemp)
cat >"$csv_file" <<'CSV'
id,comment
1,"first line
second line"
2,"single line"
CSV

line_number=0

# read は physical line ごとに読むため、quoted multiline field を 1 logical record として理解できない。
while IFS= read -r line; do
  ((line_number += 1))
  printf 'line %s: %s\n' "$line_number" "$line"
done <"$csv_file"

printf 'physical line count=%s\n' "$line_number"
rm -f -- "$csv_file"
