#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/alpha.txt" "$work_dir/beta.txt" "$work_dir/gamma.log"

# pathname expansion（glob）により `*.txt` に一致する path へ展開される。
for path in "$work_dir"/*.txt; do
  printf '%s\n' "$path"
done

rm -f -- "$work_dir/alpha.txt" "$work_dir/beta.txt" "$work_dir/gamma.log"
rmdir "$work_dir"
