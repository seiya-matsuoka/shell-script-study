#!/usr/bin/env bash

# tee は stdin を stdout へ流しながら、同じ内容を file にも書き込める。

output_file=$(mktemp)

# redirect で stdout を file だけへ向ける場合と異なり、Terminal への表示を残しながら保存する。
printf '%s\n' 'line through tee' | tee "$output_file"

# tee が file に保存した内容も確認する。
cat "$output_file"

rm -f -- "$output_file"
