#!/usr/bin/env bash

# Unit 10 の補助 Application を background process として起動する。
# PID と log の保存先を外部化し、後続の health check / stop Script から同じ process を扱えるようにする。

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(
  cd -- "$script_dir/../.."
  pwd
)

pid_file=${UNIT10_APP_PID_FILE:-/tmp/unit10-support-app.pid}
log_file=${UNIT10_APP_LOG_FILE:-/tmp/unit10-support-app.log}

# 前回の PID file が残っている場合は、実際にその process が存在するか確認する。
# process が生きていれば二重起動を避け、存在しなければ stale な PID file を削除する。
if [[ -f $pid_file ]]; then
  existing_pid=$(<"$pid_file")

  if kill -0 "$existing_pid" 2>/dev/null; then
    printf 'application is already running: pid=%s\n' "$existing_pid" >&2
    exit 1
  fi

  rm -f -- "$pid_file"
fi

# Application を background process として起動し、後続 Script から管理できるよう PID を保存する。
# stdout / stderr は log file へまとめ、Terminal から切り離した後でも起動時の情報を確認できるようにする。
python3 "$unit_dir/support/app/server.py" >"$log_file" 2>&1 &
app_pid=$!
printf '%s\n' "$app_pid" >"$pid_file"

printf 'application started: pid=%s log=%s\n' "$app_pid" "$log_file"
