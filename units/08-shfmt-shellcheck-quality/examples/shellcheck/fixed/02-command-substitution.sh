#!/usr/bin/env bash

files=$(printf '%s\n' 'alpha report.txt' 'beta.txt')

# line 単位の data を扱う意図を明確にし、IFS= / read -r でそのまま受け取る。
while IFS= read -r file; do
  printf 'file=%s\n' "$file"
done <<<"$files"
