#!/usr/bin/env bash

greet() {
  local name=$1

  if [[ -n $name ]]; then
    printf 'hello, %s\n' "$name"
  else
    printf '%s\n' 'hello'
  fi
}

greet "${1:-}"
