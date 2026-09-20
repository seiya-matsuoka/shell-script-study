#!/usr/bin/env bash

# PATH に一時 directory を追加し、absolute path を指定しなくても
# command 名だけで executable file を探索・実行できることを確認する。

temp_dir=$(mktemp -d)
custom_command="$temp_dir/unit01-hello"

cat >"$custom_command" <<'SCRIPT'
#!/usr/bin/env bash

# この出力は教材用の見出しではなく、独自 command が実際に実行されたことを確認するためのもの。
printf '%s\n' 'unit01-hello executed'
SCRIPT

chmod +x "$custom_command"

# 既存の PATH は残したまま、一時 directory を探索順の先頭へ追加する。
# export することで、この Shell から起動する child process にも更新後の PATH が渡される。
PATH="$temp_dir:$PATH"
export PATH

command -v unit01-hello
unit01-hello

rm -f -- "$custom_command"
rmdir "$temp_dir"
