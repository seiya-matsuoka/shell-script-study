#!/usr/bin/env bash

# relative path は current working directory を基準に解釈される。
# absolute path は `/` から始まり、current working directory に依存せず対象を表す。

work_dir=$(mktemp -d)
mkdir "$work_dir/subdir"
printf '%s\n' 'sample data' >"$work_dir/subdir/sample.txt"

cd "$work_dir"

# pwd で現在の working directory を確認する。
pwd

# current working directory を基準にした relative path。
cat "subdir/sample.txt"

# / から始まる absolute path。
cat "$work_dir/subdir/sample.txt"

cd /
rm -f -- "$work_dir/subdir/sample.txt"
rmdir "$work_dir/subdir"
rmdir "$work_dir"
