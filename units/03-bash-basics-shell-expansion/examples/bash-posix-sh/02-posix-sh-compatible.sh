#!/bin/sh

# POSIX sh で利用できる基本構文だけを使った例。
value='portable'
if [ "$value" = 'portable' ]; then
  printf '%s\n' 'POSIX sh compatible syntax'
fi

for item in alpha beta gamma; do
  printf '<%s>\n' "$item"
done
