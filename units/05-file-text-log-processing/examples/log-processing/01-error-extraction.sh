#!/usr/bin/env bash

log_file=$(mktemp)
cat >"$log_file" <<'LOG'
2026-09-24T10:00:00 INFO request completed
2026-09-24T10:01:00 ERROR database unavailable
2026-09-24T10:02:00 WARN retrying
2026-09-24T10:03:00 ERROR request failed
LOG

# ERROR level の行だけを抽出する。
grep ' ERROR ' "$log_file"

rm -f -- "$log_file"
