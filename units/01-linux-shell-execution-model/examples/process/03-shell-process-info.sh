#!/usr/bin/env bash

# Bash 自体も Linux 上で動く process であることを確認する。
# $$ は現在の Shell に関連する PID、BASHPID は現在実行中の Bash process の PID、
# PPID はその Bash の parent process の PID を表す。
# subshell 内での $$ と BASHPID の違いは environment/03-subshell.sh で確認する。

printf '$$=%s\n' "$$"
printf 'BASHPID=%s\n' "$BASHPID"
printf 'PPID=%s\n' "$PPID"

ps -o pid=,ppid=,comm= -p "$BASHPID"
