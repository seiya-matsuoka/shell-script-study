#!/usr/bin/env bash

format_name() {
  # function 内でも $1 などは、その function に渡された positional parameter を指す。
  local first_name=$1
  local last_name=$2

  # local により function 内だけで使う variable として扱う。
  printf '%s %s\n' "$first_name" "$last_name"
}

format_name 'Seiya' 'Matsuoka'
