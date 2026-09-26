#!/usr/bin/env bash

command_name=${1:-awk}

# command name だけで実行できるかは PATH に依存する。
# command -v で、現在の environment からどの executable が解決されるか確認する。
if command_path=$(command -v "$command_name"); then
  printf 'command=%s path=%s\n' "$command_name" "$command_path"
else
  printf 'command not found in PATH: %s\n' "$command_name" >&2
  exit 1
fi
