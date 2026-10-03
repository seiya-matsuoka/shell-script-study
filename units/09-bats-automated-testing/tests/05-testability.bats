#!/usr/bin/env bats

load test_helper

setup() {
  TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p -- "$TEST_WORK_DIR"

  INPUT_FILE="$TEST_WORK_DIR/report-input.txt"
  EMPTY_FILE="$TEST_WORK_DIR/empty-input.txt"
  OUTPUT_FILE="$TEST_WORK_DIR/report.txt"

  copy_fixture "report-input.txt" "$INPUT_FILE"
  copy_fixture "empty-input.txt" "$EMPTY_FILE"

  LARGE_MAIN_SCRIPT="$PROJECT_ROOT/examples/testability/01-large-main.sh"
  REPORT_CLI_SCRIPT="$PROJECT_ROOT/examples/testability/03-report-cli.sh"

  # function 単位の test を行うため library を test process へ読み込む。
  source "$PROJECT_ROOT/examples/testability/02-report-lib.sh"
}

teardown() {
  rm -rf -- "$TEST_WORK_DIR"
}

@test "大きな main 処理は CLI 全体を通した end-to-end test になる" {
  run bash "$LARGE_MAIN_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "$OUTPUT_FILE" ]
  grep -q '^status=READY$' "$OUTPUT_FILE"
}

@test "function 分割後は report_status の判断だけを直接確認できる" {
  run report_status "$INPUT_FILE"

  [ "$status" -eq 0 ]
  [ "$output" = "READY" ]

  run report_status "$EMPTY_FILE"

  [ "$status" -eq 0 ]
  [ "$output" = "EMPTY" ]
}

@test "function 分割後も CLI 全体の振る舞いを確認できる" {
  run bash "$REPORT_CLI_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "$OUTPUT_FILE" ]
  grep -q '^status=READY$' "$OUTPUT_FILE"
  grep -q '^lines=3$' "$OUTPUT_FILE"
}

@test "validation function は missing file を status 1 で返す" {
  run validate_input "$TEST_WORK_DIR/missing.txt"

  [ "$status" -eq 1 ]
  [[ "$output" == "input file not found:"* ]]
}
