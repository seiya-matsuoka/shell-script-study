#!/usr/bin/env bash
base_url=${UNIT06_BASE_URL:-http://127.0.0.1:18080}
target_name=${1:-gamma}
response=$(curl -sS "$base_url/api/items")

# Shell variable を jq expression の文字列へ直接埋め込まず、
# --arg で jq variable として渡して data と jq program を分離する。
item_id=$(
  jq -r \
    --arg target "$target_name" \
    '.items[] | select(.name == $target) | .id' \
    <<<"$response"
)

if [[ -z $item_id ]]; then
  printf 'item not found: %s\n' "$target_name" >&2
  exit 1
fi

printf 'name=%s id=%s\n' "$target_name" "$item_id"
