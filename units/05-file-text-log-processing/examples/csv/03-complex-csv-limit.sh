#!/usr/bin/env bash

csv_file=$(mktemp)
cat >"$csv_file" <<'CSV'
name,score
"Doe, John",90
Alice,85
CSV

# 単純な IFS=',' は CSV の quote rule を理解しない。
# quoted field 内の comma まで delimiter として分割され、fields がずれる。
while IFS=',' read -r field1 field2 field3; do
  printf 'field1=<%s> field2=<%s> field3=<%s>\n' "$field1" "$field2" "${field3:-}"
done <"$csv_file"

# quoted comma、escaped quote、multiline field が必要なら CSV parser を持つ Python 等へ任せる。
rm -f -- "$csv_file"
