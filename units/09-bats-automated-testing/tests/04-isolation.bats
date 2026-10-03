#!/usr/bin/env bats

load test_helper

setup() {
  TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p -- "$TEST_WORK_DIR"

  RECORD_FILE="$TEST_WORK_DIR/records.txt"
  copy_fixture "records.txt" "$RECORD_FILE"

  APPEND_SCRIPT="$PROJECT_ROOT/examples/files/02-append-record.sh"
}

teardown() {
  rm -rf -- "$TEST_WORK_DIR"
}

@test "fixture を変更しても現在の test case 内だけに影響する" {
  run bash "$APPEND_SCRIPT" "$RECORD_FILE" "gamma"

  [ "$status" -eq 0 ]

  run bash -c 'wc -l < "$1"' _ "$RECORD_FILE"

  [ "$status" -eq 0 ]
  [ "$output" -eq 3 ]
}

@test "次の test case では setup により新しい fixture から開始する" {
  run bash -c 'wc -l < "$1"' _ "$RECORD_FILE"

  [ "$status" -eq 0 ]
  [ "$output" -eq 2 ]
  [ "$(tail -n 1 -- "$RECORD_FILE")" = "beta" ]
}
