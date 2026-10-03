#!/usr/bin/env bats

load test_helper

setup() {
  FETCH_SCRIPT="$PROJECT_ROOT/examples/external/01-fetch-status.sh"
  FAKE_BIN="$PROJECT_ROOT/tests/fakes"

  ORIGINAL_PATH=$PATH
  PATH="$FAKE_BIN:$ORIGINAL_PATH"
  export PATH

  API_URL='https://example.invalid/api'
  export API_URL

  FAKE_CURL_MARKER="$BATS_TEST_TMPDIR/curl-called.log"
  export FAKE_CURL_MARKER
}

teardown() {
  PATH=$ORIGINAL_PATH
  export PATH

  unset API_URL
  unset FAKE_CURL_MODE
  unset FAKE_CURL_RESPONSE
  unset FAKE_CURL_MARKER
}

@test "fake curl を使って external dependency の正常系を test する" {
  FAKE_CURL_MODE=success
  FAKE_CURL_RESPONSE=READY
  export FAKE_CURL_MODE FAKE_CURL_RESPONSE

  run bash "$FETCH_SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "remote_status=READY" ]
  [ -f "$FAKE_CURL_MARKER" ]
}

@test "fake curl の command failure を再現して異常系を test する" {
  FAKE_CURL_MODE=failure
  export FAKE_CURL_MODE

  run --separate-stderr bash "$FETCH_SCRIPT"

  [ "$status" -eq 1 ]
  [ -z "$output" ]
  [[ "$stderr" == *"fake curl: request failed"* ]]
  [[ "$stderr" == *"failed to fetch remote status"* ]]
}

@test "response を変えても実ネットワークへ接続せず deterministic に test できる" {
  FAKE_CURL_MODE=success
  FAKE_CURL_RESPONSE=MAINTENANCE
  export FAKE_CURL_MODE FAKE_CURL_RESPONSE

  run bash "$FETCH_SCRIPT"

  [ "$status" -eq 0 ]
  [ "$output" = "remote_status=MAINTENANCE" ]
}
