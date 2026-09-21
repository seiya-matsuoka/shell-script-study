#!/usr/bin/env bash

# pipefail を有効にしていない通常の pipeline では、
# pipeline 全体の exit status は基本的に最後の command の exit status になる。

# 途中の false は失敗するが、最後の true が成功するため pipeline 全体は 0 になる。
false | true
status_last_success=$?

# 最後の false が失敗するため、pipeline 全体も non-zero になる。
true | false
status_last_failure=$?

# 2 つの pipeline の違いを取得済み exit status から確認する。
printf 'false | true  -> %s\n' "$status_last_success"
printf 'true  | false -> %s\n' "$status_last_failure"
