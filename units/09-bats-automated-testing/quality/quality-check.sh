#!/usr/bin/env bash

set -u

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(dirname -- "$script_dir")

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

# Bats 固有の @test syntax を含む .bats はこの check では対象外とし、
# 通常の Shell files と helper / fake command を Unit 08 以降の品質対象にする。
if ! shfmt -i 2 -d \
  examples \
  tests/test_helper.bash \
  tests/fakes/curl \
  quality/quality-check.sh; then
  exit 1
fi

if ! shellcheck \
  examples/basic/*.sh \
  examples/files/*.sh \
  examples/testability/*.sh \
  examples/external/*.sh \
  tests/test_helper.bash \
  tests/fakes/curl \
  quality/quality-check.sh; then
  exit 1
fi

printf '%s\n' 'quality checks passed'
