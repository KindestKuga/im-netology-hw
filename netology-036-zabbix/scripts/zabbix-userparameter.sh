#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  1)
    printf '%s\n' 'Mosiichuk Igor'
    ;;
  2)
    date '+%Y-%m-%d'
    ;;
  *)
    printf 'Usage: %s {1|2}\n' "$0" >&2
    exit 1
    ;;
esac
