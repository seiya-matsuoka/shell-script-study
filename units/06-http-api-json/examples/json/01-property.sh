#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
response=$(curl -sS "$base_url/api/user")

# jq -r で JSON property を Shell で扱いやすい raw text にする。
name=$(jq -r '.name' <<<"$response")
active=$(jq -r '.active' <<<"$response")
printf 'name=%s active=%s\n' "$name" "$active"
