#!/usr/bin/env bash

# brace expansion は複数の word を生成する Bash の展開。
printf '%s\n' file-{a,b,c}.txt
printf '%s\n' number-{1..3}
