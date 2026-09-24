#!/usr/bin/env bash

# `set -euo pipefail` は有用な組み合わせだが、
# validation・cleanup・再実行性・秘密情報保護まで自動的に実現するものではない。
set -euo pipefail

required_value=${REQUIRED_VALUE:-default-value}

# strict mode を有効にしていても、入力値の意味が正しいかは Script 自身で検証する必要がある。
if [[ -z $required_value ]]; then
  printf '%s\n' 'required_value must not be empty' >&2
  exit 1
fi

printf 'required_value=%s\n' "$required_value"
