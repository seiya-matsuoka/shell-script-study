#!/usr/bin/env bash

# command failure を無視すると、後続処理が「成功した前提」で進んでしまう可能性がある。
# 学習用に child Bash で failure を発生させ、Script 全体には影響を残さず比較する。

printf '%s\n' '--- failure を明示的に扱わない例 ---'
bash -c '
  false
  printf "%s\n" "processing continued after failure"
'

printf '%s\n' '--- failure を明示的に扱う例 ---'
if false; then
  printf '%s\n' 'command succeeded'
else
  status=$?
  printf 'command failed: status=%s\n' "$status" >&2
fi
