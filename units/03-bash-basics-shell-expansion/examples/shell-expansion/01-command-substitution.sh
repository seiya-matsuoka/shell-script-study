#!/usr/bin/env bash

# command substitution `$()` は command の stdout を文字列として取り込む。
current_directory=$(pwd)
printf 'current directory=%s\n' "$current_directory"
