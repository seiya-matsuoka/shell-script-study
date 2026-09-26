#!/usr/bin/env bash

report_name='daily-report.txt'
output_dir=${1:-/tmp/unit08-report}
output_file="$output_dir/$report_name"

mkdir -p -- "$output_dir"
printf 'report generated\n' >"$output_file"
printf 'output_file=%s\n' "$output_file"
