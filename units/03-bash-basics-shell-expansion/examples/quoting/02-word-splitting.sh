#!/usr/bin/env bash

show_arguments() {
  printf 'count=%s\n' "$#"
  for argument in "$@"; do
    printf '<%s>\n' "$argument"
  done
}

value='alpha beta gamma'

# quote しない variable expansion は IFS に基づく word splitting の対象になる。
show_arguments $value

# double quote すると空白を含む値でも 1 argument として保持される。
show_arguments "$value"
