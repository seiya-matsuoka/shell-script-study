#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}

# GET は resource や状態の取得で頻繁に利用する。
# -sS は progress meter を抑えつつ、通信 error は stderr に表示する。
response=$(curl -sS "$base_url/api/user")
printf '%s\n' "$response"
