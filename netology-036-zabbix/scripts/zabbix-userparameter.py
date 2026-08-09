#!/usr/bin/env python3

import re
import subprocess
import sys
from datetime import date


FULL_NAME = "Mosiichuk Igor"


def ping(target: str) -> None:
    result = subprocess.run(
        ["ping", "-c", "1", "-W", "2", target],
        capture_output=True,
        text=True,
        check=False,
    )

    if result.returncode != 0:
        print(f"ping failed for {target}", file=sys.stderr)
        raise SystemExit(1)

    match = re.search(r"time[=<]([\d.]+)\s*ms", result.stdout)

    if not match:
        print("ping latency not found", file=sys.stderr)
        raise SystemExit(1)

    print(match.group(1))


def main() -> None:
    if len(sys.argv) < 2:
        print("missing argument", file=sys.stderr)
        raise SystemExit(1)

    command = sys.argv[1]

    if command == "1":
        print(FULL_NAME)

    elif command == "2":
        print(date.today().isoformat())

    elif command == "-ping":
        if len(sys.argv) < 3 or not sys.argv[2]:
            print("missing ping target", file=sys.stderr)
            raise SystemExit(1)

        ping(sys.argv[2])

    elif command == "-simple_print":
        if len(sys.argv) < 3:
            print("missing text", file=sys.stderr)
            raise SystemExit(1)

        print(sys.argv[2])

    else:
        print(f"unknown input: {command}")


if __name__ == "__main__":
    main()
