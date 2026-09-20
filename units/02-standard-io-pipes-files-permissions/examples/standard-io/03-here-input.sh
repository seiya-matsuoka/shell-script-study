#!/usr/bin/env bash

# here document / here string も、command の stdin へ data を渡す方法である。
# この Unit では redirect の応用として基本的な形だけ確認する。

# here document は delimiter までの複数行を stdin として cat へ渡す。
cat <<'TEXT'
first line from here document
second line from here document
TEXT

# here string は一つの文字列を stdin として command へ渡す。
read -r value <<<'value from here string'
printf '%s\n' "$value"
