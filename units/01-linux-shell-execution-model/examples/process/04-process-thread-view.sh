#!/usr/bin/env bash

# process と thread は同じ概念ではない。
# ps -T を使い、現在の Bash process に属する thread を PID と SPID で確認する。
# この Unit では thread programming や scheduler の詳細には踏み込まない。

ps -T -p "$BASHPID" -o pid=,spid=,comm=
