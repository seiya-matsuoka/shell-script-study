#!/usr/bin/env bash

# PostgreSQL Container の起動から CSV import、Application 起動、health / API、
# DB の最終確認、cleanup までを一つにつなぐ Unit 10 の統合 sample。
# 各 system の処理自体は専用 command に任せ、Shell は順序・待機・failure handling を担当する。

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/.."
  pwd
)

compose_file="$unit_dir/compose.yaml"
postgres_user=${POSTGRES_USER:-unit10}
postgres_db=${POSTGRES_DB:-unit10db}
app_url=${UNIT10_APP_URL:-http://127.0.0.1:18090}
app_log=$(mktemp)
app_pid=''

# 統合処理を開始する前に、後続 step で必要になる外部 command をまとめて確認する。
# 途中まで resource を起動してから dependency 不足に気付く状態を避ける。
require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null; then
    printf 'required command not found: %s\n' "$command_name" >&2
    return 1
  fi
}

# 統合 Script が自分で起動・生成した resource を終了時に片付ける。
# cleanup 自体の failure で元の終了理由を上書きしないよう、最初に status を保存する。
cleanup() {
  local status=$?

  if [[ -n $app_pid ]] && kill -0 "$app_pid" 2>/dev/null; then
    kill "$app_pid"
    wait "$app_pid" 2>/dev/null || true
  fi

  rm -f -- "$app_log"

  # この統合 sample が起動した学習用 Container を最後に片付ける。
  docker compose -f "$compose_file" down >/dev/null 2>&1 || true

  exit "$status"
}

# 正常終了だけでなく、途中 failure や signal でも同じ cleanup 経路を通す。
trap cleanup EXIT INT TERM

require_command docker || exit 1
require_command curl || exit 1
require_command jq || exit 1
require_command python3 || exit 1

printf '%s\n' '1. Start PostgreSQL container'
docker compose -f "$compose_file" up -d db

printf '%s\n' '2. Wait for PostgreSQL'
db_ready=false

# Container process の起動と PostgreSQL の readiness は別なので、
# pg_isready が成功するまで有限回 polling してから DB 処理へ進む。
for attempt in {1..15}; do
  if docker compose -f "$compose_file" exec -T db \
    pg_isready -q -U "$postgres_user" -d "$postgres_db"; then
    db_ready=true
    printf 'database is ready: attempt=%s\n' "$attempt"
    break
  fi

  sleep 1
done

if [[ $db_ready != true ]]; then
  printf '%s\n' 'database did not become ready' >&2
  exit 1
fi

printf '%s\n' '3. Create schema and import CSV'

# SQL / CSV の解釈は PostgreSQL に任せ、Shell では
# schema 作成 → data reset → CSV import という実行順序だけを制御する。
docker compose -f "$compose_file" exec -T db \
  psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" \
  -f /sql/01-schema.sql

docker compose -f "$compose_file" exec -T db \
  psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" \
  -f /sql/02-reset.sql

docker compose -f "$compose_file" exec -T db \
  psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" \
  -c "\copy items(name, status) FROM '/data/items.csv' WITH (FORMAT csv, HEADER true)"

printf '%s\n' '4. Start application'

# 補助 Application を background で起動し、cleanup で停止できるよう PID を保持する。
# 起動時の stdout / stderr は temporary log に保存し、health failure 時の調査情報として利用する。
python3 "$unit_dir/support/app/server.py" >"$app_log" 2>&1 &
app_pid=$!

printf '%s\n' '5. Wait for application health'
app_ready=false

# process の存在だけではなく、DB access を含む /health が UP になるまで待つ。
# curl の HTTP success と JSON 内の Application status の両方を確認する。
for attempt in {1..10}; do
  if response=$(curl -fsS --max-time 2 "$app_url/health" 2>/dev/null); then
    if [[ $(jq -r '.status' <<<"$response") == UP ]]; then
      app_ready=true
      printf 'application is healthy: attempt=%s\n' "$attempt"
      break
    fi
  fi

  sleep 1
done

if [[ $app_ready != true ]]; then
  printf '%s\n' 'application did not become healthy' >&2
  printf '%s\n' '--- application log ---' >&2
  cat "$app_log" >&2
  exit 1
fi

printf '%s\n' '6. Call API'

# DB から Application を経由して返された JSON を取得し、
# jq で内容を表示して HTTP 側から data flow を確認する。
api_response=$(curl -fsS --max-time 2 "$app_url/api/items")
jq '.' <<<"$api_response"

printf '%s\n' '7. Verify database'

# 最後に DB を直接 query し、API とは別の interface から import 結果を確認する。
# -A / -t で装飾を除き、Shell で比較しやすい row count だけを取得する。
db_count=$(
  docker compose -f "$compose_file" exec -T db \
    psql -v ON_ERROR_STOP=1 -U "$postgres_user" -d "$postgres_db" \
    -At -c 'SELECT COUNT(*) FROM items;'
)

printf 'database_item_count=%s\n' "$db_count"

# 想定件数と異なる場合は統合フロー全体を failure とし、trap の cleanup へつなぐ。
if [[ $db_count != 3 ]]; then
  printf 'unexpected database item count: %s\n' "$db_count" >&2
  exit 1
fi

printf '%s\n' 'integration flow completed'
