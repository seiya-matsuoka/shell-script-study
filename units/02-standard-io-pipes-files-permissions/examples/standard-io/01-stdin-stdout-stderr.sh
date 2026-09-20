#!/usr/bin/env bash

# stdin / stdout / stderr がそれぞれ別の入出力経路であることを確認する最小例。

# read は stdin から 1 行読み取る。
read -r input

# redirect を付けない通常の出力は stdout(fd 1) へ送られる。
printf 'stdout: %s\n' "$input"

# >&2 を付けると、同じ printf でも出力先を stderr(fd 2) へ変更できる。
printf 'stderr: input length=%s\n' "${#input}" >&2
