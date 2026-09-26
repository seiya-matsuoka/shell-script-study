#!/usr/bin/env bash

# cron などでは interactive shell の設定がそのまま引き継がれるとは限らないため、
# Script に必要な environment variable は明示的に前提確認する。
: "${UNIT07_TARGET:?UNIT07_TARGET is required}"

printf 'target=%s\n' "$UNIT07_TARGET"
