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
postgres_user=${POSTGRES_USER:-unit10}
postgres_db=${POSTGRES_DB:-unit10db}
postgres_port=${POSTGRES_PORT:-55432}

# password 自体は表示せず、接続先を特定するために必要な情報だけを確認する。
printf 'host=%s\n' '127.0.0.1'
printf 'port=%s\n' "$postgres_port"
printf 'database=%s\n' "$postgres_db"
printf 'user=%s\n' "$postgres_user"

# Container 内の psql から、実際に利用している connection を確認する。
docker compose -f "$compose_file" exec -T db \
  psql \
  -v ON_ERROR_STOP=1 \
  -U "$postgres_user" \
  -d "$postgres_db" \
  -c '\conninfo'
