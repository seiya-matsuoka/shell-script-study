#!/usr/bin/env bash

# Shell から Docker Compose を経由して Container 内の psql を実行し、
# 「Shell → Container → PostgreSQL」という command chain を確認する sample。

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

# -T で pseudo-TTY を割り当てず、Script から扱いやすい非対話実行にする。
# ON_ERROR_STOP を有効にし、SQL error を psql の failure として Shell 側へ伝播させる。
docker compose -f "$compose_file" exec -T db \
  psql \
  -v ON_ERROR_STOP=1 \
  -U "$postgres_user" \
  -d "$postgres_db" \
  -c 'SELECT current_database(), current_user;'
