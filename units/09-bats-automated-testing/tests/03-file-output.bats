#!/usr/bin/env bats

load test_helper

setup() {
  TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p -- "$TEST_WORK_DIR"

  INPUT_FILE="$TEST_WORK_DIR/report-input.txt"
  OUTPUT_FILE="$TEST_WORK_DIR/output/report.txt"
  copy_fixture "report-input.txt" "$INPUT_FILE"

  REPORT_SCRIPT="$PROJECT_ROOT/examples/files/01-write-report.sh"
}

teardown() {
  rm -rf -- "$TEST_WORK_DIR"
}

@test "正常系: report file を作成する" {
  run bash "$REPORT_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ -f "$OUTPUT_FILE" ]
}

@test "作成された report の内容を確認する" {
  run bash "$REPORT_SCRIPT" "$INPUT_FILE" "$OUTPUT_FILE"

  [ "$status" -eq 0 ]

  run cat "$OUTPUT_FILE"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "source=report-input.txt" ]
  [ "${lines[1]}" = "lines=3" ]
  [ "${lines[2]}" = "first=alpha" ]
}

@test "異常系: input file がない場合は output を作らず失敗する" {
  missing_file="$TEST_WORK_DIR/missing.txt"

  run --separate-stderr bash "$REPORT_SCRIPT" "$missing_file" "$OUTPUT_FILE"

  [ "$status" -eq 1 ]
  [ ! -e "$OUTPUT_FILE" ]
  [[ "$stderr" == "input file not found:"* ]]
}
