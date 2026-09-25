#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
: "${API_TOKEN:?API_TOKEN is required}"

# token を source code に hard-code せず environment variable から受け取る。
# token value 自体は stdout / stderr へ出さない。
response=$(
  curl -sS -H "Authorization: Bearer $API_TOKEN" "$base_url/api/protected"
)
printf '%s\n' "$response"
