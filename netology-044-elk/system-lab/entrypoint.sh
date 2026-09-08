#!/usr/bin/env bash
set -euo pipefail

mkdir -p /var/log/journal /run/systemd/journal
chmod 2755 /var/log/journal

# Keep one machine-id with the named journal volume so journal files stay
# in one namespace across container recreation.
persisted_machine_id=/var/log/journal/.machine-id
if [[ -s "$persisted_machine_id" ]]; then
  cat "$persisted_machine_id" >/etc/machine-id
else
  rm -f /etc/machine-id
  systemd-machine-id-setup >/dev/null
  cp /etc/machine-id "$persisted_machine_id"
fi

if command -v systemd-journald >/dev/null 2>&1; then
  journald_bin="$(command -v systemd-journald)"
elif [[ -x /usr/lib/systemd/systemd-journald ]]; then
  journald_bin=/usr/lib/systemd/systemd-journald
elif [[ -x /lib/systemd/systemd-journald ]]; then
  journald_bin=/lib/systemd/systemd-journald
else
  echo "systemd-journald binary not found" >&2
  exit 1
fi

"$journald_bin" &
journald_pid=$!
app_pid=""

cleanup() {
  trap - EXIT INT TERM

  if [[ -n "$app_pid" ]]; then
    kill "$app_pid" 2>/dev/null || true
    wait "$app_pid" 2>/dev/null || true
  fi

  kill "$journald_pid" 2>/dev/null || true
  wait "$journald_pid" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

for _ in $(seq 1 50); do
  [[ -S /run/systemd/journal/socket ]] && break
  sleep 0.1
done

if [[ ! -S /run/systemd/journal/socket ]]; then
  echo "journald socket did not appear" >&2
  exit 1
fi

# journald initially writes to /run. Without a full systemd boot there is no
# systemd-journal-flush.service, so request the switch to persistent
# /var/log/journal explicitly. That directory is the Docker named volume.
journalctl --flush

python3 /opt/system-lab/app.py &
app_pid=$!
wait "$app_pid"
