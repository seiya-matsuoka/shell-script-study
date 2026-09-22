#!/usr/bin/env bash

unset configured_value
empty_value=''

# ${var:-default} は var が unset または empty の場合に default を利用する。
printf 'unset -> %s\n' "${configured_value:-default value}"
printf 'empty -> %s\n' "${empty_value:-default value}"

configured_value='configured'
printf 'set -> %s\n' "${configured_value:-default value}"
