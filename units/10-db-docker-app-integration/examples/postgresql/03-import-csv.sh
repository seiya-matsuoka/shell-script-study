#!/usr/bin/env bash

# CSV を Bash で解析せず、PostgreSQL の \copy へ渡して DB import する流れを確認する。
# Shell は schema 準備・reset・import・結果確認という処理順序を組み立てる。

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

# 同じ connection option を繰り返さず、Container 内の psql 実行を一つの関数へまとめる。
# "$@" により -f / -c など、この sample で変化する psql option だけを呼び出し側から渡す。
psql_in_db() {
  docker compose -f "$compose_file" exec -T db \
    psql \
    -v ON_ERROR_STOP=1 \
    -U "$postgres_user" \
    -d "$postgres_db" \
    "$@"
}

# 再実行しても同じ学習結果になるよう、schema を用意して data を reset してから import する。
psql_in_db -f /sql/01-schema.sql
psql_in_db -f /sql/02-reset.sql

# CSV は Container へ read-only mount しており、psql の \copy から読み込む。
psql_in_db -c "\copy items(name, status) FROM '/data/items.csv' WITH (FORMAT csv, HEADER true)"

# import 後の row count を返し、Shell から DB 処理結果を観察できるようにする。
psql_in_db -At -c 'SELECT COUNT(*) FROM items;'
