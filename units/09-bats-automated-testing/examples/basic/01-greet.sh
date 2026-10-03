#!/usr/bin/env bash

if (($# != 1)); then
  printf 'usage: %s NAME\n' "$0" >&2
  exit 2
fi

name=$1

if [[ -z $name ]]; then
  printf '%s\n' 'NAME must not be empty' >&2
  exit 1
fi

printf 'hello, %s\n' "$name"
