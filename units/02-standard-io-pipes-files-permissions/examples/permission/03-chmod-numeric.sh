#!/usr/bin/env bash

# numeric notation では read=4、write=2、execute=1 を組み合わせて
# owner / group / others の permission を 3 桁で指定する。
#
# 640 = owner: rw-, group: r--, others: ---
# 755 = owner: rwx, group: r-x, others: r-x

work_dir=$(mktemp -d)
sample_file="$work_dir/sample.txt"

printf '%s\n' 'permission sample' >"$sample_file"

chmod 640 "$sample_file"
stat -c 'mode=%a %A' "$sample_file"

chmod 755 "$sample_file"
stat -c 'mode=%a %A' "$sample_file"

rm -f -- "$sample_file"
rmdir "$work_dir"
