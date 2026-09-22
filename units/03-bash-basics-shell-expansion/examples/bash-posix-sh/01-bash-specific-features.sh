#!/usr/bin/env bash

# Bash 固有機能を意図的に利用する例。/bin/sh 互換性は目的にしない。
items=('alpha' 'beta gamma')
for item in "${items[@]}"; do
  printf '<%s>\n' "$item"
done

value='beta gamma'
if [[ $value == 'beta gamma' ]]; then
  printf '%s\n' '[[ ]] matched'
fi

show_local() {
  local message='local value'
  printf '%s\n' "$message"
}
show_local
