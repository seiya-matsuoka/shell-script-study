#!/usr/bin/env bash

work_dir=$(mktemp -d)

cleanup() {
  rm -rf -- "$work_dir"
}

trap cleanup EXIT

mkdir -p -- "$work_dir/input" "$work_dir/done" "$work_dir/failed"

printf '%s\n' 'alpha' >"$work_dir/input/01-ok.txt"
printf '%s\n' 'broken' >"$work_dir/input/02-fail.txt"
printf '%s\n' 'gamma' >"$work_dir/input/03-ok.txt"

failed=0

for input_file in "$work_dir"/input/*.txt; do
  name=$(basename -- "$input_file")

  # 一件の failure で batch 全体を即終了させず、
  # 成功 / failure を記録して最後に job 全体の結果を返す例。
  if [[ $name == *fail* ]]; then
    printf 'failed=%s\n' "$name" >&2
    mv -- "$input_file" "$work_dir/failed/"
    failed=$((failed + 1))
    continue
  fi

  printf 'completed=%s\n' "$name"
  mv -- "$input_file" "$work_dir/done/"
done

printf 'done_count=%s\n' "$(find "$work_dir/done" -type f | wc -l)"
printf 'failed_count=%s\n' "$failed"

if ((failed > 0)); then
  exit 1
fi
