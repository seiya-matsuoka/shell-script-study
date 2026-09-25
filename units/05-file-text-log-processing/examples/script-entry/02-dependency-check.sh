#!/usr/bin/env bash

# 後続処理で必要な external command を Script の入口で確認する。
required_commands=(grep awk sort)

for command_name in "${required_commands[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'required command not found: %s\n' "$command_name" >&2
    exit 1
  fi
done

printf '%s\n' 'all dependencies are available'
