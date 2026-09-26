#!/usr/bin/env bash

# current working directory は「Script が置かれている directory」とは限らない。
# Script 自身の場所を基準にしたい場合は BASH_SOURCE から求める。
script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)

printf 'current_working_directory=%s\n' "$PWD"
printf 'script_directory=%s\n' "$script_dir"

# relative path を current working directory 基準で使うか、
# script directory 基準で使うかは意図を明確にする。
printf 'cwd_relative=%s\n' "$PWD/output"
printf 'script_relative=%s\n' "$script_dir/output"
