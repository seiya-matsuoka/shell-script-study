#!/usr/bin/env bash

# pipefail を有効にしていない通常の pipeline では、
# pipeline 全体の exit status は基本的に最後の command の exit status になる。

false | true
status_last_success=$?

true | false
status_last_failure=$?

printf 'false | true  -> %s\n' "$status_last_success"
printf 'true  | false -> %s\n' "$status_last_failure"
