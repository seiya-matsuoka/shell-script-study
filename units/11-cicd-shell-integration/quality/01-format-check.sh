#!/usr/bin/env bash

# local と CI で同じ shfmt rule を利用し、未整形の差分があれば non-zero で終了する。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/.."
  pwd
)

if ! command -v shfmt >/dev/null; then
  printf '%s\n' 'shfmt is required' >&2
  exit 1
fi

cd -- "$unit_dir" || exit 1

# 通常の Bash files と Bats files を、それぞれの language として format check する。
shfmt -i 2 -d examples scripts quality tests/test_helper.bash
shfmt -ln bats -i 2 -d tests/*.bats
