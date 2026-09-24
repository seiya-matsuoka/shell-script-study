#!/usr/bin/env bash

trace_file=$(mktemp)
DEMO_TOKEN='dummy-secret-for-learning'

# set -x は実行 command と展開後の argument を stderr へ出すため、
# secret を含む command を trace すると値が log に露出する可能性がある。
{
  set -x
  printf 'token=%s\n' "$DEMO_TOKEN" >/dev/null
  set +x
} 2>"$trace_file"

printf '%s\n' 'trace contains the dummy secret:'
grep -F -- "$DEMO_TOKEN" "$trace_file" || true

# real secret を扱う箇所では xtrace を無効化するなど、debug trace と secret の境界を意識する。
rm -f -- "$trace_file"
