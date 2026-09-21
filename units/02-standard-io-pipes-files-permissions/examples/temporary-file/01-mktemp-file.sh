#!/usr/bin/env bash

# /tmp などに temporary file を安全に作成する基本として mktemp を確認する。

# mktemp は名前の衝突を避けた unique な temporary file を作成し、その path を返す。
temp_file=$(mktemp)

printf 'temporary file=%s\n' "$temp_file"

# 作成された temporary file は通常の file と同じように読み書きできる。
printf '%s\n' 'temporary data' >"$temp_file"
cat "$temp_file"

# 不要になった temporary file は明示的に削除する。
rm -f -- "$temp_file"
