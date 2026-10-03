#!/usr/bin/env bash

PROJECT_ROOT=$(
  cd -- "$BATS_TEST_DIRNAME/.."
  pwd
)

fixture_path() {
  local fixture_name=$1
  printf '%s/tests/fixtures/%s\n' "$PROJECT_ROOT" "$fixture_name"
}

copy_fixture() {
  local fixture_name=$1
  local destination=$2

  cp -- "$(fixture_path "$fixture_name")" "$destination"
}
