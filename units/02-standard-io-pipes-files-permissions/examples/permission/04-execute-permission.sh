#!/usr/bin/env bash

# `./script.sh` と `bash script.sh` で、Script file 自体の execute permission の扱いが異なることを確認する。

work_dir=$(mktemp -d)
sample_script="$work_dir/sample.sh"
error_file="$work_dir/direct-execution-error.txt"

cat >"$sample_script" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' 'sample script executed'
SCRIPT

# まず execute permission を持たない通常の readable file にする。
chmod 644 "$sample_script"

# `./script.sh` 相当の直接実行では、Script file 自体の execute permission と shebang が関係する。
# execute permission がないため失敗し、その stderr と exit status を保存する。
"$sample_script" 2>"$error_file"
direct_status=$?

printf 'direct execution status=%s\n' "$direct_status"
cat "$error_file"

# `bash script.sh` は executable である Bash が Script file を読み込むため、
# Script file 自体に execute permission がなくても、読み取り可能なら実行できる。
bash "$sample_script"

# execute permission を追加すると、Script file を直接実行できる。
chmod +x "$sample_script"

"$sample_script"

rm -f -- "$error_file" "$sample_script"
rmdir "$work_dir"
