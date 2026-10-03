#!/usr/bin/env python3
"""Unit 10 の Shell / Docker / DB 連携を確認するための学習補助 Application。

HTTP server 自体の学習を目的とせず、health endpoint と items API の最小機能だけを持つ。
DB access は Compose で起動した PostgreSQL Container 内の psql へ委譲し、
Shell Script から Application と DB をつなぐ流れを観察できる構成にする。
"""

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

# repository 上の Unit directory と Compose file を基準にして、
# Shell Script からどの working directory で起動しても同じ DB service を参照する。
UNIT_DIR = Path(__file__).resolve().parents[2]
COMPOSE_FILE = UNIT_DIR / "compose.yaml"

# Application の bind address / port と DB connection information は、
# Shell 側と同じ environment variable から上書きできるようにする。
HOST = os.environ.get("APP_HOST", "127.0.0.1")
PORT = int(os.environ.get("APP_PORT", "18090"))
POSTGRES_USER = os.environ.get("POSTGRES_USER", "unit10")
POSTGRES_DB = os.environ.get("POSTGRES_DB", "unit10db")


def run_query(sql: str) -> subprocess.CompletedProcess[str]:
    """Compose の PostgreSQL Container 内で psql を実行し、SQL の結果を返す。"""

    # Application 内に DB driver を追加せず、Unit 10 で学習対象としている
    # docker compose exec / psql の command chain をそのまま利用する。
    return subprocess.run(
        [
            "docker",
            "compose",
            "-f",
            str(COMPOSE_FILE),
            "exec",
            "-T",
            "db",
            "psql",
            "-v",
            "ON_ERROR_STOP=1",
            "-U",
            POSTGRES_USER,
            "-d",
            POSTGRES_DB,
            "-At",
            "-F",
            "\t",
            "-c",
            sql,
        ],
        cwd=UNIT_DIR,
        capture_output=True,
        text=True,
        check=False,
    )


class Handler(BaseHTTPRequestHandler):
    # Shell 側の学習出力へ不要な access log を混ぜない。
    def log_message(self, format, *args):
        return

    # 各 endpoint で同じ HTTP header / JSON encoding を繰り返さないための共通 response 処理。
    def send_json(self, status: int, payload: dict) -> None:
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        # /health は HTTP server が起動していることだけでなく、
        # PostgreSQL へ実際に query できることまで含めて Application の状態を判定する。
        if self.path == "/health":
            result = run_query("SELECT 1;")
            if result.returncode == 0 and result.stdout.strip() == "1":
                self.send_json(200, {"status": "UP"})
            else:
                self.send_json(503, {"status": "DOWN"})
            return

        # /api/items は items table を取得し、psql の tab 区切り output を
        # Shell 側で扱いやすい JSON response へ変換して返す。
        if self.path == "/api/items":
            result = run_query("SELECT id, name, status FROM items ORDER BY id;")
            if result.returncode != 0:
                self.send_json(500, {"error": "database_query_failed"})
                return

            items = []
            for line in result.stdout.splitlines():
                if not line:
                    continue
                item_id, name, status = line.split("\t")
                items.append({"id": int(item_id), "name": name, "status": status})

            self.send_json(200, {"items": items})
            return

        # 学習対象外の path には明示的に 404 を返し、endpoint の範囲を限定する。
        self.send_json(404, {"error": "not_found"})


if __name__ == "__main__":
    # local learning environment だけで利用する最小 HTTP server を起動する。
    # ThreadingHTTPServer の詳細は今回の学習対象ではなく、Shell から呼べる Application を用意するために使う。
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Unit 10 support app: http://{HOST}:{PORT}", flush=True)

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        # Ctrl+C などで終了した場合も server socket を閉じる。
        server.server_close()
