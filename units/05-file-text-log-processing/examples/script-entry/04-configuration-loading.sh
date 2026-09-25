#!/usr/bin/env bash

work_dir=$(mktemp -d)
config_file="$work_dir/app.conf"

cat >"$config_file" <<'CONFIG'
APP_NAME='unit05-demo'
LOG_LEVEL='INFO'
CONFIG

# source した file は Shell code として実行されるため、信頼できる設定 file だけを対象にする。
if [[ ! -f $config_file ]]; then
  printf 'config file not found: %s\n' "$config_file" >&2
  exit 1
fi

source "$config_file"
printf 'app=%s log_level=%s\n' "$APP_NAME" "$LOG_LEVEL"

rm -f -- "$config_file"
rmdir "$work_dir"
