#!/usr/bin/env bash

input_file=$(mktemp)
seq 1 10 >"$input_file"

printf '%s\n' 'first 3 lines:'
head -n 3 "$input_file"

printf '%s\n' 'last 3 lines:'
tail -n 3 "$input_file"

rm -f -- "$input_file"
