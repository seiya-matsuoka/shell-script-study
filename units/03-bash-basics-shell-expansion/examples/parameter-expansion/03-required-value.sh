#!/usr/bin/env bash

# ${var:?message} は var が unset または empty の場合に message を stderr へ出し、その Shell を終了させる。
# 現在の学習 Script を終了させないよう child Bash で確認する。
error_file=$(mktemp)

bash -c '
  unset REQUIRED_VALUE
  printf "%s\n" "${REQUIRED_VALUE:?REQUIRED_VALUE is required}"
' 2>"$error_file"
status=$?

cat "$error_file"
printf 'child status=%s\n' "$status"
rm -f -- "$error_file"
