#!/usr/bin/env bash

count=1

# until は条件が失敗している間、処理を繰り返す。while と逆向きの条件として読める。
until ((count > 3)); do
  printf 'count=%s\n' "$count"
  ((count += 1))
done
