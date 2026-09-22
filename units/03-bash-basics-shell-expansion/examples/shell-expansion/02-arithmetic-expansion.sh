#!/usr/bin/env bash

count=5

# arithmetic expansion `$(( ))` は整数の算術式を評価する。
next=$((count + 1))
total=$((count * 3))
printf 'next=%s total=%s\n' "$next" "$total"
