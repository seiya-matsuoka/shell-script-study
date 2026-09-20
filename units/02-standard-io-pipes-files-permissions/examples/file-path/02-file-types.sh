#!/usr/bin/env bash

# regular file / directory / symbolic link / hidden file / executable file を作成し、
# test command と ls で種類や状態を確認する。

work_dir=$(mktemp -d)

regular_file="$work_dir/regular.txt"
directory="$work_dir/directory"
symbolic_link="$work_dir/regular-link"
hidden_file="$work_dir/.hidden"
executable_file="$work_dir/run.sh"

printf '%s\n' 'regular file' >"$regular_file"
mkdir "$directory"
ln -s "$regular_file" "$symbolic_link"
printf '%s\n' 'hidden file' >"$hidden_file"

cat >"$executable_file" <<'SCRIPT'
#!/usr/bin/env bash
printf '%s\n' 'executable file'
SCRIPT
chmod +x "$executable_file"

[[ -f "$regular_file" ]] && printf 'regular file: %s\n' "$regular_file"
[[ -d "$directory" ]] && printf 'directory: %s\n' "$directory"
[[ -L "$symbolic_link" ]] && printf 'symbolic link: %s\n' "$symbolic_link"
[[ -f "$hidden_file" ]] && printf 'hidden file: %s\n' "$hidden_file"
[[ -x "$executable_file" ]] && printf 'executable file: %s\n' "$executable_file"

# -a を付けると `.` から始まる hidden file も表示される。
ls -la "$work_dir"

rm -f -- "$symbolic_link" "$regular_file" "$hidden_file" "$executable_file"
rmdir "$directory"
rmdir "$work_dir"
