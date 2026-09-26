#!/usr/bin/env bash

# cron などから実行された場合に差が出やすい runtime context を確認する。
# 手動実行時の値を当然の前提にせず、実際の environment を観察するための sample。
printf 'pwd=%s\n' "$PWD"
printf 'PATH=%s\n' "${PATH:-<unset>}"
printf 'HOME=%s\n' "${HOME:-<unset>}"
printf 'SHELL=%s\n' "${SHELL:-<unset>}"
