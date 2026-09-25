#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
name='alice'
message='hello from shell'

# Shell variable を JSON へ安全に埋め込むため、
# JSON の quote / escape は文字列連結せず jq --arg に任せる。
request_body=$(
  jq -n \
    --arg name "$name" \
    --arg message "$message" \
    '{name: $name, message: $message}'
)

# Content-Type で body が JSON であることを伝え、
# --data で先ほど生成した JSON を request body として送る。
curl -sS \
  -X POST \
  -H 'Content-Type: application/json' \
  --data "$request_body" \
  "$base_url/api/messages"
printf '\n'
