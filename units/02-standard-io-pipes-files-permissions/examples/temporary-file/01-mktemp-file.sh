#!/usr/bin/env bash

# /tmp は temporary data の保存先としてよく利用される directory。
# mktemp を使うと、名前の衝突を避けた temporary file を安全に作成できる。

temp_file=$(mktemp)

printf 'temporary file=%s\n' "$temp_file"

printf '%s\n' 'temporary data' >"$temp_file"
cat "$temp_file"

rm -f -- "$temp_file"
