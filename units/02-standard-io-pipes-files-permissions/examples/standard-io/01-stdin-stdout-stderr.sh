#!/usr/bin/env bash

# stdin / stdout / stderr の役割を確認するための最小例。
# read は stdin から 1 行読み取り、通常の printf は stdout、
# `>&2` を付けた printf は stderr へ出力する。

read -r input

printf 'stdout: %s\n' "$input"
printf 'stderr: input length=%s\n' "${#input}" >&2
