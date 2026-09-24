#!/usr/bin/env bash

number=''

while getopts ':n:' option; do
  case "$option" in
  n)
    number=$OPTARG
    ;;
  :)
    printf 'option -%s requires an argument\n' "$OPTARG" >&2
    exit 2
    ;;
  \?)
    printf 'unknown option: -%s\n' "$OPTARG" >&2
    exit 2
    ;;
  esac
done

# option が存在するだけではなく、期待する numeric format かも検証する。
if [[ ! $number =~ ^[0-9]+$ ]]; then
  printf 'number must be a non-negative integer: <%s>\n' "$number" >&2
  exit 2
fi

printf 'number=%s\n' "$number"
