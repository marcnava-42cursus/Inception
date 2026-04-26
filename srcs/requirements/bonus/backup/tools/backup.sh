#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"

DB_HOST="${BACKUP_DB_HOST:-mariadb}"
DB_PORT="${BACKUP_DB_PORT:-3306}"
DB_NAME="${BACKUP_DB_NAME:-${MYSQL_DATABASE}}"
DB_USER="${BACKUP_DB_USER:-${MYSQL_USER}}"
DB_PASSWORD="${BACKUP_DB_PASSWORD:-${MYSQL_PASSWORD}}"
KEEP="${BACKUP_KEEP:-72}"

mkdir -p /backups

DB_READY=0
for _ in $(seq 1 60); do
	if mariadb-admin -h "${DB_HOST}" -P "${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" ping --silent >/dev/null 2>&1; then
		DB_READY=1
		break
	fi
	sleep 2
done

if [ "${DB_READY}" != "1" ]; then
	echo "Error: MariaDB not reachable for backup."
	exit 1
fi

TS="$(date +%Y%m%d_%H%M%S)"
DB_OUT="/backups/mariadb_${TS}.sql.gz"
WP_OUT="/backups/wordpress_${TS}.tar.gz"

mariadb-dump -h "${DB_HOST}" -P "${DB_PORT}" -u"${DB_USER}" -p"${DB_PASSWORD}" "${DB_NAME}" | gzip > "${DB_OUT}"
tar -czf "${WP_OUT}" -C /var/www/html .

if [ "${KEEP}" -gt 0 ] 2>/dev/null; then
	ls -1t /backups/mariadb_*.sql.gz 2>/dev/null | awk "NR>${KEEP}" | xargs -r rm -f
	ls -1t /backups/wordpress_*.tar.gz 2>/dev/null | awk "NR>${KEEP}" | xargs -r rm -f
fi

echo "[backup] ${TS} OK: ${DB_OUT} + ${WP_OUT}"
