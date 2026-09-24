#!/usr/bin/env bash

work_dir=$(mktemp -d)
valid_script="$work_dir/valid.sh"
invalid_script="$work_dir/invalid.sh"

cat >"$valid_script" <<'SCRIPT'
#!/usr/bin/env bash
if true; then
  printf '%s\n' 'valid'
fi
SCRIPT

cat >"$invalid_script" <<'SCRIPT'
#!/usr/bin/env bash
if true; then
  printf '%s\n' 'missing fi'
SCRIPT

# bash -n は Script を実行せず syntax を確認する。
if bash -n "$valid_script"; then
  printf '%s\n' 'valid.sh syntax OK'
fi

if ! bash -n "$invalid_script" 2>/dev/null; then
  printf '%s\n' 'invalid.sh syntax error detected'
fi

rm -f -- "$valid_script" "$invalid_script"
rmdir "$work_dir"
