#!/usr/bin/env bash

work_dir=$(mktemp -d)
target_dir="$work_dir/generated"
mkdir "$target_dir"
touch "$target_dir/a.txt" "$target_dir/b.txt"

safe_remove_generated() {
  local target=$1
  local expected_parent=$2

  # destructive operation の前に、空文字や root directory を拒否する。
  if [[ -z $target || $target == / ]]; then
    printf 'refusing unsafe target: <%s>\n' "$target" >&2
    return 1
  fi

  # 削除対象が意図した parent directory の直下か確認する。
  if [[ $target != "$expected_parent"/* ]]; then
    printf 'target is outside expected directory: %s\n' "$target" >&2
    return 1
  fi

  rm -rf -- "$target"
}

safe_remove_generated "$target_dir" "$work_dir"

if [[ ! -e $target_dir ]]; then
  printf '%s\n' 'validated target removed'
fi

rmdir "$work_dir"
