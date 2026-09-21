#!/usr/bin/env bash

# chmod の symbolic notation で execute permission を追加・削除する。
# u / g / o は owner(user) / group / others を表し、+ / - / = で permission を操作できる。

work_dir=$(mktemp -d)
sample_file="$work_dir/sample.sh"

printf '%s\n' '#!/usr/bin/env bash' >"$sample_file"
printf '%s\n' 'printf "%s\n" "sample"' >>"$sample_file"

# u+x で owner に execute permission を追加する。
chmod u+x "$sample_file"
ls -l "$sample_file"

# u-x で owner から execute permission を削除する。
chmod u-x "$sample_file"
ls -l "$sample_file"

rm -f -- "$sample_file"
rmdir "$work_dir"
