#!/usr/bin/env bash

log_file=$(mktemp)

log() {
  local level=$1
  shift

  # timestamp / level / message の format を固定すると、後続の grep / awk で解析しやすい。
  printf '%s %-5s %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$level" "$*" |
    tee -a "$log_file"
}

log INFO 'job started'
log WARN 'sample warning'
log INFO 'job finished'

printf '%s\n' 'saved log:'
cat "$log_file"

rm -f -- "$log_file"
