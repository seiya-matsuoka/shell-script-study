#!/usr/bin/env bash

# pipe (`|`) は左側 command の stdout を右側 command の stdin へ接続する。
# intermediate file を作らず、複数 command を data の流れとしてつなげられる。

# printf の stdout を grep の stdin へ、grep の stdout を tr の stdin へ順番に渡す。
printf '%s\n' \
  'apple' \
  'banana' \
  'apricot' \
  'grape' |
  grep '^a' |
  tr '[:lower:]' '[:upper:]'
