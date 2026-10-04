#!/usr/bin/env bats

load test_helper.bash

setup() {
  TEST_WORK_DIR="$BATS_TEST_TMPDIR/work"
  mkdir -p -- "$TEST_WORK_DIR"

  ENVIRONMENT_SCRIPT="$PROJECT_ROOT/examples/ci/02-environment.sh"
  SECRET_SCRIPT="$PROJECT_ROOT/examples/ci/03-secret-usage.sh"
  BUILD_SCRIPT="$PROJECT_ROOT/scripts/build-artifact.sh"
}

@test "local environment を明示すると local として判定する" {
  run env \
    -u GITHUB_ACTIONS \
    -u RUNNER_OS \
    -u GITHUB_REF_NAME \
    bash "$ENVIRONMENT_SCRIPT"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "execution_environment=local" ]
  [ "${lines[1]}" = "runner_os=local" ]
  [ "${lines[2]}" = "ref_name=local" ]
}

@test "GitHub Actions environment を与えると CI 側の値を利用する" {
  run env \
    GITHUB_ACTIONS=true \
    RUNNER_OS=Linux \
    GITHUB_REF_NAME=feature/unit11 \
    bash "$ENVIRONMENT_SCRIPT"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "execution_environment=github-actions" ]
  [ "${lines[1]}" = "runner_os=Linux" ]
  [ "${lines[2]}" = "ref_name=feature/unit11" ]
}

@test "secret 未設定時は安全に skip する" {
  run env -u UNIT11_SAMPLE_TOKEN bash "$SECRET_SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "UNIT11_SAMPLE_TOKEN is not configured; secret example skipped" ]
}

@test "secret 設定時も secret value を stdout へ出さない" {
  dummy_secret='unit11-dummy-secret'

  run env UNIT11_SAMPLE_TOKEN="$dummy_secret" bash "$SECRET_SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "UNIT11_SAMPLE_TOKEN is configured; value is not printed" ]
  [[ "$output" != *"$dummy_secret"* ]]
}

@test "build Script は CI metadata を artifact file に保存する" {
  output_dir="$TEST_WORK_DIR/dist"

  run env \
    UNIT11_OUTPUT_DIR="$output_dir" \
    GITHUB_ACTIONS=true \
    RUNNER_OS=Linux \
    GITHUB_REF_NAME=feature/unit11 \
    GITHUB_SHA=0123456789abcdef \
    bash "$BUILD_SCRIPT"

  [ "$status" -eq 0 ]
  [ -f "$output_dir/ci-summary.txt" ]

  run cat "$output_dir/ci-summary.txt"

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "execution_environment=github-actions" ]
  [ "${lines[1]}" = "runner_os=Linux" ]
  [ "${lines[2]}" = "ref_name=feature/unit11" ]
  [ "${lines[3]}" = "commit_sha=0123456789abcdef" ]
}
