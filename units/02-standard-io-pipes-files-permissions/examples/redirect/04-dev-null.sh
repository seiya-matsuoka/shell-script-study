#!/usr/bin/env bash

# /dev/null へ書き込んだ内容は破棄される。
# stdout / stderr のうち、不要な出力だけを捨てたい場合などに利用できる。

printf '%s\n' 'this stdout is discarded' >/dev/null
printf '%s\n' 'this stderr is discarded' >&2 2>/dev/null

printf '%s\n' 'visible output'
