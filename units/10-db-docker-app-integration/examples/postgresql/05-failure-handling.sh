#!/usr/bin/env bash

# DB 側で発生した SQL failure が psql の exit status を通して Shell へ伝わることを確認する。
# 正常系ではなく、system boundary を越えた failure propagation を観察するための sample。

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

# 存在しない table への query を実行し、psql の failure を Shell 側で明示的に扱う。
if docker compose -f "$compose_file" exec -T db \
  psql \
  -v ON_ERROR_STOP=1 \
  -U "$postgres_user" \
  -d "$postgres_db" \
  -c 'SELECT * FROM table_that_does_not_exist;'; then
  printf '%s\n' 'unexpected success' >&2
  exit 1
else
  # else に入った直後の $? は失敗した docker compose exec / psql chain の status なので、
  # その値を保持して Script 自身の exit status として返す。
  status=$?
  printf 'database command failed as expected: status=%s\n' "$status" >&2
  exit "$status"
fi
