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

# Unit 10 の学習用 Container を停止・削除する。
docker compose -f "$compose_file" down
