#!/usr/bin/env bash

# 学習用の問題コード。
# directory 部分を quote しない glob は、directory 名に space がある場合などに壊れやすい。
target_dir=${1:-.}

for file in $target_dir/*.log; do
  printf 'file=%s\n' "$file"
done
