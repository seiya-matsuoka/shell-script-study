#!/usr/bin/env bash

script_dir=$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
  pwd
)

# shellcheck source=02-report-lib.sh
source "$script_dir/02-report-lib.sh"

if (($# != 2)); then
  printf 'usage: %s INPUT_FILE OUTPUT_FILE\n' "$0" >&2
  exit 2
fi

input_file=$1
output_file=$2

if ! validate_input "$input_file"; then
  exit 1
fi

mkdir -p -- "$(dirname -- "$output_file")"
build_report "$input_file" >"$output_file"

printf 'report=%s\n' "$output_file"
