#!/usr/bin/env bash

# developer が local で CI と同じ品質確認を一括実行するための入口。
# 一つでも non-zero が返ればここで終了し、failure を呼び出し元へ伝播させる。
set -e

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
) || exit 1

bash "$script_dir/01-format-check.sh"
bash "$script_dir/02-shellcheck.sh"
bash "$script_dir/03-bats.sh"

printf '%s\n' 'all quality checks passed'
