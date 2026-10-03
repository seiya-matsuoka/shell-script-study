#!/usr/bin/env bats

load test_helper

setup() {
  GREET_SCRIPT="$PROJECT_ROOT/examples/basic/01-greet.sh"
}

@test "正常系: NAME を渡すと greeting を stdout に出して成功する" {
  run bash "$GREET_SCRIPT" "Alice"

  [ "$status" -eq 0 ]
  [ "$output" = "hello, Alice" ]
}

@test "異常系: argument がない場合は usage を stderr に出して status 2 で終了する" {
  run --separate-stderr bash "$GREET_SCRIPT"

  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [[ "$stderr" == usage:* ]]
}

@test "異常系: empty NAME は status 1 で終了する" {
  run --separate-stderr bash "$GREET_SCRIPT" ""

  [ "$status" -eq 1 ]
  [ "$stderr" = "NAME must not be empty" ]
}
