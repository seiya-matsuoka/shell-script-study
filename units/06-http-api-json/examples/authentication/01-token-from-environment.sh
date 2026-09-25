#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}

# token は Script に hard-code せず environment variable から受け取る。
# 未設定なら request を送る前に終了する。
: "${API_TOKEN:?API_TOKEN is required}"

# Authorization header に token を渡すが、token value 自体は stdout / stderr へ出さない。
response=$(
  curl -sS \
    -H "Authorization: Bearer $API_TOKEN" \
    "$base_url/api/protected"
)

printf '%s\n' "$response"
