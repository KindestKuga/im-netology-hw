#!/usr/bin/env python3
import os
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

PORT = int(os.environ.get("PORT", "9100"))
_lock = threading.Lock()
_state = {
    "events": 0,
    "errors": 0,
    "cpu_load_active": 0,
    "memory_load_active": 0,
}
_memory_holders = []


def journal(priority: str, message: str) -> None:
    with _lock:
        _state["events"] += 1
        if priority in {"err", "crit", "alert", "emerg"}:
            _state["errors"] += 1
    subprocess.run(
        ["systemd-cat", "--identifier=system-lab", f"--priority={priority}"],
        input=message + "\n",
        text=True,
        check=False,
    )


def read_number(path: str, default: float = 0.0) -> float:
    try:
        text = open(path, encoding="utf-8").read().strip()
        if text == "max":
            return -1.0
        return float(text)
    except (OSError, ValueError):
        return default


def cpu_usage_seconds() -> float:
    try:
        with open("/sys/fs/cgroup/cpu.stat", encoding="utf-8") as fh:
            for line in fh:
                key, value = line.split()
                if key == "usage_usec":
                    return float(value) / 1_000_000.0
    except OSError:
        pass
    return 0.0


def metrics() -> str:
    memory_current = read_number("/sys/fs/cgroup/memory.current")
    memory_max = read_number("/sys/fs/cgroup/memory.max", -1)
    with _lock:
        events = _state["events"]
        errors = _state["errors"]
        cpu_active = _state["cpu_load_active"]
        mem_active = _state["memory_load_active"]
    return f"""# HELP systemlab_cpu_usage_seconds_total CPU time consumed inside the synthetic system container.\n# TYPE systemlab_cpu_usage_seconds_total counter\nsystemlab_cpu_usage_seconds_total {cpu_usage_seconds():.6f}\n# HELP systemlab_memory_current_bytes Current cgroup memory usage.\n# TYPE systemlab_memory_current_bytes gauge\nsystemlab_memory_current_bytes {memory_current:.0f}\n# HELP systemlab_memory_max_bytes Cgroup memory limit, -1 means unlimited.\n# TYPE systemlab_memory_max_bytes gauge\nsystemlab_memory_max_bytes {memory_max:.0f}\n# HELP systemlab_journal_events_total Synthetic journal events emitted.\n# TYPE systemlab_journal_events_total counter\nsystemlab_journal_events_total {events}\n# HELP systemlab_journal_errors_total Synthetic error journal events emitted.\n# TYPE systemlab_journal_errors_total counter\nsystemlab_journal_errors_total {errors}\n# HELP systemlab_cpu_load_active Whether a CPU load scenario is active.\n# TYPE systemlab_cpu_load_active gauge\nsystemlab_cpu_load_active {cpu_active}\n# HELP systemlab_memory_load_active Whether a memory load scenario is active.\n# TYPE systemlab_memory_load_active gauge\nsystemlab_memory_load_active {mem_active}\n"""


def burn_cpu(seconds: int, workers: int):
    def worker(deadline):
        value = 1
        while time.monotonic() < deadline:
            value = (value * 1103515245 + 12345) & 0x7FFFFFFF

    def controller():
        with _lock:
            _state["cpu_load_active"] = 1
        journal("warning", f"scenario=cpu-load phase=start seconds={seconds} workers={workers}")
        deadline = time.monotonic() + seconds
        threads = [threading.Thread(target=worker, args=(deadline,), daemon=True) for _ in range(workers)]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()
        journal("info", "scenario=cpu-load phase=finish")
        with _lock:
            _state["cpu_load_active"] = 0

    threading.Thread(target=controller, daemon=True).start()


def hold_memory(seconds: int, megabytes: int):
    def controller():
        with _lock:
            _state["memory_load_active"] = 1
        journal("warning", f"scenario=memory-load phase=start seconds={seconds} megabytes={megabytes}")
        block = bytearray(megabytes * 1024 * 1024)
        for offset in range(0, len(block), 4096):
            block[offset] = 1
        _memory_holders.append(block)
        time.sleep(seconds)
        _memory_holders.remove(block)
        journal("info", "scenario=memory-load phase=finish")
        with _lock:
            _state["memory_load_active"] = 0

    threading.Thread(target=controller, daemon=True).start()


class Handler(BaseHTTPRequestHandler):
    server_version = "netology44-system-lab/1.0"

    def log_message(self, fmt, *args):
        return

    def reply(self, status: int, body: str, content_type="application/json"):
        raw = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def do_GET(self):
        parsed = urlparse(self.path)
        query = parse_qs(parsed.query)

        if parsed.path == "/health":
            self.reply(200, '{"status":"ok"}')
        elif parsed.path == "/metrics":
            self.reply(200, metrics(), "text/plain; version=0.0.4")
        elif parsed.path == "/event/info":
            journal("info", "scenario=manual-event level=info message=synthetic informational event")
            self.reply(200, '{"logged":"info"}')
        elif parsed.path == "/event/warn":
            journal("warning", "scenario=manual-event level=warning message=synthetic warning event")
            self.reply(200, '{"logged":"warning"}')
        elif parsed.path == "/event/error":
            journal("err", "scenario=manual-event level=error message=synthetic system failure")
            self.reply(500, '{"logged":"error"}')
        elif parsed.path == "/load/cpu":
            seconds = max(1, min(int(query.get("seconds", ["10"])[0]), 60))
            workers = max(1, min(int(query.get("workers", ["2"])[0]), 8))
            burn_cpu(seconds, workers)
            self.reply(202, f'{{"cpu_load":"started","seconds":{seconds},"workers":{workers}}}')
        elif parsed.path == "/load/memory":
            seconds = max(1, min(int(query.get("seconds", ["10"])[0]), 60))
            megabytes = max(16, min(int(query.get("mb", ["128"])[0]), 512))
            hold_memory(seconds, megabytes)
            self.reply(202, f'{{"memory_load":"started","seconds":{seconds},"megabytes":{megabytes}}}')
        else:
            self.reply(404, '{"error":"not found"}')


if __name__ == "__main__":
    journal("info", "scenario=startup service=system-lab message=synthetic journald source started")
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
