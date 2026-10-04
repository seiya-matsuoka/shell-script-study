#!/usr/bin/env bash

# secret は environment variable として受け取れるが、値そのものを log へ出力しない。
# 未設定時は学習 workflow を壊さず skip し、設定された場合だけ「存在すること」だけを確認する。
if [[ -z ${UNIT11_SAMPLE_TOKEN:-} ]]; then
  printf '%s\n' 'UNIT11_SAMPLE_TOKEN is not configured; secret example skipped'
  exit 0
fi

printf '%s\n' 'UNIT11_SAMPLE_TOKEN is configured; value is not printed'
