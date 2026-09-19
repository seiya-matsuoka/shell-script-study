#!/usr/bin/env bash

# 丸括弧の中は subshell で実行される。
# subshell 内で variable や working directory を変更しても、終了後の parent Shell には残らない。

UNIT01_SUBSHELL_VALUE='parent value'
parent_directory=$PWD

printf 'parent before: $$=%s BASHPID=%s value=%s directory=%s\n' \
  "$$" "$BASHPID" "$UNIT01_SUBSHELL_VALUE" "$PWD"

(
  UNIT01_SUBSHELL_VALUE='subshell value'
  cd /tmp

  # $$ は subshell 内でも同じ値として見える一方、
  # BASHPID は現在実行中の Bash process を表すため parent と異なる値になる。
  printf 'subshell: $$=%s BASHPID=%s value=%s directory=%s\n' \
    "$$" "$BASHPID" "$UNIT01_SUBSHELL_VALUE" "$PWD"
)

printf 'parent after: $$=%s BASHPID=%s value=%s directory=%s\n' \
  "$$" "$BASHPID" "$UNIT01_SUBSHELL_VALUE" "$PWD"

# working directory も parent 側では変更されていないことを確認する。
if [[ $PWD == "$parent_directory" ]]; then
  printf '%s\n' 'parent directory preserved'
fi
