#!/usr/bin/env bash

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/.."
  pwd
)

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null; then
    printf 'required command not found: %s\n' "$command_name" >&2
    return 1
  fi
}

require_command shfmt || exit 1
require_command shellcheck || exit 1

cd -- "$unit_dir" || exit 1

# Unit 08 以降の通常 Shell Script を formatter / static analysis の対象にする。
if ! shfmt -i 2 -d examples integration quality; then
  exit 1
fi

if ! shellcheck \
  examples/docker/*.sh \
  examples/postgresql/*.sh \
  examples/application/*.sh \
  integration/*.sh \
  quality/*.sh; then
  exit 1
fi

printf '%s\n' 'quality checks passed'
