#!/usr/bin/env bash

# CI では command の exit status が step の success / failure へつながる。
# この sample は同じ Script から success / failure を明示的に再現し、その違いを観察する。
mode=${1:-success}

case "$mode" in
success)
  printf '%s\n' 'command completed successfully'
  exit 0
  ;;
failure)
  printf '%s\n' 'command failed intentionally' >&2
  exit 1
  ;;
*)
  printf 'unknown mode: %s\n' "$mode" >&2
  exit 2
  ;;
esac
