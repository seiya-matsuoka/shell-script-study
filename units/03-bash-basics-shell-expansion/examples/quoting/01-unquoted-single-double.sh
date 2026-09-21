#!/usr/bin/env bash

value='hello world'

# unquoted では word splitting の影響を受ける。
set -- $value
printf 'unquoted count=%s\n' "$#"

# single quote では variable expansion 自体が行われない。
printf '%s\n' '$value'

# double quote では variable expansion を行いつつ、展開結果を 1 argument として保持できる。
printf '%s\n' "$value"
