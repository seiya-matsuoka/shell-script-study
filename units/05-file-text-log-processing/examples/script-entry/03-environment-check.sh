#!/usr/bin/env bash

# environment variable は存在だけでなく、受け付ける値かも入口で検証する。
: "${UNIT05_MODE:?UNIT05_MODE is required}"

case "$UNIT05_MODE" in
development | production)
  printf 'mode=%s\n' "$UNIT05_MODE"
  ;;
*)
  printf 'unsupported UNIT05_MODE: %s\n' "$UNIT05_MODE" >&2
  exit 2
  ;;
esac
