#!/usr/bin/env bash

value='hello world'

# [ ] は test command として動作するため、variable を quote して 1 argument に保つのが基本。
if [ "$value" = 'hello world' ]; then
  printf '%s\n' '[ ] matched'
fi

# [[ ]] は Bash の conditional expression。word splitting / pathname expansion の扱いが [ ] と異なる。
if [[ $value == 'hello world' ]]; then
  printf '%s\n' '[[ ]] matched'
fi
