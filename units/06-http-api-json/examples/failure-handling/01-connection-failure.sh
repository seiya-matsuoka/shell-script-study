#!/usr/bin/env bash
unreachable_url='http://127.0.0.1:18081/api/user'

# HTTP response を受け取る前の connection failure を再現する。
if curl -sS --connect-timeout 1 "$unreachable_url" >/dev/null; then
  printf '%s\n' 'unexpected connection success' >&2
  exit 1
else
  status=$?
  printf 'curl exit status=%s\n' "$status"
fi
