#!/bin/sh
set -eu

: "${WORDPRESS_DB_NAME:?Missing WORDPRESS_DB_NAME}"
: "${WORDPRESS_DB_USER:?Missing WORDPRESS_DB_USER}"
: "${WORDPRESS_DB_PASSWORD:?Missing WORDPRESS_DB_PASSWORD}"
: "${WORDPRESS_DB_HOST:?Missing WORDPRESS_DB_HOST}"
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"

: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_USER:?Missing WP_ADMIN_USER}"
: "${WP_ADMIN_PASSWORD:?Missing WP_ADMIN_PASSWORD}"
: "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
: "${WP_USER:?Missing WP_USER}"
: "${WP_USER_PASSWORD:?Missing WP_USER_PASSWORD}"
: "${WP_USER_EMAIL:?Missing WP_USER_EMAIL}"

ADMIN_USER_LOWER="$(printf '%s' "${WP_ADMIN_USER}" | tr '[:upper:]' '[:lower:]')"
case "${ADMIN_USER_LOWER}" in
	*admin*)
		echo "Error: WP_ADMIN_USER cannot contain admin/administrator."
		exit 1
		;;
esac

DB_HOSTNAME="${WORDPRESS_DB_HOST%:*}"
DB_PORT="${WORDPRESS_DB_HOST#*:}"
if [ "${DB_HOSTNAME}" = "${DB_PORT}" ]; then
	DB_PORT=3306
fi

DB_READY=0
for _ in $(seq 1 60); do
	if mariadb -h "${DB_HOSTNAME}" -P "${DB_PORT}" -u"${WORDPRESS_DB_USER}" -p"${WORDPRESS_DB_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
		DB_READY=1
		break
	fi
	sleep 2
done

if [ "${DB_READY}" != "1" ]; then
	echo "Error: MariaDB not reachable after timeout."
	exit 1
fi

chown -R nobody:nobody /var/www/html

if [ ! -f /var/www/html/wp-config.php ]; then
	su-exec nobody wp config create \
		--path=/var/www/html \
		--dbname="${WORDPRESS_DB_NAME}" \
		--dbuser="${WORDPRESS_DB_USER}" \
		--dbpass="${WORDPRESS_DB_PASSWORD}" \
		--dbhost="${WORDPRESS_DB_HOST}" \
		--skip-check \
		--skip-salts
fi

if ! su-exec nobody wp core is-installed --path=/var/www/html >/dev/null 2>&1; then
	su-exec nobody wp core install \
		--path=/var/www/html \
		--url="https://${DOMAIN_NAME}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_ADMIN_USER}" \
		--admin_password="${WP_ADMIN_PASSWORD}" \
		--admin_email="${WP_ADMIN_EMAIL}"
fi

if ! su-exec nobody wp user get "${WP_USER}" --path=/var/www/html >/dev/null 2>&1; then
	su-exec nobody wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
		--path=/var/www/html \
		--user_pass="${WP_USER_PASSWORD}" \
		--role=author
fi

exec php-fpm83 -F
