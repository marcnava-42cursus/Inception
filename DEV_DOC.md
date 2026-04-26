# DEV_DOC

## Purpose

This document explains how a developer can set up, build, launch, inspect, and maintain the Inception project from scratch.

The project is a Docker Compose stack with mandatory services and bonus services. All Docker-related configuration is located inside `srcs/`, while the `Makefile` is located at the repository root.

## Repository Layout

```text
.
|-- Makefile
|-- README.md
|-- USER_DOC.md
|-- DEV_DOC.md
|-- secrets/
`-- srcs/
    |-- .env
    |-- docker-compose.yml
    `-- requirements/
        |-- mariadb/
        |   |-- Dockerfile
        |   |-- conf/
        |   `-- tools/
        |-- nginx/
        |   |-- Dockerfile
        |   `-- conf/
        |-- wordpress/
        |   |-- Dockerfile
        |   `-- tools/
        `-- bonus/
            |-- adminer/
            |-- backup/
            |-- ftp/
            |-- redis/
            `-- static-web/
```

## Services

Mandatory:

- `mariadb`: database backend.
- `wordpress`: WordPress with PHP-FPM only.
- `nginx`: HTTPS entrypoint on port `443`.

Bonus:

- `redis`: WordPress object cache.
- `ftp`: FTP access to WordPress files.
- `static-web`: static website generated with R.
- `adminer`: database administration UI.
- `backup`: scheduled database and WordPress file backups.

Each service has its own Dockerfile and runs in its own container.

## Prerequisites

Use a Linux VM with:

- Docker Engine.
- Docker Compose plugin.
- `make`.
- `curl`, useful for validation.
- `openssl`, useful for TLS validation.
- Permission to edit `/etc/hosts`.

Before evaluation, the evaluator may run a full Docker cleanup:

```sh
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

This removes all Docker containers, images, volumes, and custom networks from the machine.

## Environment Setup From Scratch

### 1. Clone the Repository

Clone into an empty directory:

```sh
git clone <repository-url> inception
cd inception
```

### 2. Create `srcs/.env`

Create the environment file locally:

```sh
touch srcs/.env
chmod 600 srcs/.env
```

Example content:

```env
DOMAIN_NAME=marcnava.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=marcnava
MYSQL_PASSWORD=<db_user_password>
MYSQL_ROOT_PASSWORD=<db_root_password>

WORDPRESS_DB_NAME=wordpress
WORDPRESS_DB_USER=marcnava
WORDPRESS_DB_PASSWORD=<db_user_password>
WORDPRESS_DB_HOST=mariadb:3306

WP_TITLE=Inception
WP_ADMIN_USER=marcnava
WP_ADMIN_PASSWORD=<wp_admin_password>
WP_ADMIN_EMAIL=marcnava@student.42madrid.com
WP_USER=editor
WP_USER_PASSWORD=<wp_user_password>
WP_USER_EMAIL=editor@student.42madrid.com

WP_REDIS_HOST=redis
WP_REDIS_PORT=6379

FTP_USER=marcnava
FTP_PASSWORD=<ftp_password>
FTP_PASV_MIN_PORT=40000
FTP_PASV_MAX_PORT=40010

BACKUP_DB_HOST=mariadb
BACKUP_DB_PORT=3306
BACKUP_DB_NAME=wordpress
BACKUP_DB_USER=marcnava
BACKUP_DB_PASSWORD=<db_user_password>
BACKUP_KEEP=72

DATA_PATH=/home/marcnava/data
```

Important:

- Do not commit real credentials.
- `WP_ADMIN_USER` must not contain `admin` or `administrator`, in any casing.
- For strict subject validation, `DATA_PATH` must point to `/home/<login>/data`.

### 3. Configure the Local Domain

```sh
sudo sh -c 'echo "127.0.0.1 marcnava.42.fr" >> /etc/hosts'
```

If the VM uses another local IP, map `marcnava.42.fr` to that IP.

### 4. Prepare Data Directories

The Makefile creates the required directories automatically during `make up`.

Manual equivalent:

```sh
mkdir -p /home/marcnava/data/mariadb
mkdir -p /home/marcnava/data/wordpress
mkdir -p /home/marcnava/data/backups
```

## Build and Launch

Build and start everything:

```sh
make up
```

Equivalent Compose command:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env up -d --build
```

Build only:

```sh
make build
```

Stop:

```sh
make down
```

Rebuild from a clean state:

```sh
make re
```

## Makefile Targets

```sh
make up       # Create data directories, build images, start containers
make build    # Build all images through Docker Compose
make down     # Stop and remove Compose containers
make restart  # Run down, then up
make logs     # Follow logs from all services
make ps       # Show Compose container status
make clean    # Stop containers
make iclean   # Stop containers and remove project images
make vclean   # Remove containers, orphans, and named volumes
make fclean   # Remove containers, volumes, orphans, and persistent data directories
make re       # Full cleanup and fresh start
```

## Docker Compose Model

The stack is defined in:

```text
srcs/docker-compose.yml
```

It defines:

- Build contexts for each service.
- Image names matching service names.
- Container names.
- `env_file: .env` for services that need runtime variables.
- Named volumes for persistent data.
- A dedicated bridge network named `inception`.
- Restart policy `unless-stopped`.

The project does not use:

- `network: host`
- `links:`
- `--link`

## Image Build Sources

Mandatory image build contexts:

```text
srcs/requirements/mariadb
srcs/requirements/wordpress
srcs/requirements/nginx
```

Bonus image build contexts:

```text
srcs/requirements/bonus/redis
srcs/requirements/bonus/ftp
srcs/requirements/bonus/static-web
srcs/requirements/bonus/adminer
srcs/requirements/bonus/backup
```

All services are built from Alpine and have custom Dockerfiles.

## Runtime Processes

The main process for each container is:

- `mariadb`: startup script, then `mariadbd`.
- `wordpress`: startup script, then `php-fpm83 -F`.
- `nginx`: `nginx -g 'daemon off;'`.
- `redis`: `redis-server /etc/redis.conf`.
- `ftp`: startup script, then `vsftpd`.
- `static-web`: `nginx -g 'daemon off;'`.
- `adminer`: PHP built-in server serving Adminer.
- `backup`: startup script, then `crond -f`.

The service entrypoints are intended to keep the real daemon in the foreground. They do not rely on `tail -f`, `sleep infinity`, or an infinite shell loop.

## Management Commands

Show containers:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env ps
```

Show logs:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env logs
```

Follow logs for one service:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env logs -f wordpress
```

Open a shell in a container:

```sh
docker exec -it wordpress sh
docker exec -it mariadb sh
docker exec -it nginx sh
```

List images:

```sh
docker image ls | grep inception
```

List volumes:

```sh
docker volume ls
```

Inspect a volume:

```sh
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

List networks:

```sh
docker network ls
docker network inspect inception_inception
```

## Data Persistence

MariaDB data:

```text
Docker volume: inception_mariadb_data
Container path: /var/lib/mysql
Host path: /home/marcnava/data/mariadb
```

WordPress data:

```text
Docker volume: inception_wordpress_data
Container path: /var/www/html
Host path: /home/marcnava/data/wordpress
```

Backup data:

```text
Docker volume: inception_backup_data
Container path: /backups
Host path: /home/marcnava/data/backups
```

These paths are derived from:

```env
DATA_PATH=/home/marcnava/data
```

The data survives container recreation. It is removed by `make fclean`.

## Validation Commands

Check Compose syntax and expansion:

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env config
```

Check HTTP and HTTPS:

```sh
curl -I http://marcnava.42.fr
curl -k -I https://marcnava.42.fr
```

Check TLS versions:

```sh
openssl s_client -connect marcnava.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect marcnava.42.fr:443 -tls1_3 </dev/null
```

Check WordPress:

```sh
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
docker exec wordpress wp user list --path=/var/www/html --allow-root --fields=user_login,roles
docker exec wordpress wp option get siteurl --path=/var/www/html --allow-root
```

Check MariaDB:

```sh
set -a; . srcs/.env; set +a
docker exec mariadb mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h 127.0.0.1 "$MYSQL_DATABASE" -e "SHOW TABLES;"
docker exec mariadb mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
```

Check Redis:

```sh
docker exec wordpress wp redis status --path=/var/www/html --allow-root
```

Check Adminer:

```sh
curl -k https://marcnava.42.fr/adminer/
```

Check static website:

```sh
curl -k https://marcnava.42.fr/web/
```

Check FTP:

```sh
set -a; . srcs/.env; set +a
curl --ftp-pasv -u "$FTP_USER:$FTP_PASSWORD" ftp://127.0.0.1/
```

Check backups:

```sh
docker exec backup ls -lh /backups
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env logs backup
```

## Troubleshooting

If containers do not start:

```sh
make ps
make logs
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env config
```

If WordPress reports database errors:

- Check that `mariadb` is running.
- Check `MYSQL_*` and `WORDPRESS_DB_*` variables in `srcs/.env`.
- If old persistent data exists with old credentials, run `make fclean`, then `make up`.

If NGINX does not answer on HTTPS:

```sh
docker exec nginx nginx -t
sudo ss -ltnp | grep ':443'
```

If the domain does not resolve:

```sh
grep marcnava.42.fr /etc/hosts
```

If volume paths are wrong:

```sh
docker volume inspect inception_mariadb_data
docker volume inspect inception_wordpress_data
```

Then verify `DATA_PATH` in `srcs/.env`.

## Clean Installation State

To return to a clean project runtime state:

```sh
make fclean
```

To also remove project images:

```sh
make iclean
```

To verify no project runtime resources remain:

```sh
docker ps -a --filter name=mariadb --filter name=wordpress --filter name=nginx --filter name=redis --filter name=adminer --filter name=ftp --filter name=backup
docker volume ls
docker network ls
docker image ls | grep inception
```
