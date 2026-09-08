#!/usr/bin/env python3
import json
import os
import resource
import threading
import time
import uuid
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

PORT = int(os.environ.get("PORT", "9100"))
LOG_PATH = Path(os.environ.get("LOG_PATH", "/var/log/agent-demo/application.jsonl"))
LOG_PATH.parent.mkdir(parents=True, exist_ok=True)
_lock = threading.Lock()
_counters = {"requests": 0, "errors": 0, "slow": 0}
_started = time.monotonic()


def now_iso():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def write_event(level: str, path: str, status: int, duration_ns: int, request_id: str, message: str):
    event = {
        "@timestamp": now_iso(),
        "log": {"level": level},
        "service": {"name": "agent-demo"},
        "trace": {"id": request_id},
        "http": {"request": {"method": "GET"}, "response": {"status_code": status}},
        "url": {"path": path},
        "event": {"duration": duration_ns},
        "message": message,
    }
    with _lock:
        with LOG_PATH.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(event, ensure_ascii=False, separators=(",", ":")) + "\n")
            fh.flush()


def prometheus_text() -> str:
    rss = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss * 1024
    cpu = time.process_time()
    uptime = time.monotonic() - _started
    with _lock:
        requests = _counters["requests"]
        errors = _counters["errors"]
        slow = _counters["slow"]
    return f"""# HELP agentdemo_requests_total Synthetic requests processed.\n# TYPE agentdemo_requests_total counter\nagentdemo_requests_total {requests}\n# HELP agentdemo_errors_total Synthetic application errors.\n# TYPE agentdemo_errors_total counter\nagentdemo_errors_total {errors}\n# HELP agentdemo_slow_requests_total Synthetic slow requests.\n# TYPE agentdemo_slow_requests_total counter\nagentdemo_slow_requests_total {slow}\n# HELP agentdemo_process_cpu_seconds_total CPU time used by agent-demo.\n# TYPE agentdemo_process_cpu_seconds_total counter\nagentdemo_process_cpu_seconds_total {cpu:.6f}\n# HELP agentdemo_process_memory_bytes Max resident set size.\n# TYPE agentdemo_process_memory_bytes gauge\nagentdemo_process_memory_bytes {rss}\n# HELP agentdemo_uptime_seconds Process uptime.\n# TYPE agentdemo_uptime_seconds gauge\nagentdemo_uptime_seconds {uptime:.3f}\n"""


class Handler(BaseHTTPRequestHandler):
    server_version = "netology44-agent-demo/1.0"

    def log_message(self, fmt, *args):
        return

    def _plain(self, status: int, body: str, content_type: str = "application/json"):
        payload = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_GET(self):
        if self.path == "/metrics":
            self._plain(200, prometheus_text(), "text/plain; version=0.0.4")
            return

        if self.path == "/health":
            self._plain(200, '{"status":"ok"}')
            return

        started = time.monotonic_ns()
        request_id = uuid.uuid4().hex
        with _lock:
            _counters["requests"] += 1

        if self.path == "/work":
            status, level = 200, "info"
            body = '{"result":"work-complete"}'
        elif self.path == "/error":
            with _lock:
                _counters["errors"] += 1
            status, level = 500, "error"
            body = '{"error":"synthetic agent-demo error"}'
        elif self.path == "/slow":
            with _lock:
                _counters["slow"] += 1
            time.sleep(1.5)
            status, level = 200, "warning"
            body = '{"result":"slow-work"}'
        else:
            status, level = 404, "warning"
            body = '{"error":"not found"}'

        duration_ns = time.monotonic_ns() - started
        write_event(level, self.path, status, duration_ns, request_id, f"GET {self.path} -> {status}")
        self._plain(status, body)


if __name__ == "__main__":
    write_event("info", "/startup", 0, 0, uuid.uuid4().hex, "agent-demo started")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
