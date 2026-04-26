#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"

cat >/etc/crontabs/root <<'EOF'
*/5 * * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
EOF

chmod 600 /etc/crontabs/root

/usr/local/bin/backup.sh || true

exec crond -f -l 8 -L /dev/stdout
