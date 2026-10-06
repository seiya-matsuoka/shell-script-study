#!/usr/bin/env bash

# local と GitHub Actions では利用できる environment variable が異なる。
# secret ではない実行環境情報だけを表示し、同じ Script がどこで動いているか確認する。
if [[ ${GITHUB_ACTIONS:-false} == true ]]; then
  execution_environment='github-actions'
else
  execution_environment='local'
fi

printf 'execution_environment=%s\n' "$execution_environment"
printf 'runner_os=%s\n' "${RUNNER_OS:-local}"
printf 'ref_name=%s\n' "${GITHUB_REF_NAME:-local}"
