#!/usr/bin/env bash

# && は左側 command が成功した場合だけ右側を実行する。
true && printf '%s\n' 'executed after success'

# || は左側 command が失敗した場合だけ右側を実行する。
false || printf '%s\n' 'executed after failure'

# 短い success / failure の分岐には便利だが、
# 複雑な処理では if を使った方が意図や error handling を明確にしやすい。
