#!/usr/bin/env bash

# relative path と absolute path の違いを、同じ file を 2 通りの path で参照して確認する。

work_dir=$(mktemp -d)
mkdir "$work_dir/subdir"
printf '%s\n' 'sample data' >"$work_dir/subdir/sample.txt"

# relative path の基準を明確にするため、temporary directory へ移動する。
cd "$work_dir"

# pwd で現在の working directory を確認する。
pwd

# current working directory を基準にした relative path。
cat "subdir/sample.txt"

# / から始まる absolute path は current working directory に依存しない。
cat "$work_dir/subdir/sample.txt"

# cleanup 対象の directory 自体を削除する前に、その外へ移動する。
cd /
rm -f -- "$work_dir/subdir/sample.txt"
rmdir "$work_dir/subdir"
rmdir "$work_dir"
