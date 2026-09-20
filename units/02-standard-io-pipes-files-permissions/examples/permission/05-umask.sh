#!/usr/bin/env bash

# umask が新規 file / directory の初期 permission に与える影響を軽く確認する。

work_dir=$(mktemp -d)
original_umask=$(umask)

# umask 022 では、group / others の write permission を初期状態から除外する。
umask 022
touch "$work_dir/file-022"
mkdir "$work_dir/dir-022"

# umask 077 では、group / others の permission を初期状態から除外する。
umask 077
touch "$work_dir/file-077"
mkdir "$work_dir/dir-077"

# 学習後の Shell に影響を残さないよう、元の umask に戻す。
umask "$original_umask"

# file と directory では元となる初期 permission が異なるため、両方の結果を確認する。
stat -c 'mode=%a %n' \
  "$work_dir/file-022" \
  "$work_dir/dir-022" \
  "$work_dir/file-077" \
  "$work_dir/dir-077"

rm -f -- "$work_dir/file-022" "$work_dir/file-077"
rmdir "$work_dir/dir-022" "$work_dir/dir-077"
rmdir "$work_dir"
