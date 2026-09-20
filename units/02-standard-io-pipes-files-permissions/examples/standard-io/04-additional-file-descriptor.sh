#!/usr/bin/env bash

# 0 / 1 / 2 以外の file descriptor も利用できることを、fd 3 で軽く確認する。
# より複雑な fd 操作はこの Unit の対象外とする。

output_file=$(mktemp)

# fd 3 を output_file への書き込み用として open する。
exec 3>"$output_file"

# stdout(fd 1) ではなく、明示的に fd 3 へ出力する。
printf '%s\n' 'written through fd 3' >&3

# 使用後は fd 3 を close する。
exec 3>&-

# fd 3 経由で書き込まれた内容を通常の stdout から確認する。
cat "$output_file"

rm -f -- "$output_file"
