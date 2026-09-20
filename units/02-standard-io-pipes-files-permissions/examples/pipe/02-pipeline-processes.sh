#!/usr/bin/env bash

# pipeline では複数の command が接続され、それぞれの処理が別 process として動くことを確認する。

# pipeline を開始する parent Bash 自身の PID を比較用に stderr へ出力する。
printf 'parent BASHPID=%s\n' "$BASHPID" >&2

# 各 stage の Bash は自分の BASHPID を stderr へ出し、
# stdout には変換対象の data だけを流して次の stage へ渡す。
printf '%s\n' 'alpha' 'beta' |
  bash -c '
    printf "stage 1 BASHPID=%s\n" "$BASHPID" >&2
    tr "[:lower:]" "[:upper:]"
  ' |
  bash -c '
    printf "stage 2 BASHPID=%s\n" "$BASHPID" >&2
    sed "s/^/result: /"
  '
