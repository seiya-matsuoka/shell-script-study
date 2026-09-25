#!/usr/bin/env bash

work_dir=$(mktemp -d)
source_dir="$work_dir/source"
archive_dir="$work_dir/archive"
mkdir "$source_dir" "$archive_dir"
printf '%s\n' 'sample' >"$source_dir/report.txt"

# cp は元 file を残して複製し、mv は元 path から target path へ移動する。
cp -- "$source_dir/report.txt" "$archive_dir/report-copy.txt"
mv -- "$source_dir/report.txt" "$archive_dir/report-moved.txt"

printf 'copy exists=%s\n' "$([[ -f $archive_dir/report-copy.txt ]] && printf yes || printf no)"
printf 'moved exists=%s\n' "$([[ -f $archive_dir/report-moved.txt ]] && printf yes || printf no)"
printf 'source remains=%s\n' "$([[ -f $source_dir/report.txt ]] && printf yes || printf no)"

rm -f -- "$archive_dir/report-copy.txt" "$archive_dir/report-moved.txt"
rmdir "$source_dir" "$archive_dir" "$work_dir"
