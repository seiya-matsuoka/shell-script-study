#!/usr/bin/env bash

input_file=$(mktemp)
cat >"$input_file" <<'DATA'
2026-09-24 INFO api GET /health 200
2026-09-24 ERROR api POST /orders 500
2026-09-24 INFO web GET / 200
2026-09-24 ERROR api GET /users 503
2026-09-24 WARN web GET /legacy 301
DATA

# ERROR 行だけを絞り、service field を抽出して件数を grouping する。
grep ' ERROR ' "$input_file" |
  awk '{ print $3 }' |
  sort |
  uniq -c |
  sort -nr

rm -f -- "$input_file"
