#!/usr/bin/env bash

# tee は stdin を受け取り、その内容を stdout へ流しながら file にも書き込む。
# redirect だけで file へ送る場合と違い、Terminal への表示を残しながら保存できる。

output_file=$(mktemp)

printf '%s\n' 'line through tee' | tee "$output_file"

# 保存された内容も通常の file として確認できる。
cat "$output_file"

rm -f -- "$output_file"
