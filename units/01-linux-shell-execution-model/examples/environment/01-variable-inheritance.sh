#!/usr/bin/env bash

# Shell variable を定義しただけでは、通常 child process の environment には含まれない。
# export した variable は、以降に起動する child process へ environment variable として渡される。

unset UNIT01_SHELL_ONLY
unset UNIT01_EXPORTED

UNIT01_SHELL_ONLY='shell only'
UNIT01_EXPORTED='exported value'

# まだ export していないため、child Bash から UNIT01_ で始まる変数は見えない。
# grep が一致しない場合は exit status 1 になるため、学習を継続できるよう `|| true` を付ける。
bash -c 'env | grep "^UNIT01_" || true'

export UNIT01_EXPORTED

# export 後は UNIT01_EXPORTED だけが child Bash の environment から確認できる。
bash -c 'env | grep "^UNIT01_" || true'
