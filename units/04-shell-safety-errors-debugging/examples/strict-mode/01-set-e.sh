#!/usr/bin/env bash

# set -e は、特定の command failure で Shell を終了させる。
# ただし「どんな non-zero でも必ず即終了する」という単純な規則ではないため、
# failure handling をすべて set -e 任せにしないことが重要。

bash -c '
  set -e
  printf "%s\n" "before failure"
  false
  printf "%s\n" "not executed"
'
status=$?

printf 'simple set -e status=%s\n' "$status"

# if の条件として実行する command は、failure 自体を分岐に利用するため
# set -e が有効でも、その non-zero だけで Shell が終了するわけではない。
bash -c '
  set -e
  if false; then
    printf "%s\n" "unexpected success"
  else
    printf "%s\n" "failure handled by if"
  fi
  printf "%s\n" "shell continues"
'
