#!/usr/bin/env bash

# 学習用の問題コード。
# cd が失敗しても後続処理へ進むため、想定外の directory で処理する可能性がある。
target_dir=${1:-/tmp/unit08-missing-directory}

cd "$target_dir"
printf 'current_directory=%s\n' "$PWD"
