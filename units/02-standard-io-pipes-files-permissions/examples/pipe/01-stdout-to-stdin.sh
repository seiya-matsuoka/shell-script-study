#!/usr/bin/env bash

# pipe (`|`) は左側 command の stdout を右側 command の stdin へ接続する。
# intermediate file を作らず、command の出力を次の command の入力として渡せる。

printf '%s\n' \
  'apple' \
  'banana' \
  'apricot' \
  'grape' |
  grep '^a' |
  tr '[:lower:]' '[:upper:]'
