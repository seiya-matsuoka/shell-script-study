#!/usr/bin/env bash

value='visible-in-trace'
secret='dummy-secret-for-learning'

# set -x / set +x を使うと、Script の一部分だけ xtrace を有効化できる。
set -x
printf 'value=%s\n' "$value"
set +x

# secret を扱う箇所では trace を止める。
printf 'secret is set (length=%s)\n' "${#secret}"
