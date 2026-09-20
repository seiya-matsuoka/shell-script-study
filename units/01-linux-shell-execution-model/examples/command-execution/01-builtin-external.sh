#!/usr/bin/env bash

# Shell で実行できる command は、すべて同じ種類ではない。
# type は、Bash が command 名を builtin / external command などのどれとして解釈するかを表示する。
# command -v は、実際に command 名から解決される対象を確認するときに利用できる。

type cd
type printf
type export

type ls
type sleep
type ps

command -v cd
command -v ls
command -v sleep
