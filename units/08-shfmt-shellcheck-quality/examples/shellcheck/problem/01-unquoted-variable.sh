#!/usr/bin/env bash

# 学習用の問題コード。
# variable expansion を quote していないため、word splitting / glob expansion の影響を受ける。
name=${1:-"hello world"}
printf '%s\n' $name
