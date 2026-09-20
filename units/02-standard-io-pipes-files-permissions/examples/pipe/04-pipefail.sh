#!/usr/bin/env bash

# pipefail を有効にすると、pipeline の途中で command が失敗した場合も
# pipeline 全体を non-zero として扱える。
#
# ここでは比較のため、同じ pipeline を pipefail の無効・有効で実行する。

set +o pipefail

false | true
without_pipefail=$?

set -o pipefail

false | true
with_pipefail=$?

printf 'without pipefail=%s\n' "$without_pipefail"
printf 'with pipefail=%s\n' "$with_pipefail"
