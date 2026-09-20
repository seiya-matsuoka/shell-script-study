#!/usr/bin/env bash

# 0 / 1 / 2 以外の file descriptor も利用できる。
# ここでは fd 3 を一時 file へ接続し、stdout とは別の出力先として使う。
# より複雑な fd 操作はこの Unit の対象外とする。

output_file=$(mktemp)

exec 3>"$output_file"
printf '%s\n' 'written through fd 3' >&3
exec 3>&-

cat "$output_file"

rm -f -- "$output_file"
