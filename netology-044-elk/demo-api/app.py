#!/usr/bin/env python3
import json
import os
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = int(os.environ.get("PORT", "8080"))
LOG_PATH = Path(os.environ.get("LOG_PATH", "/var/log/demo-api/application.jsonl"))
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
_lock = threading.Lock()


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def write_event(event: dict) -> None:
    with _lock:
        with LOG_PATH.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n")
            fh.flush()


class Handler(BaseHTTPRequestHandler):
    server_version = "netology44-demo-api/1.0"

    def log_message(self, fmt, *args):
        return

    def _send(self, status: int, body: str, level: str = "info") -> None:
        started = time.monotonic_ns()
        request_id = self.headers.get("X-Request-ID") or uuid.uuid4().hex

        if self.path == "/slow":
            time.sleep(3)

        payload = body.encode("utf-8")
        try:
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.send_header("X-Request-ID", request_id)
            self.end_headers()
            self.wfile.write(payload)
        except (BrokenPipeError, ConnectionResetError):
            level = "warning"

        duration_ns = time.monotonic_ns() - started
        write_event({
            "@timestamp": now_iso(),
            "log": {"level": level},
            "service": {"name": "demo-api"},
            "trace": {"id": request_id},
            "http": {
                "request": {"method": self.command},
                "response": {"status_code": status},
            },
            "url": {"path": self.path},
            "event": {"duration": duration_ns},
            "message": f"{self.command} {self.path} -> {status}",
        })

    def do_GET(self):
        if self.path == "/health":
            payload = b'{"status":"ok"}'
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
        elif self.path == "/ok":
            self._send(200, '{"result":"ok"}')
        elif self.path == "/error":
            self._send(500, '{"error":"synthetic application error"}', "error")
        elif self.path == "/slow":
            self._send(200, '{"result":"slow"}', "warning")
        else:
            self._send(404, '{"error":"not found"}', "warning")


if __name__ == "__main__":
    write_event({
        "@timestamp": now_iso(),
        "log": {"level": "info"},
        "service": {"name": "demo-api"},
        "event": {"duration": 0},
        "message": "demo-api started",
    })
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
