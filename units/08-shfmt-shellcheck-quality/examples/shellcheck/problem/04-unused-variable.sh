#!/usr/bin/env bash

# 学習用の問題コード。
# report_name を定義しているが、その後どこからも参照していない。
report_name='daily-report.txt'
output_dir=${1:-/tmp/unit08-report}

mkdir -p -- "$output_dir"
printf 'output_dir=%s\n' "$output_dir"
