#!/usr/bin/env bash

# ShellCheck の warning を CI failure へつなげるため、通常の Shell files を一つの入口から解析する。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/.."
  pwd
)

if ! command -v shellcheck >/dev/null; then
  printf '%s\n' 'shellcheck is required' >&2
  exit 1
fi

cd -- "$unit_dir" || exit 1

# Bats test 自体の動作確認は Bats に任せ、この sample では通常の Shell Script と
# test helper を static analysis の対象にして tool ごとの役割を分ける。
shellcheck \
  examples/ci/*.sh \
  scripts/*.sh \
  quality/*.sh \
  tests/test_helper.bash
