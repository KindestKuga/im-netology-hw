#!/usr/bin/env bash
set -euo pipefail
umask 077

ENV_FILE=/opt/netology-labs/docker055/.local/backup.env
BACKUP_DIR=/opt/backup
IMAGE=schnitzler/mysqldump@sha256:a84aff36ecb491c96e24a7dfa0cfb33be7ba6342f3849a01ca99615f1ef712a7

test -s "$ENV_FILE"
test -d "$BACKUP_DIR"
FILE="$BACKUP_DIR/virtd_$(date +%Y%m%d_%H%M%S_%N).sql"
TMP="$FILE.partial"
trap 'rm -f -- "$TMP"' EXIT

# MySQL 8.4 требует SHA-2 плагин; вывод apk не должен попасть в дамп.
docker run --rm \
  --network netology-053-docker-practice_backend \
  --env-file "$ENV_FILE" \
  --entrypoint /bin/sh \
  "$IMAGE" -c '
    set -eu
    apk add --no-cache mariadb-connector-c >&2
    export MYSQL_PWD="$MYSQL_PASSWORD"
    exec mysqldump --host="$MYSQL_HOST" --user="$MYSQL_USER" \
      --ssl --single-transaction --quick --skip-lock-tables \
      --no-tablespaces "$MYSQL_DATABASE"
  ' > "$TMP"

test -s "$TMP"
mv -- "$TMP" "$FILE"
printf 'Backup created: %s\n' "$FILE"
