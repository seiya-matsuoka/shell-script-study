#!/usr/bin/env bash

work_dir=$(mktemp -d)
bad_file="$work_dir/bad.conf"
good_file="$work_dir/good.conf"
line='feature.enabled=true'

append_without_check() {
  local target=$1
  # 既存状態を確認せず追記すると、再実行のたびに同じ行が増える。
  printf '%s\n' "$line" >>"$target"
}

ensure_line_once() {
  local target=$1
  # 既に同じ設定が存在する場合は何もしない。
  if ! grep -qxF -- "$line" "$target" 2>/dev/null; then
    printf '%s\n' "$line" >>"$target"
  fi
}

append_without_check "$bad_file"
append_without_check "$bad_file"
ensure_line_once "$good_file"
ensure_line_once "$good_file"

printf 'non-idempotent count=%s\n' "$(grep -cFx -- "$line" "$bad_file")"
printf 'idempotent count=%s\n' "$(grep -cFx -- "$line" "$good_file")"

rm -f -- "$bad_file" "$good_file"
rmdir "$work_dir"
