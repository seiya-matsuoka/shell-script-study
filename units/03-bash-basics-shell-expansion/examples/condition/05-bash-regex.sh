#!/usr/bin/env bash

value='user-123'

# Bash の [[ ]] では =~ による regex match が利用できる。ここでは基本形だけ確認する。
if [[ $value =~ ^user-[0-9]+$ ]]; then
  printf '%s\n' 'regex matched'
fi
