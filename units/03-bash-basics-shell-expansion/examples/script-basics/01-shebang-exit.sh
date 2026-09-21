#!/usr/bin/env bash

# shebang は、Script を直接実行するときに利用する interpreter を示す。
# `/usr/bin/env bash` は PATH から bash を探して実行する書き方。
# `#` から始まる comment は Bash の実行対象にならない。

printf '%s\n' 'script started'

# exit は Script 全体をここで終了し、指定した exit status を呼び出し元へ返す。
exit 0

printf '%s\n' 'this line is not executed'
