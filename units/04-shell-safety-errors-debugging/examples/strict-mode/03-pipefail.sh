#!/usr/bin/env bash

# pipefail が無効な通常状態では、pipeline 全体の status は基本的に最後の command の結果になる。
bash -c '
  set +o pipefail
  false | true
  printf "without pipefail=%s\n" "$?"
'

# pipefail を有効にすると、途中の command failure も pipeline 全体へ反映できる。
bash -c '
  set -o pipefail
  false | true
  printf "with pipefail=%s\n" "$?"
'
