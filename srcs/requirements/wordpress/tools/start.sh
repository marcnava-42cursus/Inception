#!/bin/sh
set -eu

: "${WORDPRESS_DB_NAME:?Missing WORDPRESS_DB_NAME}"
: "${WORDPRESS_DB_USER:?Missing WORDPRESS_DB_USER}"
: "${WORDPRESS_DB_HOST:?Missing WORDPRESS_DB_HOST}"
: "${DOMAIN_NAME:?Missing DOMAIN_NAME}"

: "${WP_TITLE:?Missing WP_TITLE}"
: "${WP_ADMIN_USER:?Missing WP_ADMIN_USER}"
: "${WP_ADMIN_EMAIL:?Missing WP_ADMIN_EMAIL}"
: "${WP_USER:?Missing WP_USER}"
: "${WP_USER_EMAIL:?Missing WP_USER_EMAIL}"
: "${WP_REDIS_HOST:?Missing WP_REDIS_HOST}"
: "${WP_REDIS_PORT:?Missing WP_REDIS_PORT}"

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

WORDPRESS_DB_PASSWORD="$(read_secret WORDPRESS_DB_PASSWORD /run/secrets/db_password)"
WP_ADMIN_PASSWORD="$(read_secret WP_ADMIN_PASSWORD /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(read_secret WP_USER_PASSWORD /run/secrets/wp_user_password)"
export WORDPRESS_DB_PASSWORD WP_ADMIN_PASSWORD WP_USER_PASSWORD

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

CTYPE_POLYFILL_MARKER="INCEPTION_CTYPE_POLYFILL"
if ! grep -q "${CTYPE_POLYFILL_MARKER}" /var/www/html/wp-config.php; then
	TMP_WP_CONFIG="$(mktemp)"
	awk -v marker="${CTYPE_POLYFILL_MARKER}" '
		NR == 1 {
			print
			print ""
			print "// " marker
			print "if (!function_exists('\''ctype_digit'\'')) {"
			print "	function ctype_digit($text) {"
			print "		return is_string($text) && $text !== '\'''\'' && preg_match('\''/^[0-9]+$/'\'', $text) === 1;"
			print "	}"
			print "}"
			next
		}
		{ print }
	' /var/www/html/wp-config.php > "${TMP_WP_CONFIG}"
	chown nobody:nobody "${TMP_WP_CONFIG}"
	mv "${TMP_WP_CONFIG}" /var/www/html/wp-config.php
fi

if ! su-exec nobody wp plugin is-installed redis-cache --path=/var/www/html >/dev/null 2>&1; then
	su-exec nobody wp plugin install redis-cache --activate --path=/var/www/html
elif ! su-exec nobody wp plugin is-active redis-cache --path=/var/www/html >/dev/null 2>&1; then
	su-exec nobody wp plugin activate redis-cache --path=/var/www/html
fi

su-exec nobody wp config set WP_CACHE true --type=constant --raw --path=/var/www/html
su-exec nobody wp config set WP_REDIS_HOST "${WP_REDIS_HOST}" --type=constant --path=/var/www/html
su-exec nobody wp config set WP_REDIS_PORT "${WP_REDIS_PORT}" --type=constant --raw --path=/var/www/html

if [ ! -f /var/www/html/wp-content/object-cache.php ]; then
	su-exec nobody wp redis enable --path=/var/www/html
fi

exec php-fpm83 -F
