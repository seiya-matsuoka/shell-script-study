#!/usr/bin/env bash

debug() {
  if [[ ${DEBUG:-false} == true ]]; then
    printf 'DEBUG: %s\n' "$*" >&2
  fi
}

step_one() {
  debug 'step_one started'
  return 0
}

step_two() {
  debug 'step_two started'
  return 1
}

step_three() {
  debug 'step_three started'
  return 0
}

# 問題箇所を一度に推測せず、処理単位ごとに success / failure を確認して切り分ける。
if ! step_one; then
  printf '%s\n' 'step_one failed' >&2
  exit 1
fi

if ! step_two; then
  printf '%s\n' 'step_two failed as expected' >&2
else
  step_three
fi
