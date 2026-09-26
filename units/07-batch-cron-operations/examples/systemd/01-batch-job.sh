#!/usr/bin/env bash

# systemd service / timer から実行される処理本体を想定した最小 sample。
# stdout / stderr と exit status を scheduler / supervisor 側で扱える形にする。
printf '%s INFO  systemd batch job started\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
printf '%s INFO  systemd batch job finished\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
