#!/usr/bin/env bash

temp_dir=$(mktemp -d)

cleanup() {
  rm -f -- "$temp_dir/input.txt" "$temp_dir/output.txt"
  rmdir -- "$temp_dir" 2>/dev/null || true
}
trap cleanup EXIT

# intermediate file を一つの temporary workspace にまとめる。
printf '%s\n' 'alpha' 'beta' >"$temp_dir/input.txt"
tr '[:lower:]' '[:upper:]' <"$temp_dir/input.txt" >"$temp_dir/output.txt"
cat "$temp_dir/output.txt"
