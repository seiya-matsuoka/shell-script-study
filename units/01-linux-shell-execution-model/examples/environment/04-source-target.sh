#!/usr/bin/env bash

# 通常実行と source の違いを確認するための学習用 file。
#
# `bash 04-source-target.sh`:
#   別の Bash process で代入されるため、呼び出し元の Shell に値は残らない。
#
# `source 04-source-target.sh`:
#   現在の Shell 自身でこの file の内容を実行するため、代入した値が呼び出し元に残る。
#
# この file 自体は「変数を設定する」という役割だけにし、
# 通常実行 / source 後の確認は README に記載する command から行う。

UNIT01_SOURCE_VALUE='set-by-source-target'
