#!/usr/bin/env bash

# この variable は「外部 loader が読む metadata」という想定の学習例で、
# Script 自身から参照しないことが意図された状態とする。
# warning の意味を理解したうえで必要な場合だけ、対象 code を局所的に suppression する。
# shellcheck disable=SC2034
learning_metadata='unit08-example'

printf '%s\n' 'targeted suppression example'
