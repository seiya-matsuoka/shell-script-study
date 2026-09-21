#!/usr/bin/env bash

count=1

# while は条件が成功している間、処理を繰り返す。
while ((count <= 3)); do
  printf 'count=%s\n' "$count"
  ((count += 1))
done
