#!/usr/bin/env bash

csv_file=$(mktemp)
cat >"$csv_file" <<'CSV'
alice,engineering,120
bob,sales,95
carol,engineering,130
CSV

process_record() {
  local name=$1
  local department=$2
  local points=$3

  if [[ $department == engineering ]]; then
    printf '%s:%s\n' "$name" "$points"
  fi
}

# read で分けた fields を、別処理へ独立した arguments として渡す。
while IFS=',' read -r name department points; do
  process_record "$name" "$department" "$points"
done <"$csv_file"

rm -f -- "$csv_file"
