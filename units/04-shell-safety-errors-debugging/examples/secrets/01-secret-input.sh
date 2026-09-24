#!/usr/bin/env bash

# 実際の password / token を source code に hard-code せず、
# environment variable、permission を制限した file、CI secrets など外部から受け取る。
: "${API_TOKEN:?API_TOKEN is required}"

# secret 自体を output へ出さず、存在だけを利用する。
printf 'API_TOKEN is set (length=%s)\n' "${#API_TOKEN}"
