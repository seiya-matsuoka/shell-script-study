#!/usr/bin/env bash

# umask は、新しく作成する file / directory の permission から
# 初期状態で許可しない bit を指定する仕組み。
# この Unit では代表的な違いを確認するだけに留める。

work_dir=$(mktemp -d)
original_umask=$(umask)

umask 022
touch "$work_dir/file-022"
mkdir "$work_dir/dir-022"

umask 077
touch "$work_dir/file-077"
mkdir "$work_dir/dir-077"

# 学習後の Shell に影響を残さないよう、元の umask に戻す。
umask "$original_umask"

stat -c 'mode=%a %n' \
  "$work_dir/file-022" \
  "$work_dir/dir-022" \
  "$work_dir/file-077" \
  "$work_dir/dir-077"

rm -f -- "$work_dir/file-022" "$work_dir/file-077"
rmdir "$work_dir/dir-022" "$work_dir/dir-077"
rmdir "$work_dir"
