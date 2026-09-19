#!/usr/bin/env bash

# 現在の Bash から child Bash を background で起動し、親子関係を確認する。
# child process の PPID が parent Bash の PID と対応する点を ps の結果で確認する。

parent_pid=$BASHPID

bash -c '
  # child Bash がすぐ終了すると ps で確認できないため、少し待機する。
  sleep 2
' &
child_pid=$!

ps -o pid=,ppid=,comm= -p "$parent_pid" -p "$child_pid"

wait "$child_pid"
