#!/usr/bin/env bash

# bash -x は、Bash が実行する command と展開後の値を trace として stderr へ出す。
# source code をそのまま表示するのではなく、実行時の展開結果を追うための手段。
bash -x -c '
  name="Bash"
  message="hello $name"
  printf "%s\n" "$message"
'
