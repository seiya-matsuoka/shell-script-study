#!/usr/bin/env bash

# $0 は Script 自身の呼び出し名、$1 以降は positional parameter、$# は個数を表す。
printf 'script=%s\n' "$0"
printf 'count=%s\n' "$#"

# "$@" は各 positional parameter を独立した argument のまま展開する。
index=1
for argument in "$@"; do
  printf 'arg%s=<%s>\n' "$index" "$argument"
  ((index += 1))
done
