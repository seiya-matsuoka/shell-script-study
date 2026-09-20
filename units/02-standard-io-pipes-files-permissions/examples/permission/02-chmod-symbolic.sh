#!/usr/bin/env bash

# chmod の symbolic notation では、u(user/owner)、g(group)、o(others) などを使い、
# `+` / `-` / `=` で permission を追加・削除・設定できる。

work_dir=$(mktemp -d)
sample_file="$work_dir/sample.sh"

printf '%s\n' '#!/usr/bin/env bash' >"$sample_file"
printf '%s\n' 'printf "%s\n" "sample"' >>"$sample_file"

chmod u+x "$sample_file"
ls -l "$sample_file"

chmod u-x "$sample_file"
ls -l "$sample_file"

rm -f -- "$sample_file"
rmdir "$work_dir"
