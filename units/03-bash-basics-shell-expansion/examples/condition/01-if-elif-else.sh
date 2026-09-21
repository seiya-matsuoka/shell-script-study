#!/usr/bin/env bash

score=${1:-75}

# (( )) は Bash の arithmetic context。整数条件を自然に書ける。
if ((score >= 80)); then
  printf '%s\n' 'high'
elif ((score >= 60)); then
  printf '%s\n' 'middle'
else
  printf '%s\n' 'low'
fi
