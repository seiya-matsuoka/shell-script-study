#!/usr/bin/env bash

if ! command -v timeout >/dev/null 2>&1; then
  printf '%s\n' 'timeout command is not available' >&2
  exit 1
fi

# 外部処理が戻らない場合に備え、実行時間の上限を設ける。
# timeout の代表的な timeout 終了 status は 124。
if timeout 1 bash -c 'sleep 2'; then
  printf '%s\n' 'command completed'
else
  status=$?
  printf 'command timed out or failed: status=%s\n' "$status"
fi
