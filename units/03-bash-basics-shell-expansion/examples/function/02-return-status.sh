#!/usr/bin/env bash

is_even() {
  local number=$1

  # return は function の exit status を返して function から戻る。
  if ((number % 2 == 0)); then
    return 0
  fi
  return 1
}

if is_even 8; then
  printf '%s\n' '8 is even'
fi

if ! is_even 7; then
  printf '%s\n' '7 is not even'
fi
