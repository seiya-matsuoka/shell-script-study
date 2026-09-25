#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
response=$(curl -sS "$base_url/api/items")

# array を展開し、active == true の object だけ filter して name を取得する。
jq -r '.items[] | select(.active == true) | .name' <<<"$response"
