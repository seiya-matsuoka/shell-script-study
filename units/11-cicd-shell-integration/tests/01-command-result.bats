#!/usr/bin/env bats

load test_helper.bash

setup() {
  COMMAND_RESULT_SCRIPT="$PROJECT_ROOT/examples/ci/01-command-result.sh"
}

@test "success mode は status 0 と stdout を返す" {
  run --separate-stderr bash "$COMMAND_RESULT_SCRIPT" success

  [ "$status" -eq 0 ]
  [ "$output" = "command completed successfully" ]
  [ -z "$stderr" ]
}

@test "failure mode は status 1 と stderr を返す" {
  run --separate-stderr bash "$COMMAND_RESULT_SCRIPT" failure

  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [ "$stderr" = "command failed intentionally" ]
}

@test "unknown mode は status 2 を返す" {
  run --separate-stderr bash "$COMMAND_RESULT_SCRIPT" unknown

  [ "$status" -eq 2 ]
  [ -z "$output" ]
  [ "$stderr" = "unknown mode: unknown" ]
}
