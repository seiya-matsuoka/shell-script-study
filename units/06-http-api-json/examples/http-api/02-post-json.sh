#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
name='alice'
message='hello from shell'

# JSON の quote / escape は文字列連結せず jq に任せる。
request_body=$(
  jq -n --arg name "$name" --arg message "$message" '{name: $name, message: $message}'
)

curl -sS -X POST -H 'Content-Type: application/json' --data "$request_body" "$base_url/api/messages"
printf '\n'
