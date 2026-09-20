#!/usr/bin/env bash

# environment variable は parent から child へ渡せるが、
# child 側で値を変更しても、その変更が parent process へ自動的に戻るわけではない。

export UNIT01_DIRECTION='parent value'

bash -c '
  UNIT01_DIRECTION="child value"
  export UNIT01_DIRECTION

  # child process 内では変更後の値が見える。
  printf "child=%s\n" "$UNIT01_DIRECTION"
'

# child process が終了しても、parent 側の値は変更前のまま残る。
printf 'parent=%s\n' "$UNIT01_DIRECTION"
