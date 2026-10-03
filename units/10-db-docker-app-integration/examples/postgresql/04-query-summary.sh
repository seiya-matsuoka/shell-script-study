#!/usr/bin/env bash

# DB 集計処理を Shell に書き直さず、SQL file として PostgreSQL へ実行させる sample。
# Shell は connection information と実行対象を組み合わせ、結果をそのまま呼び出し元へ返す。

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

# SQL error が発生した場合は ON_ERROR_STOP により non-zero を返し、
# query failure を Shell 側の command failure として扱えるようにする。
docker compose -f "$compose_file" exec -T db \
  psql \
  -v ON_ERROR_STOP=1 \
  -U "$postgres_user" \
  -d "$postgres_db" \
  -f /sql/03-summary.sql
