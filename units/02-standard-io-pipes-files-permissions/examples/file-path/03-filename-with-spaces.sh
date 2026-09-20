#!/usr/bin/env bash

# filename に空白などが含まれる場合の quote の有無による違いを確認する。
# Shell expansion と quoting の詳細は Unit 03 で扱うため、ここでは実際の argument の分かれ方に注目する。

show_arguments() {
  printf 'argument count=%s\n' "$#"

  for argument in "$@"; do
    printf '<%s>\n' "$argument"
  done
}

filename='report 2026.txt'

# quote すると、空白を含む filename 全体が 1 argument として渡される。
show_arguments "$filename"

# quote しない場合は word splitting により複数 argument として扱われる。
show_arguments $filename

work_dir=$(mktemp -d)
file_path="$work_dir/$filename"

# 実際の file path を扱う場合も、空白を含むため variable を quote する。
printf '%s\n' 'content with spaced filename' >"$file_path"
cat "$file_path"

rm -f -- "$file_path"
rmdir "$work_dir"
