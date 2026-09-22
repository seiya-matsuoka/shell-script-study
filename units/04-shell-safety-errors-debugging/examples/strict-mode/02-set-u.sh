#!/usr/bin/env bash

# set -u は、未定義 variable の参照を error として扱う。
# typo や設定値の渡し忘れに気付きやすくなる一方、
# optional な値には parameter expansion などで明示的に対応する必要がある。

bash -c '
  set -u
  printf "%s\n" "$UNDEFINED_VALUE"
' 2>/dev/null
status=$?

printf 'undefined variable status=%s\n' "$status"

bash -c '
  set -u
  printf "optional=<%s>\n" "${OPTIONAL_VALUE:-}"
'
