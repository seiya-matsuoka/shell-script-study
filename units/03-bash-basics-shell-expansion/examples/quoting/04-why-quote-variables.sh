#!/usr/bin/env bash

work_dir=$(mktemp -d)
file_path="$work_dir/report 2026.txt"
printf '%s\n' 'sample content' >"$file_path"

# file path を variable から利用するときは、基本的に double quote して 1 argument として扱う。
cat "$file_path"

rm -f -- "$file_path"
rmdir "$work_dir"
