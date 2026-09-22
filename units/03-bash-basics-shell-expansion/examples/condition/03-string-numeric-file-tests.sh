#!/usr/bin/env bash

left='alpha'
right='beta'
number=10
temp_file=$(mktemp)

# string comparison。
if [[ $left != "$right" ]]; then
  printf '%s\n' 'strings differ'
fi

# numeric comparison。-gt は greater than。
if [[ $number -gt 5 ]]; then
  printf '%s\n' 'number is greater than 5'
fi

# file test。-f は regular file が存在するかを確認する。
if [[ -f $temp_file ]]; then
  printf '%s\n' 'temporary file exists'
fi

rm -f -- "$temp_file"
