#!/usr/bin/env bash

# Script を起動した current working directory ではなく、Script 自身の位置を基準に path を組み立てる例。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)

printf 'current working directory=%s\n' "$PWD"
printf 'script directory=%s\n' "$script_dir"
