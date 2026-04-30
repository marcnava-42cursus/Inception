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
MYSQL_ROOT_PASSWORD="$(read_secret MYSQL_ROOT_PASSWORD /run/secrets/db_root_password)"
export MYSQL_PASSWORD MYSQL_ROOT_PASSWORD

mkdir -p /run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

FIRST_BOOT=0
if [ ! -d /var/lib/mysql/mysql ]; then
	FIRST_BOOT=1
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

mariadbd --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --skip-networking &
TEMP_PID=$!

DB_READY=0
for _ in $(seq 1 60); do
	if mariadb-admin --socket=/run/mysqld/mysqld.sock ping --silent >/dev/null 2>&1; then
		DB_READY=1
		break
	fi
	sleep 1
done

if [ "${DB_READY}" != "1" ]; then
	echo "Error: MariaDB bootstrap server did not start."
	kill "${TEMP_PID}" || true
	exit 1
fi

if [ "${FIRST_BOOT}" = "1" ]; then
	mariadb --socket=/run/mysqld/mysqld.sock -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
	mariadb --socket=/run/mysqld/mysqld.sock -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "ALTER USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "FLUSH PRIVILEGES;"
else
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "ALTER USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';"
	mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" -e "FLUSH PRIVILEGES;"
fi

mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
wait "${TEMP_PID}"

exec mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
