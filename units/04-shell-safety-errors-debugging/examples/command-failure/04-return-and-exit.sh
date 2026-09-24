#!/usr/bin/env bash

validate_number() {
  local value=$1

  if [[ $value =~ ^[0-9]+$ ]]; then
    return 0
  fi

  # return は function の status を返し、caller へ戻る。
  return 1
}

if validate_number '42'; then
  printf '%s\n' '42 is valid'
fi

if ! validate_number 'abc'; then
  printf '%s\n' 'abc is invalid'
fi

# exit は function だけではなく Script / Shell process 全体を終了する。
# 学習用 Script 自体を終了させないよう child Bash 内で確認する。
bash -c 'exit 7'
child_status=$?

printf 'child exit status=%s\n' "$child_status"
