#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}

# -H で request header を追加する。
response=$(curl -sS -H 'X-Demo: unit06' "$base_url/api/header")
printf '%s\n' "$response"
