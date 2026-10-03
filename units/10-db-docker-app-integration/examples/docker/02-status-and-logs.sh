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

# ps は現在の Container state、logs は起動後の出力を確認するために使う。
docker compose -f "$compose_file" ps db
printf '%s\n' '--- recent database logs ---'
docker compose -f "$compose_file" logs --no-color --tail 10 db
