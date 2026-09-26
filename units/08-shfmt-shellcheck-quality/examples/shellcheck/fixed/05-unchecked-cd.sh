#!/usr/bin/env bash

target_dir=${1:-/tmp/unit08-missing-directory}

# directory 移動に失敗した場合は、想定外の場所で後続処理をしないよう終了する。
if ! cd -- "$target_dir"; then
  printf 'failed to change directory: %s\n' "$target_dir" >&2
  exit 1
fi

printf 'current_directory=%s\n' "$PWD"
