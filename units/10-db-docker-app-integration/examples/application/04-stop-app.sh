#!/usr/bin/env bash

# start Script が保存した PID を使って、Unit 10 の補助 Application だけを停止する。
# PID file がない場合も cleanup 操作として安全に終了できる形にする。

pid_file=${UNIT10_APP_PID_FILE:-/tmp/unit10-support-app.pid}

if [[ ! -f $pid_file ]]; then
  printf '%s\n' 'application is not running'
  exit 0
fi

app_pid=$(<"$pid_file")

# PID file が残っていても process 自体は既に終了している場合があるため、
# kill -0 で存在を確認してから停止する。
if kill -0 "$app_pid" 2>/dev/null; then
  kill "$app_pid"
  wait "$app_pid" 2>/dev/null || true
fi

# process の有無にかかわらず PID file を削除し、次回起動へ stale state を残さない。
rm -f -- "$pid_file"
printf 'application stopped: pid=%s\n' "$app_pid"
