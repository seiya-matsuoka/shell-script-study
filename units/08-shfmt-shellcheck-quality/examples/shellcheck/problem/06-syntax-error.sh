#!/usr/bin/env bash

# 学習用に意図的な syntax error を含めている。
name=${1:-alice}

if [[ -n $name ]]; then
  printf 'name=%s\n' "$name"
