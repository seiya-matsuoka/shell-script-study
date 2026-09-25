#!/usr/bin/env bash

work_dir=$(mktemp -d)
source_file="$work_dir/settings.conf"
backup_dir="$work_dir/backup"
mkdir "$backup_dir"
printf '%s\n' 'mode=production' >"$source_file"

# backup 名に timestamp を含め、世代を区別する基本例。
timestamp=$(date '+%Y%m%d-%H%M%S')
backup_file="$backup_dir/settings.conf.$timestamp.bak"
cp -- "$source_file" "$backup_file"

printf 'backup=%s\n' "$backup_file"
cat "$backup_file"

rm -f -- "$source_file" "$backup_file"
rmdir "$backup_dir" "$work_dir"
