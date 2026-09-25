#!/usr/bin/env bash

csv_file=$(mktemp)
cat >"$csv_file" <<'CSV'
name,score,active
alice,90,true
bob,75,false
carol,88,true
CSV

# field 内に comma / newline / quote rule がない単純な CSV なら、IFS と read で扱える場合がある。
{
  IFS= read -r header

  while IFS=',' read -r name score active; do
    printf 'name=%s score=%s active=%s\n' "$name" "$score" "$active"
  done
} <"$csv_file"

rm -f -- "$csv_file"
