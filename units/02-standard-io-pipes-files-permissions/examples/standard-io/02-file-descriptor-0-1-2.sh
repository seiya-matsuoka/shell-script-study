#!/usr/bin/env bash

# Linux process は open している入出力先を file descriptor で扱う。
# この Script では、通常 stdin=0、stdout=1、stderr=2 として存在することを確認する。

# /proc/<PID>/fd/ には、その process が持つ file descriptor への symbolic link がある。
# Terminal や実行環境によって link 先の表示は異なるため、0 / 1 / 2 が存在し、
# それぞれ何らかの入出力先へ接続されていることに注目する。
ls -l \
  "/proc/$BASHPID/fd/0" \
  "/proc/$BASHPID/fd/1" \
  "/proc/$BASHPID/fd/2"
