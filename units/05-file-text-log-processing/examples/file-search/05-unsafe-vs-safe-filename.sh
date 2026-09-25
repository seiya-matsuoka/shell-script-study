#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/alpha.txt" "$work_dir/report 2026.txt"

# command substitution の結果を unquoted に展開すると、空白を含む path の境界が壊れる。
unsafe_count=0
for path in $(find "$work_dir" -type f -name '*.txt' -print); do
  ((unsafe_count += 1))
done

# NUL delimiter なら path の境界を維持できる。
safe_count=0
while IFS= read -r -d '' path; do
  ((safe_count += 1))
done < <(find "$work_dir" -type f -name '*.txt' -print0)

printf 'unsafe loop count=%s\n' "$unsafe_count"
printf 'safe loop count=%s\n' "$safe_count"

rm -f -- "$work_dir/alpha.txt" "$work_dir/report 2026.txt"
rmdir "$work_dir"
