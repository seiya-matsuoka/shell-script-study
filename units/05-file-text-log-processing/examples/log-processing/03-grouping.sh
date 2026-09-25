#!/usr/bin/env bash

log_file=$(mktemp)
cat >"$log_file" <<'LOG'
ERROR database connection_failed
ERROR api timeout
ERROR database connection_failed
ERROR api unauthorized
ERROR api timeout
LOG

# service field を awk で取り出し、sort + uniq -c で grouping する。
awk '$1 == "ERROR" { print $2 }' "$log_file" |
  sort |
  uniq -c |
  sort -nr

rm -f -- "$log_file"
