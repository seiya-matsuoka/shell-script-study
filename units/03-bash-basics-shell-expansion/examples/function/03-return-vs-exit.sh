#!/usr/bin/env bash

return_example() {
  printf '%s\n' 'before return'
  return 0
  printf '%s\n' 'after return'
}

return_example
printf '%s\n' 'script continues after return'

# exit は function だけではなく、その Script / Shell process 全体を終了する。
# 現在の Script 自体を終了させないよう child Bash 内で確認する。
bash -c 'exit 7'
child_status=$?
printf 'child exit status=%s\n' "$child_status"
