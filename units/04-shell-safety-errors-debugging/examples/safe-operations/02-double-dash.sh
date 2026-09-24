#!/usr/bin/env bash

work_dir=$(mktemp -d)

(
  cd "$work_dir"
  # `-temporary.txt` のような filename は option と誤解される可能性がある。
  touch -- '-temporary.txt'
  # `--` は、これ以降を option ではなく operand として扱う区切りとして利用される。
  rm -- '-temporary.txt'
)

rmdir "$work_dir"
printf '%s\n' 'file beginning with - removed safely'
