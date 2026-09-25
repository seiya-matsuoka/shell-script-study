#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
: "${API_TOKEN:?API_TOKEN is required}"

# secret を含む request command は xtrace の対象外にする。
set +x
response=$(
  curl -sS -H "Authorization: Bearer $API_TOKEN" "$base_url/api/protected"
)

# secret を含まない後続処理だけ trace する。
set -x
message=$(jq -r '.message' <<<"$response")
set +x

printf 'message=%s\n' "$message"
