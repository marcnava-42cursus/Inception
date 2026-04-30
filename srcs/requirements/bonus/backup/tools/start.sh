#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"

read_secret() {
	var_name="$1"
	file_path="$2"
	eval "current_value=\${${var_name}:-}"
	if [ -n "${current_value}" ]; then
		printf '%s' "${current_value}"
	elif [ -r "${file_path}" ]; then
		cat "${file_path}"
	else
		echo "Error: missing ${var_name} or ${file_path}." >&2
		exit 1
	fi
}

MYSQL_PASSWORD="$(read_secret MYSQL_PASSWORD /run/secrets/db_password)"
export MYSQL_PASSWORD

cat >/etc/crontabs/root <<'EOF'
*/5 * * * * /usr/local/bin/backup.sh >> /var/log/backup.log 2>&1
EOF

chmod 600 /etc/crontabs/root

/usr/local/bin/backup.sh || true

exec crond -f -l 8 -L /dev/stdout
