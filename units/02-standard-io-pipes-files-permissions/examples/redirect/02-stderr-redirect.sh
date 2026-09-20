#!/usr/bin/env bash

# stdout と stderr は別の file descriptor なので、stderr だけを個別に redirect できる。

work_dir=$(mktemp -d)
error_file="$work_dir/error.log"

# 2> は stderr(fd 2) を file へ向け、既存内容がある場合は上書きする。
printf '%s\n' 'first error' >&2 2>"$error_file"

# 2>> は stderr を同じ file の末尾へ追記する。
printf '%s\n' 'second error' >&2 2>>"$error_file"

# redirect された stderr の内容を file から確認する。
cat "$error_file"

rm -f -- "$error_file"
rmdir "$work_dir"
