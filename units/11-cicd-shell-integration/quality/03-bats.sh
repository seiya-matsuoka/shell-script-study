#!/usr/bin/env bash

# Bats test の failure status をそのまま呼び出し元へ返し、CI step の結果へ接続する。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/.."
  pwd
)

if ! command -v bats >/dev/null; then
  printf '%s\n' 'bats is required' >&2
  exit 1
fi

cd -- "$unit_dir" || exit 1

bats tests
