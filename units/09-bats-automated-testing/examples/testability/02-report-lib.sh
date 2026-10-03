#!/usr/bin/env bash

validate_input() {
  local input_file=$1

  if [[ ! -f $input_file ]]; then
    printf 'input file not found: %s\n' "$input_file" >&2
    return 1
  fi
}

report_status() {
  local input_file=$1
  local line_count

  line_count=$(wc -l <"$input_file")

  if ((line_count == 0)); then
    printf '%s\n' 'EMPTY'
  else
    printf '%s\n' 'READY'
  fi
}

build_report() {
  local input_file=$1
  local status
  local line_count

  status=$(report_status "$input_file")
  line_count=$(wc -l <"$input_file")

  printf 'status=%s\n' "$status"
  printf 'lines=%s\n' "$line_count"
}
