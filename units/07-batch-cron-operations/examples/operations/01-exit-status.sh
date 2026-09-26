#!/usr/bin/env bash

mode=${1:-success}

# scheduler や呼び出し元は Script の exit status を使って
# success / failure を判断できるため、結果に合った status で終了する。
case "$mode" in
success)
  printf '%s\n' 'job completed successfully'
  exit 0
  ;;
failure)
  printf '%s\n' 'job failed' >&2
  exit 1
  ;;
*)
  printf 'unknown mode: %s\n' "$mode" >&2
  exit 2
  ;;
esac
