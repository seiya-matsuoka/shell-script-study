#!/usr/bin/env bash

# pipefail の無効・有効で、同じ pipeline の exit status がどう変わるか比較する。

# pipefail を明示的に無効化する。
# 最後の true が成功するため、途中の false が失敗しても pipeline 全体は 0 になる。
set +o pipefail

false | true
without_pipefail=$?

# pipefail を有効化すると、pipeline 内の失敗を pipeline 全体の non-zero として扱える。
set -o pipefail

false | true
with_pipefail=$?

printf 'without pipefail=%s\n' "$without_pipefail"
printf 'with pipefail=%s\n' "$with_pipefail"
