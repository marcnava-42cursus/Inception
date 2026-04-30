#!/bin/sh
set -eu

: "${FTP_USER:?Missing FTP_USER}"
: "${FTP_PASV_MIN_PORT:?Missing FTP_PASV_MIN_PORT}"
: "${FTP_PASV_MAX_PORT:?Missing FTP_PASV_MAX_PORT}"

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

FTP_PASSWORD="$(read_secret FTP_PASSWORD /run/secrets/ftp_password)"
export FTP_PASSWORD

if [ "${FTP_PASV_MIN_PORT}" -gt "${FTP_PASV_MAX_PORT}" ]; then
	echo "Error: FTP_PASV_MIN_PORT must be <= FTP_PASV_MAX_PORT."
	exit 1
fi

if ! id "${FTP_USER}" >/dev/null 2>&1; then
	adduser -D -h /var/www/html -s /sbin/nologin "${FTP_USER}"
fi

echo "${FTP_USER}:${FTP_PASSWORD}" | chpasswd
addgroup "${FTP_USER}" nobody 2>/dev/null || true

find /var/www/html -type d -exec chmod 775 {} + 2>/dev/null || true
find /var/www/html -type f -exec chmod 664 {} + 2>/dev/null || true

sed -i "s|__FTP_PASV_MIN_PORT__|${FTP_PASV_MIN_PORT}|g" /etc/vsftpd/vsftpd.conf
sed -i "s|__FTP_PASV_MAX_PORT__|${FTP_PASV_MAX_PORT}|g" /etc/vsftpd/vsftpd.conf

exec vsftpd /etc/vsftpd/vsftpd.conf
