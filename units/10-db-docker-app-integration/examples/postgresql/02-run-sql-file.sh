#!/usr/bin/env bash

# repository 内の SQL file を、Compose で mount された /sql 経由で Container 内の psql から実行する。
# Shell は SQL 自体を組み立てず、対象 file の validation と command 実行を担当する。

if (($# != 1)); then
  printf 'usage: %s SQL_FILE_NAME\n' "$0" >&2
  exit 2
fi

sql_file=$1

# /sql 配下へ mount した学習用 SQL file だけを対象にする。
if [[ $sql_file == */* ]]; then
  printf 'SQL_FILE_NAME must be a file name only: %s\n' "$sql_file" >&2
  exit 2
fi

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/../.."
  pwd
)

# host 側にも同名 file が存在することを先に確認し、誤った file name を DB command まで渡さない。
if [[ ! -f $unit_dir/sql/$sql_file ]]; then
  printf 'SQL file not found: %s\n' "$sql_file" >&2
  exit 1
fi

compose_file="$unit_dir/compose.yaml"
postgres_user=${POSTGRES_USER:-unit10}
postgres_db=${POSTGRES_DB:-unit10db}

# ON_ERROR_STOP により SQL error が発生した場合は psql 自体を failure にする。
# /sql は compose.yaml で read-only mount されているため、host と Container で同じ SQL file を参照する。
docker compose -f "$compose_file" exec -T db \
  psql \
  -v ON_ERROR_STOP=1 \
  -U "$postgres_user" \
  -d "$postgres_db" \
  -f "/sql/$sql_file"
