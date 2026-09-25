#!/usr/bin/env bash

log_file=$(mktemp)
cat >"$log_file" <<'LOG'
INFO start
ERROR database
ERROR timeout
WARN retry
ERROR timeout
LOG

# grep -c で条件に一致する行数を直接数える。
error_count=$(grep -c '^ERROR ' "$log_file")
printf 'error count=%s\n' "$error_count"

rm -f -- "$log_file"
