#!/usr/bin/env bash

# "$*" は positional parameter 全体を 1 つの文字列として展開する。
# "$@" とは argument の保持方法が異なるため、通常は "$@" を優先する。
printf '"$*"=<%s>\n' "$*"

# shift は先頭 positional parameter を取り除き、残りを左へ詰める。
printf 'before shift: first=%s count=%s\n' "$1" "$#"
shift
printf 'after shift: first=%s count=%s\n' "$1" "$#"
