#!/usr/bin/env bash

work_dir=$(mktemp -d)
expected_dir="$work_dir/project"
other_dir="$work_dir/other"

mkdir "$expected_dir" "$other_dir"
touch "$expected_dir/.unit04-project"

(
  cd "$other_dir"
  # relative path に依存した処理を行う前に、想定した working directory か確認する。
  if [[ ! -f .unit04-project ]]; then
    printf 'refusing operation in unexpected directory: %s\n' "$PWD" >&2
  fi
)

(
  cd "$expected_dir"
  if [[ -f .unit04-project ]]; then
    printf 'working directory validated: %s\n' "$PWD"
  fi
)

rm -f -- "$expected_dir/.unit04-project"
rmdir "$expected_dir" "$other_dir" "$work_dir"
