# USER_DOC

## Purpose

This document explains how an end user or administrator can run and use the Inception stack.

The stack provides a WordPress website served through HTTPS, backed by MariaDB, and extended with several bonus services.

## Provided Services

### Mandatory Services

- `nginx`: public HTTPS entrypoint. It listens on port `443`, serves WordPress, and reverse-proxies bonus web services.
- `wordpress`: WordPress CMS running with PHP-FPM. It contains no NGINX server.
- `mariadb`: database backend used by WordPress.

### Bonus Services

- `redis`: object cache used by WordPress through the Redis Cache plugin.
- `ftp`: FTP server pointing to the WordPress files volume.
- `static-web`: static website generated with R and exposed through NGINX at `/web/`.
- `adminer`: database administration interface exposed through NGINX at `/adminer/`.
- `backup`: periodic backup service for the MariaDB database and WordPress files.

## Required Local Files

The project reads runtime configuration from:

```text
srcs/.env
```

This file must exist before starting the project. It stores the domain name, database settings, WordPress users, FTP settings, Redis settings, backup settings, and data path.

Credentials must not be committed to Git. Passwords are stored locally in Docker secret files under `secrets/`.

## Domain Setup

The subject requires the domain to be `<login>.42.fr`.

For this project:

```text
marcnava.42.fr
```

Add it to `/etc/hosts` on the VM:

```sh
sudo sh -c 'echo "127.0.0.1 marcnava.42.fr" >> /etc/hosts'
```

If the VM has a specific local IP, use that IP instead of `127.0.0.1`.

## Data Location

Persistent data is controlled by `DATA_PATH` in `srcs/.env`.

For strict subject mode:

```env
DATA_PATH=/home/marcnava/data
```

Expected storage layout:

```text
/home/marcnava/data/mariadb
/home/marcnava/data/wordpress
/home/marcnava/data/backups
```

The mandatory persistent data is:

- MariaDB database files in `/home/marcnava/data/mariadb`.
- WordPress website files in `/home/marcnava/data/wordpress`.

The bonus backup service stores backup files in `/home/marcnava/data/backups`.

## Start and Stop the Project

Start and build everything:

```sh
make up
```

Stop containers:

```sh
make down
```

Restart:

```sh
make restart
```

Show running services:

```sh
make ps
```

Follow logs:

```sh
make logs
```

Full cleanup, including containers, volumes, orphan resources, and persisted data directories:

```sh
make fclean
```

Rebuild from scratch:

```sh
make re
```

## Access the Website

Open the website:

```text
https://marcnava.42.fr
```

The browser may show a certificate warning because the NGINX certificate is self-signed. This is expected.

The WordPress installation page should not appear. The site should already be installed by the WordPress startup script.

HTTP should not serve the website:

```text
http://marcnava.42.fr
```

## Access the WordPress Administration Panel

Open:

```text
https://marcnava.42.fr/wp-admin
```

Use the administrator username from `srcs/.env` and the password from the local secret file:

```env
WP_ADMIN_USER=...
```

```text
secrets/wp_admin_password.txt
```

The administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

The regular WordPress user is configured in `srcs/.env` and its password is stored in `secrets/wp_user_password.txt`:

```env
WP_USER=...
```

Use the regular user to test comments, and the administrator user to edit pages from the dashboard.

## Access Adminer

Adminer is available at:

```text
https://marcnava.42.fr/adminer/
```

Use:

- System: `MySQL / MariaDB`
- Server: `mariadb`
- Username: value of `MYSQL_USER`
- Password: content of `secrets/db_password.txt`
- Database: value of `MYSQL_DATABASE`

The non-sensitive values are stored in `srcs/.env`; the password is stored in `secrets/db_password.txt`.

## Access the Static Website

The static bonus website is available at:

```text
https://marcnava.42.fr/web/
```

## Access FTP

FTP uses the username from `srcs/.env` and the password from `secrets/ftp_password.txt`:

```env
FTP_USER=...
FTP_PASV_MIN_PORT=40000
FTP_PASV_MAX_PORT=40010
```

Example check:

```sh
set -a; . srcs/.env; set +a
FTP_PASSWORD="$(cat secrets/ftp_password.txt)"
curl --ftp-pasv -u "$FTP_USER:$FTP_PASSWORD" ftp://127.0.0.1/
```

The FTP root points to the WordPress files volume.

## Locate and Manage Credentials

Main configuration file:

```text
srcs/.env
```

Local secret files:

```text
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
secrets/ftp_password.txt
```

Important variables:

- `MYSQL_USER`: MariaDB user, with password in `secrets/db_password.txt`.
- `secrets/db_root_password.txt`: MariaDB root password.
- `WP_ADMIN_USER`: WordPress administrator user, with password in `secrets/wp_admin_password.txt`.
- `WP_USER`: regular WordPress user, with password in `secrets/wp_user_password.txt`.
- `FTP_USER`: FTP user, with password in `secrets/ftp_password.txt`.

Rules:

- Do not commit real credentials to Git.
- Keep `srcs/.env` and `secrets/*.txt` local.
- Use strong passwords during real use.
- If credentials are changed after data already exists, existing MariaDB and WordPress data may still contain old users/passwords. For a clean reset, run `make fclean`, then `make up`.

## Check That Services Are Running

Compose status:

```sh
make ps
```

Equivalent Docker Compose command:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env ps
```

Expected containers:

```text
mariadb
wordpress
nginx
redis
adminer
static-web
ftp
backup
```

Check logs:

```sh
make logs
```

Check Docker network:

```sh
docker network ls
docker network inspect inception_inception
```

Check volumes:

```sh
docker volume ls
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

The volume inspect output should contain:

```text
/home/marcnava/data/mariadb
/home/marcnava/data/wordpress
```

## Functional Checks

Check HTTPS:

```sh
curl -k -I https://marcnava.42.fr
```

Check that HTTP does not serve the site:

```sh
curl -I http://marcnava.42.fr
```

Check WordPress installation:

```sh
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
docker exec wordpress wp user list --path=/var/www/html --allow-root --fields=user_login,roles
```

Check Redis cache:

```sh
docker exec wordpress wp redis status --path=/var/www/html --allow-root
```

Check MariaDB content:

```sh
set -a; . srcs/.env; set +a
DB_PASSWORD="$(cat secrets/db_password.txt)"
docker exec mariadb mariadb -u"$MYSQL_USER" -p"$DB_PASSWORD" -h 127.0.0.1 "$MYSQL_DATABASE" -e "SHOW TABLES;"
```

Check backups:

```sh
docker exec backup ls -lh /backups
```

## Persistence Check

1. Start the project with `make up`.
2. Open `https://marcnava.42.fr/wp-admin`.
3. Edit a WordPress page.
4. Reboot the VM.
5. Start the project again with `make up`.
6. Open `https://marcnava.42.fr`.

The edited page should still contain the change. This confirms that WordPress files and MariaDB data persisted through Docker named volumes.

## Troubleshooting

If the website does not load:

```sh
make ps
make logs
```

If WordPress cannot connect to the database:

- Verify `mariadb` is running.
- Verify `WORDPRESS_DB_*` values match `MYSQL_*` values in `srcs/.env`.
- Verify `secrets/db_password.txt` contains the database user password.
- Check MariaDB logs with `make logs`.

If the domain does not resolve:

```sh
grep marcnava.42.fr /etc/hosts
```

If credentials were changed after a previous run:

```sh
make fclean
make up
```

If port `443` is already in use:

```sh
sudo ss -ltnp | grep ':443'
```
