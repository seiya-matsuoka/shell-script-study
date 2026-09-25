#!/usr/bin/env bash

log_file=$(mktemp)
cat >"$log_file" <<'LOG'
2026-09-23 INFO previous day
2026-09-24 INFO current day
2026-09-24 ERROR current day failure
2026-09-25 INFO next day
LOG

target_date='2026-09-24'

# 日付が行頭に一定 format で記録される前提なら、grep で対象日を絞り込める。
grep "^${target_date} " "$log_file"

rm -f -- "$log_file"
