#!/usr/bin/env bash

check_file=$(mktemp)

# `if command; then` は command の exit status をそのまま条件として扱える。
# success / failure を判定するためだけに `$?` を一度 variable へ入れる必要はない。
if grep -q 'target' "$check_file"; then
  printf '%s\n' 'target found'
else
  printf '%s\n' 'target not found'
fi

printf '%s\n' 'target value' >"$check_file"

if grep -q 'target' "$check_file"; then
  printf '%s\n' 'target found after update'
fi

rm -f -- "$check_file"
