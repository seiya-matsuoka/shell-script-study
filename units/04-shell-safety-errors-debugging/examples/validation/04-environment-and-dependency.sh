#!/usr/bin/env bash

# 必須 environment variable は、処理開始時に確認すると失敗理由を早く明確にできる。
: "${UNIT04_CONFIG:?UNIT04_CONFIG is required}"

# external command を利用する前に command -v で存在を確認できる。
if ! command -v grep >/dev/null 2>&1; then
  printf '%s\n' 'required command not found: grep' >&2
  exit 1
fi

printf 'config=%s\n' "$UNIT04_CONFIG"
printf '%s\n' 'dependency grep is available'
