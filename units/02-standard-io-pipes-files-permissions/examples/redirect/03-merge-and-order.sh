#!/usr/bin/env bash

# 2>&1 は「stderr(fd 2) を、その時点の stdout(fd 1) と同じ接続先へ向ける」という意味。
# redirect は左から順番に評価されるため、同じ記号でも並べる順序によって結果が変わる。

work_dir=$(mktemp -d)
case_a="$work_dir/case-a.txt"
case_b="$work_dir/case-b.txt"

# 先に stdout を file へ向け、その後 stderr をその stdout と同じ file へ向ける。
# そのため stdout / stderr の両方が case-a.txt に入る。
bash -c '
  printf "%s\n" "stdout from case A"
  printf "%s\n" "stderr from case A" >&2
' >"$case_a" 2>&1

# 先に stderr を「その時点の stdout」と同じ先へ向け、その後 stdout だけを file へ変更する。
# stderr は元の stdout である Terminal 側へ残り、case-b.txt には stdout だけが入る。
bash -c '
  printf "%s\n" "stdout from case B"
  printf "%s\n" "stderr from case B" >&2
' 2>&1 >"$case_b"

# 2 種類の redirect 順序で file に残った内容を比較する。
printf '%s\n' 'case A file:'
cat "$case_a"

printf '%s\n' 'case B file:'
cat "$case_b"

rm -f -- "$case_a" "$case_b"
rmdir "$work_dir"
