#!/usr/bin/env bash

set -u

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)
unit_dir=$(dirname -- "$script_dir")

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null; then
    printf 'required command not found: %s\n' "$command_name" >&2
    return 1
  fi
}

require_command shfmt || exit 1
require_command shellcheck || exit 1

cd -- "$unit_dir" || exit 1

# 学習用の problem samples は意図的な warning / syntax error を含むため除外する。
# 通常コードだけを同じ formatter / static analysis のルールで確認する。
printf '%s\n' '== shfmt check =='
shfmt -i 2 -d examples/shfmt/02-formatted.sh examples/shellcheck/fixed examples/shellcheck/suppression quality/quality-check.sh

printf '%s\n' '== ShellCheck =='
shellcheck examples/shfmt/02-formatted.sh examples/shellcheck/fixed/*.sh examples/shellcheck/suppression/*.sh quality/quality-check.sh

printf '%s\n' 'quality checks passed'
