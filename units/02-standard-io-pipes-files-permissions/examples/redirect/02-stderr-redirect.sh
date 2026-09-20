#!/usr/bin/env bash

# `2>` は stderr を file へ書き出し、`2>>` は stderr を追記する。
# stdout と stderr は別の file descriptor なので、個別に redirect できる。

work_dir=$(mktemp -d)
error_file="$work_dir/error.log"

printf '%s\n' 'first error' >&2 2>"$error_file"
printf '%s\n' 'second error' >&2 2>>"$error_file"

cat "$error_file"

rm -f -- "$error_file"
rmdir "$work_dir"
