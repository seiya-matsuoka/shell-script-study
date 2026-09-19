#!/usr/bin/env bash

# $? が保持するのは「直前に実行した command」の exit status である。
# 確認したい command と $? の間に別の command を挟むと、値はその command の結果に更新される。

false
status_after_false=$?

printf 'status after false=%s\n' "$status_after_false"

# 直前の printf は正常終了するため、この時点の $? は false の結果ではない。
status_after_printf=$?
printf 'status after printf=%s\n' "$status_after_printf"
