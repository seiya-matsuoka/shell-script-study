#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/recent.log"
touch -d '10 days ago' "$work_dir/old.log"

# mtime を条件に古い log を cleanup する。境界の定義は find の仕様を確認して使う。
find "$work_dir" -maxdepth 1 -type f -name '*.log' -mtime +7 -print -delete

printf 'recent remains=%s\n' "$([[ -f $work_dir/recent.log ]] && printf yes || printf no)"
printf 'old remains=%s\n' "$([[ -f $work_dir/old.log ]] && printf yes || printf no)"

rm -f -- "$work_dir/recent.log"
rmdir "$work_dir"
