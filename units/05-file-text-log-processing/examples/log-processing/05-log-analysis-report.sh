#!/usr/bin/env bash

log_file=$(mktemp)
cat >"$log_file" <<'LOG'
2026-09-24 INFO api 200
2026-09-24 ERROR api 500
2026-09-24 ERROR web 502
2026-09-24 ERROR api 503
2026-09-24 INFO web 200
LOG

# 全体件数と ERROR 件数を出し、さらに service ごとの ERROR 件数を集計する。
total=$(wc -l <"$log_file")
errors=$(grep -c ' ERROR ' "$log_file")

printf 'total=%s errors=%s\n' "$total" "$errors"
printf '%s\n' 'errors by service:'

grep ' ERROR ' "$log_file" |
  awk '{ print $3 }' |
  sort |
  uniq -c |
  sort -nr

rm -f -- "$log_file"
