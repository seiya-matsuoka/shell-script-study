#!/usr/bin/env bash

# 最初の sleep は foreground で実行されるため、終了するまで次の行へ進まない。
# `bash -x` で実行すると、次の command がいつ実行されるかを trace で確認できる。
sleep 1

# & を付けると background で開始され、Shell は終了を待たず次の処理へ進む。
sleep 2 &
background_pid=$!

# jobs は現在の Bash が管理している job を表示する。
# Linux 全体の process 一覧を表示する ps とは対象が異なる。
jobs -l

# wait は指定した background process の終了を待つ。
wait "$background_pid"

# wait 自体の exit status は、待機した process の終了結果を反映する。
background_status=$?
printf 'background exit status=%s\n' "$background_status"
