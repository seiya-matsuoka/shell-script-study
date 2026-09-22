#!/usr/bin/env bash

# "$@" と for を組み合わせると、受け取った argument を順番に安全に処理できる。
for argument in "$@"; do
  printf '<%s>\n' "$argument"
done
