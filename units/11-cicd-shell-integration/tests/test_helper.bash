#!/usr/bin/env bash

# Bats test files から参照する共通変数であり、この helper 単体では直接参照しない。
# shellcheck disable=SC2034
PROJECT_ROOT=$(
  cd -- "$BATS_TEST_DIRNAME/.." && pwd
) || return 1
