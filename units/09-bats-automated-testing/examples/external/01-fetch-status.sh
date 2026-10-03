#!/usr/bin/env bash

: "${API_URL:?API_URL is required}"

# curl は外部依存なので、テストでは実ネットワークへ接続せず
# PATH 上の fake command へ差し替えられる構造にしている。
if ! response=$(curl -fsS "$API_URL/status"); then
  printf '%s\n' 'failed to fetch remote status' >&2
  exit 1
fi

printf 'remote_status=%s\n' "$response"
