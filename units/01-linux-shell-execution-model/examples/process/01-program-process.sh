#!/usr/bin/env bash

# program は実行される前の命令やデータで、process は program が実行中になった状態を表す。
# 同じ sleep program を 2 回実行し、それぞれに別の PID が割り当てられることを確認する。
# `bash -x` で実行すると、background 起動、$! の取得、wait の順序も追いやすい。

sleep 2 &
first_pid=$!

sleep 2 &
second_pid=$!

# 同じ program から起動した 2 つの process を、PID / PPID / command 名で確認する。
ps -o pid=,ppid=,comm= -p "$first_pid" -p "$second_pid"

# background process を残さないよう、両方の終了を待つ。
wait "$first_pid"
wait "$second_pid"
