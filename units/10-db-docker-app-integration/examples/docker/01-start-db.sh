#!/usr/bin/env bash

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/../.."
  pwd
)

compose_file="$unit_dir/compose.yaml"

# Container の起動処理を Shell から実行し、command の失敗はそのまま job failure として扱う。
if ! docker compose -f "$compose_file" up -d db; then
  printf '%s\n' 'failed to start database container' >&2
  exit 1
fi

printf '%s\n' 'database container started'
