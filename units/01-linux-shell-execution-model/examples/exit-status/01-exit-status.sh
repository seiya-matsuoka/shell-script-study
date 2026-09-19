#!/usr/bin/env bash

# command は終了時に exit status を返す。
# 基本的に 0 は成功、non-zero は失敗やその他の状態を表す。

true
true_status=$?

false
false_status=$?

# non-zero は 1 だけではなく、command が意味を持たせた別の値も利用できる。
bash -c 'exit 7'
explicit_status=$?

# ここでの printf は、取得した exit status 自体を観察するための出力。
printf 'true=%s\n' "$true_status"
printf 'false=%s\n' "$false_status"
printf 'explicit=%s\n' "$explicit_status"
