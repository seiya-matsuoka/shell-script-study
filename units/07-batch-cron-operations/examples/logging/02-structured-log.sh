#!/usr/bin/env bash

log() {
  local level=$1
  shift

  # 後から追跡できるよう、timestamp / level / message を一定 format で出力する。
  printf '%s %-5s %s\n' \
    "$(date '+%Y-%m-%dT%H:%M:%S%z')" \
    "$level" \
    "$*"
}

log INFO 'batch started'
log INFO 'processing item=alpha'
log WARN 'sample warning for item=beta'
log INFO 'batch finished'
