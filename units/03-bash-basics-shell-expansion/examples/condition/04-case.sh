#!/usr/bin/env bash

command_name=${1:-start}

# case は 1 つの値を複数 pattern と照合する処理に向いている。
case "$command_name" in
start) printf '%s\n' 'starting' ;;
stop) printf '%s\n' 'stopping' ;;
restart) printf '%s\n' 'restarting' ;;
*)
  printf 'unknown command: %s\n' "$command_name" >&2
  exit 1
  ;;
esac
