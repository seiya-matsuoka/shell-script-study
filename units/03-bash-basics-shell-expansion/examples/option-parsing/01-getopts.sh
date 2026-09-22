#!/usr/bin/env bash

usage() {
  printf 'usage: %s [-v] [-n name] [argument]\n' "$0"
}

verbose=false
name='default'

# getopts は short option を順番に解析する Bash builtin。`n:` は -n が argument を必要とすることを表す。
while getopts ':vn:' option; do
  case "$option" in
  v) verbose=true ;;
  n) name=$OPTARG ;;
  :)
    printf 'option -%s requires an argument\n' "$OPTARG" >&2
    usage >&2
    exit 2
    ;;
  \?)
    printf 'unknown option: -%s\n' "$OPTARG" >&2
    usage >&2
    exit 2
    ;;
  esac
done

# getopts が解析した option を positional parameter から取り除く。
shift $((OPTIND - 1))

if [[ $verbose == true ]]; then
  printf 'name=%s\n' "$name"
fi
if (($# > 0)); then
  printf 'argument=%s\n' "$1"
fi
