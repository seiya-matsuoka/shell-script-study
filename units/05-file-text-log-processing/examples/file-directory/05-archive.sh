#!/usr/bin/env bash

work_dir=$(mktemp -d)
data_dir="$work_dir/data"
archive_file="$work_dir/data.tar.gz"
mkdir "$data_dir"
printf '%s\n' 'alpha' >"$data_dir/a.txt"
printf '%s\n' 'beta' >"$data_dir/b.txt"

# tar で directory をまとめて gzip 圧縮する。-C で archive 内 path を整理する。
tar -czf "$archive_file" -C "$work_dir" data

printf '%s\n' 'archive contents:'
tar -tzf "$archive_file"

rm -f -- "$data_dir/a.txt" "$data_dir/b.txt" "$archive_file"
rmdir "$data_dir" "$work_dir"
