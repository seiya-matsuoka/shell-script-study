#!/usr/bin/env bash

name=${1:-"hello world"}

# variable を 1 argument として扱いたいので double quote する。
printf '%s\n' "$name"
