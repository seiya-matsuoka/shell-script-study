#!/usr/bin/env bash

name='Bash'
printf '%s\n' "$name"

# variable 名の直後に文字を続ける場合は ${name} と境界を明示する。
printf '%s\n' "${name}_script"
