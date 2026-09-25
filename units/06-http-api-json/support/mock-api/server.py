#!/usr/bin/env python3
"""Unit 06 learning-only mock API. Binds only to 127.0.0.1."""

import json
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

# Unit 06 の Shell samples から共通で利用する local mock API の設定。
# authentication / retry / readiness の挙動も、この server 内の dummy state で再現する。
HOST = "127.0.0.1"
PORT = 18080
DEMO_TOKEN = "unit06-demo-token"
unstable_count = 0
ready_count = 0


class Handler(BaseHTTPRequestHandler):
    # 学習中は Shell 側の出力を確認しやすくするため、通常の access log は抑制する。
    def log_message(self, format, *args):
        return

    # 各 endpoint から JSON response を返すための共通処理。
    def send_json(self, status, data):
        body = json.dumps(data).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        global unstable_count, ready_count
        path = urlparse(self.path).path

        # GET / header / JSON array の基本サンプルで利用する endpoint。
        if path == "/api/user":
            return self.send_json(200, {"id": 1, "name": "alice", "active": True})
        if path == "/api/header":
            return self.send_json(200, {"x_demo": self.headers.get("X-Demo", "")})
        if path == "/api/items":
            return self.send_json(
                200,
                {
                    "items": [
                        {"id": 1, "name": "alpha", "active": True},
                        {"id": 2, "name": "beta", "active": False},
                        {"id": 3, "name": "gamma", "active": True},
                    ]
                },
            )

        # health check / readiness / timeout / retry を再現する endpoint。
        if path == "/api/health":
            return self.send_json(200, {"status": "UP", "version": "1.0.0"})
        if path == "/api/ready":
            ready_count += 1
            status = "READY" if ready_count >= 3 else "STARTING"
            return self.send_json(200, {"status": status, "attempt": ready_count})
        if path == "/api/slow":
            time.sleep(2)
            return self.send_json(200, {"status": "completed"})
        if path == "/api/unstable":
            unstable_count += 1
            if unstable_count < 3:
                return self.send_json(
                    503, {"status": "temporary_error", "attempt": unstable_count}
                )
            return self.send_json(200, {"status": "ok", "attempt": unstable_count})

        # authentication と HTTP error のサンプルで利用する endpoint。
        if path == "/api/protected":
            auth = self.headers.get("Authorization", "")
            if auth != f"Bearer {DEMO_TOKEN}":
                return self.send_json(401, {"error": "unauthorized"})
            return self.send_json(200, {"message": "authenticated"})
        if path == "/api/status/404":
            return self.send_json(404, {"error": "not_found"})

        return self.send_json(404, {"error": "unknown_endpoint"})

    # POST sample では JSON request body を受け取り、受信内容を JSON response として返す。
    def do_POST(self):
        if urlparse(self.path).path != "/api/messages":
            return self.send_json(404, {"error": "unknown_endpoint"})
        if self.headers.get("Content-Type") != "application/json":
            return self.send_json(
                415, {"error": "content_type_must_be_application_json"}
            )

        try:
            length = int(self.headers.get("Content-Length", "0"))
            data = json.loads(self.rfile.read(length).decode())
        except json.JSONDecodeError:
            return self.send_json(400, {"error": "invalid_json"})

        return self.send_json(201, {"received": data})


# 127.0.0.1 のみで mock API server を起動し、Ctrl+C で終了できるようにする。
if __name__ == "__main__":
    server = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Unit 06 mock API: http://{HOST}:{PORT}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()
