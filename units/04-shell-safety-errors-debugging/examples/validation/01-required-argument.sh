#!/usr/bin/env bash

usage() {
  printf 'usage: %s <input>\n' "$0" >&2
}

# required argument は処理を始める前に存在を検証する。
# `${1:-}` とすることで、argument がない場合でも安全に空文字として確認できる。
input=${1:-}

if [[ -z $input ]]; then
  printf '%s\n' 'input argument is required' >&2
  usage
  exit 2
fi

printf 'input=%s\n' "$input"
