#!/usr/bin/env bash

# /dev/null は、不要な出力を破棄するときに利用できる特殊な file。

# stdout だけを /dev/null へ redirect するため、この文字列は表示されない。
printf '%s\n' 'this stdout is discarded' >/dev/null

# stderr だけを /dev/null へ redirect する場合も同様に表示されない。
printf '%s\n' 'this stderr is discarded' >&2 2>/dev/null

# redirect していない stdout は通常どおり Terminal に表示される。
printf '%s\n' 'visible output'
