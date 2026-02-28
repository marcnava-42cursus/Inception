#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?Missing MYSQL_DATABASE}"
: "${MYSQL_USER:?Missing MYSQL_USER}"
: "${MYSQL_PASSWORD:?Missing MYSQL_PASSWORD}"
: "${MYSQL_ROOT_PASSWORD:?Missing MYSQL_ROOT_PASSWORD}"

mkdir -p /run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

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

	mariadb --socket=/run/mysqld/mysqld.sock -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"
	mariadb --socket=/run/mysqld/mysqld.sock -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
	mariadb --socket=/run/mysqld/mysqld.sock -e "FLUSH PRIVILEGES;"

	mariadb-admin --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
	wait "${TEMP_PID}"
fi

exec mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0
