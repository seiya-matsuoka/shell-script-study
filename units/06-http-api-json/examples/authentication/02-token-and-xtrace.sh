#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
: "${API_TOKEN:?API_TOKEN is required}"

# xtrace は展開後の argument を stderr へ出すため、
# secret を request header に含める処理では明示的に無効にしておく。
set +x
response=$(
  curl -sS \
    -H "Authorization: Bearer $API_TOKEN" \
    "$base_url/api/protected"
)

# secret を含まない後続処理だけ trace し、
# 必要な範囲に限定して debugging information を取得する。
set -x
message=$(jq -r '.message' <<<"$response")
set +x

printf 'message=%s\n' "$message"
