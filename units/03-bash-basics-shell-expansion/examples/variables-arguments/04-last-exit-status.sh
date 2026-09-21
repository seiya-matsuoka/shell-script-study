#!/usr/bin/env bash

# $? は直前に実行した command の exit status。
false
status=$?
printf 'status=%s\n' "$status"
