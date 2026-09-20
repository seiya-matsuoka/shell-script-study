#!/usr/bin/env bash

# `./script.sh` は Script file 自体を executable file として実行するため、
# execute permission と shebang が関係する。
#
# `bash script.sh` は executable である bash に Script file を読み込ませるため、
# Script file 自体に execute permission がなくても、読み取り可能なら実行できる。

work_dir=$(mktemp -d)
sample_script="$work_dir/sample.sh"
error_file="$work_dir/direct-execution-error.txt"

cat >"$sample_script" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' 'sample script executed'
SCRIPT

chmod 644 "$sample_script"

# execute permission がない状態で直接実行し、失敗した exit status を保存する。
"$sample_script" 2>"$error_file"
direct_status=$?

printf 'direct execution status=%s\n' "$direct_status"
cat "$error_file"

# bash が file を読み込む場合は execute permission がなくても実行できる。
bash "$sample_script"

chmod +x "$sample_script"

# execute permission を追加すると、直接実行できる。
"$sample_script"

rm -f -- "$error_file" "$sample_script"
rmdir "$work_dir"
