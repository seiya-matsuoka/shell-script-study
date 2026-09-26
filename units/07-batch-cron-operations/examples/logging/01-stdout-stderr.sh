#!/usr/bin/env bash

# 正常な処理結果と診断 message を stdout / stderr に分ける。
printf '%s\n' 'result: batch completed'
printf '%s\n' 'warning: sample diagnostic message' >&2
