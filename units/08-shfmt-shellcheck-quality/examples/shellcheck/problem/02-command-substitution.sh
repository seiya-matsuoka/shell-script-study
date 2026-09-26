#!/usr/bin/env bash

# 学習用の問題コード。
# command substitution の結果を for へそのまま展開すると、
# space や newline による word splitting の影響を受ける。
files=$(printf '%s\n' 'alpha report.txt' 'beta.txt')

for file in $(printf '%s\n' "$files"); do
  printf 'file=%s\n' "$file"
done
