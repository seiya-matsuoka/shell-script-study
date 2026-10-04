#!/usr/bin/env bash

# CI の build / artifact の位置づけを確認するため、workflow 実行情報を小さな text artifact として生成する。
# output directory を environment variable で差し替えられるようにし、Bats では temporary directory を利用できる。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
) || exit 1
unit_dir=$(
  cd -- "$script_dir/.." && pwd
) || exit 1

output_dir=${UNIT11_OUTPUT_DIR:-"$unit_dir/dist"}
output_file="$output_dir/ci-summary.txt"

mkdir -p -- "$output_dir"

if [[ ${GITHUB_ACTIONS:-false} == true ]]; then
  execution_environment='github-actions'
else
  execution_environment='local'
fi

# repository content を build する例ではなく、artifact が「workflow が生成した file」を
# 後続処理や workflow run 後へ受け渡す仕組みであることを観察するための最小成果物にする。
{
  printf 'execution_environment=%s\n' "$execution_environment"
  printf 'runner_os=%s\n' "${RUNNER_OS:-local}"
  printf 'ref_name=%s\n' "${GITHUB_REF_NAME:-local}"
  printf 'commit_sha=%s\n' "${GITHUB_SHA:-local}"
} >"$output_file"

printf 'artifact_file=%s\n' "$output_file"
