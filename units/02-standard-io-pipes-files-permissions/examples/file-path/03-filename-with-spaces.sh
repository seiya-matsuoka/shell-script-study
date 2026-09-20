#!/usr/bin/env bash

# filename に空白などが含まれる場合、variable を quote せず展開すると
# word splitting により複数 argument として扱われる可能性がある。
# Unit 03 で Shell expansion と quoting を詳しく扱うため、ここでは違いだけ確認する。

show_arguments() {
  printf 'argument count=%s\n' "$#"

  for argument in "$@"; do
    printf '<%s>\n' "$argument"
  done
}

filename='report 2026.txt'

show_arguments "$filename"
show_arguments $filename

work_dir=$(mktemp -d)
file_path="$work_dir/$filename"

printf '%s\n' 'content with spaced filename' >"$file_path"
cat "$file_path"

rm -f -- "$file_path"
rmdir "$work_dir"
