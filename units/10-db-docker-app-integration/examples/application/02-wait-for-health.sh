#!/usr/bin/env bash

# Application process の起動直後に次へ進まず、health endpoint が利用可能になるまで有限回 polling する。
# Unit 06 で扱った health check / retry を、DB と連携する Application の起動待ちへ適用する。

app_url=${UNIT10_APP_URL:-http://127.0.0.1:18090}
max_attempts=${UNIT10_HEALTH_ATTEMPTS:-10}

for ((attempt = 1; attempt <= max_attempts; attempt += 1)); do
  # process が存在するだけでなく、Application が DB を利用できる状態になるまで待つ。
  # curl 自体の成功後に JSON の status も確認し、HTTP success と Application state を分けて判定する。
  if response=$(curl -fsS --max-time 2 "$app_url/health"); then
    status=$(jq -r '.status' <<<"$response")

    if [[ $status == UP ]]; then
      printf 'application is healthy: attempt=%s\n' "$attempt"
      exit 0
    fi
  fi

  printf 'waiting for application: attempt=%s\n' "$attempt" >&2
  sleep 1
done

# 最大回数まで ready にならなければ、後続の API call へ進まず failure として終了する。
printf '%s\n' 'application did not become healthy' >&2
exit 1
