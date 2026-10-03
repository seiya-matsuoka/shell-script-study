#!/usr/bin/env bats

load test_helper

setup() {
  LIST_SCRIPT="$PROJECT_ROOT/examples/basic/02-list-items.sh"
}

@test "複数行 output は output 全体と lines array の両方から確認できる" {
  run bash "$LIST_SCRIPT"

  [ "$status" -eq 0 ]
  [ "${#lines[@]}" -eq 4 ]
  [ "${lines[0]}" = "start" ]
  [ "${lines[1]}" = "item=alpha" ]
  [ "${lines[2]}" = "item=beta" ]
  [ "${lines[3]}" = "finish" ]
  [[ "$output" == *"item=alpha"* ]]
}
