#!/usr/bin/env bash

message='hello'
printf '%s\n' "$message"

# readonly にした variable は、その後の再代入を禁止できる。
readonly fixed_value='fixed'
printf '%s\n' "$fixed_value"

# export すると、後から起動する child process の environment に渡される。
export exported_value='from parent'
bash -c 'printf "child exported_value=%s\n" "$exported_value"'
