#!/usr/bin/env bash

show_arguments() {
  printf 'count=%s\n' "$#"
  for argument in "$@"; do
    printf '<%s>\n' "$argument"
  done
}

value='alpha beta'
empty=''

# quote しない場合は word splitting が起こり、空文字は argument として消える場合がある。
show_arguments $value $empty

# double quote すると、空白を含む値も空文字も、それぞれ明示的な argument として保持される。
show_arguments "$value" "$empty"
