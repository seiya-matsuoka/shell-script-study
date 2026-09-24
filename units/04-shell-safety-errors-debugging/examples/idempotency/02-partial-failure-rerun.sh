#!/usr/bin/env bash

work_dir=$(mktemp -d)
step1_marker="$work_dir/step1.done"
step2_marker="$work_dir/step2.done"

run_job() {
  local fail_after_step1=$1

  # 完了済み step を marker で確認し、再実行時の重複処理を避ける。
  if [[ ! -f $step1_marker ]]; then
    printf '%s\n' 'running step 1'
    : >"$step1_marker"
  else
    printf '%s\n' 'step 1 already completed'
  fi

  if [[ $fail_after_step1 == true ]]; then
    printf '%s\n' 'simulated failure after step 1' >&2
    return 1
  fi

  if [[ ! -f $step2_marker ]]; then
    printf '%s\n' 'running step 2'
    : >"$step2_marker"
  else
    printf '%s\n' 'step 2 already completed'
  fi
}

if ! run_job true; then
  printf '%s\n' 'first run failed as expected'
fi

# 2 回目は step 1 を再実行せず、未完了の step 2 を実行する。
run_job false

rm -f -- "$step1_marker" "$step2_marker"
rmdir "$work_dir"
