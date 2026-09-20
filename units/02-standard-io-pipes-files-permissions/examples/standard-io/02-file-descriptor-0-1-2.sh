#!/usr/bin/env bash

# Linux process は open している入出力先を file descriptor で扱う。
# 通常、0 は stdin、1 は stdout、2 は stderr として開始される。
# /proc/<PID>/fd/ では、その process が持つ file descriptor の参照先を確認できる。
#
# 実行環境や Terminal によって参照先の表示内容は異なるため、
# 「0 / 1 / 2 が存在し、それぞれ何かへ接続されている」ことを確認する。

ls -l \
  "/proc/$BASHPID/fd/0" \
  "/proc/$BASHPID/fd/1" \
  "/proc/$BASHPID/fd/2"
