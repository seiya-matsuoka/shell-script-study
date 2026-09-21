#!/usr/bin/env bash

build_message() {
  local name=$1

  # function の stdout は command substitution で文字列として受け取れる。
  printf 'hello %s\n' "$name"
}

message=$(build_message 'Bash')
printf '%s\n' "$message"
