#!/usr/bin/env bash

# pipeline では複数の command が組み合わされ、それぞれの処理が別 process として動く。
# 各 stage の Bash が自分の BASHPID を stderr へ出し、
# stdout には変換対象の data だけを流して次の stage へ渡す。

printf 'parent BASHPID=%s\n' "$BASHPID" >&2

printf '%s\n' 'alpha' 'beta' |
  bash -c '
    printf "stage 1 BASHPID=%s\n" "$BASHPID" >&2
    tr "[:lower:]" "[:upper:]"
  ' |
  bash -c '
    printf "stage 2 BASHPID=%s\n" "$BASHPID" >&2
    sed "s/^/result: /"
  '
