#!/usr/bin/env bash

# signal の違いを安全に確認するための学習用 process。
# 実行後に表示される PID は、この Script を実行している Bash process の PID。
# この PID に対してだけ SIGINT / SIGTERM / SIGKILL を送って確認する。

printf 'PID=%s\n' "$BASHPID"

# SIGINT / SIGTERM は process 側で捕捉できるため、trap で受信時の処理を定義できる。
# 終了 status 130 / 143 は、それぞれ 128 + signal number を意識した学習用の値。
trap 'printf "%s\n" "received SIGINT"; exit 130' INT
trap 'printf "%s\n" "received SIGTERM"; exit 143' TERM

# SIGKILL は process 側で捕捉・無視できないため、trap は設定できない。
while :; do
  sleep 1
done
