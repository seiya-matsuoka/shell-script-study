#!/usr/bin/env bash

# here document と here string は、command の stdin へデータを渡す方法の一つ。
# この Unit では redirect の応用として軽く確認し、複雑な利用方法には踏み込まない。

cat <<'TEXT'
first line from here document
second line from here document
TEXT

read -r value <<<'value from here string'
printf '%s\n' "$value"
