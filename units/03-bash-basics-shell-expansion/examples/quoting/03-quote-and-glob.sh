#!/usr/bin/env bash

work_dir=$(mktemp -d)
touch "$work_dir/first.txt" "$work_dir/second.txt"
pattern="$work_dir/*.txt"

show_arguments() {
  printf 'count=%s\n' "$#"
  for argument in "$@"; do
    printf '<%s>\n' "$argument"
  done
}

# quote しない場合、variable expansion 後の glob pattern が pathname expansion の対象になる。
show_arguments $pattern

# double quote すると glob pattern は展開されず、文字列そのものが 1 argument になる。
show_arguments "$pattern"

rm -f -- "$work_dir/first.txt" "$work_dir/second.txt"
rmdir "$work_dir"
