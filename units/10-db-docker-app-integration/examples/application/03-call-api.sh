#!/usr/bin/env bash

app_url=${UNIT10_APP_URL:-http://127.0.0.1:18090}

response=$(curl -fsS --max-time 2 "$app_url/api/items")

# API response の JSON を jq で処理し、DB から取得された item を確認する。
jq -r '.items[] | "\(.id)\t\(.name)\t\(.status)"' <<<"$response"
