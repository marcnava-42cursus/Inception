*This project has been created as part of the 42 curriculum by marcnava*

# Inception

## Description

Inception is a system administration project that builds a small web infrastructure with Docker Compose.
The goal is to run several isolated services, each one in its own container, using custom Dockerfiles, a private Docker network, TLS, and persistent Docker named volumes.

The mandatory infrastructure contains:

- `nginx`: the only public web entrypoint, exposed on port `443` with TLSv1.2/TLSv1.3.
- `wordpress`: WordPress installed and configured with PHP-FPM only.
- `mariadb`: the database server used by WordPress.
- `mariadb_data`: persistent database volume.
- `wordpress_data`: persistent WordPress files volume.
- `inception`: a dedicated Docker bridge network.

This repository also includes bonus services:

- `redis`: WordPress object cache.
- `ftp`: FTP access to the WordPress files volume.
- `static-web`: a simple static website generated with R.
- `adminer`: database administration web interface.
- `backup`: extra service that creates periodic MariaDB and WordPress backups.

## Project Description

### Why Docker is used

Docker makes each service reproducible and isolated. Every service has its own image, dependencies, filesystem, runtime process, and configuration.

Docker Compose is used to describe and run the whole infrastructure from a single file: `srcs/docker-compose.yml`. It defines how images are built, which containers are started, which ports are exposed, which volumes are mounted, and which network connects the containers.

### Docker Image With Compose vs Without Compose

A Docker image is a build artifact: it contains the filesystem and instructions needed to run a container.

Without Docker Compose, each container must be built and started manually with several `docker build` and `docker run` commands. That makes networks, volumes, environment files, and dependencies harder to repeat correctly.

With Docker Compose, all services are declared together. A single `make up` command builds the images, creates the volumes and network, and starts the containers consistently.

### Virtual Machines vs Docker

Virtual machines emulate full machines and run complete guest operating systems. They are strong isolation tools, but they are heavier in CPU, memory, storage, and boot time.

Docker containers share the host kernel and isolate processes, filesystems, networks, and resources. They are lighter and faster to start. For this project, Docker is a better fit because the goal is to orchestrate several services, not several complete operating systems.

### Secrets vs Environment Variables

Environment variables are useful for non-sensitive runtime configuration such as domain name, database host, service ports, and feature settings.

Secrets are better for passwords, private keys, API keys, and other confidential values because they can be stored outside the image and mounted only where needed.

For evaluation, credentials and environment variables must be created locally in `srcs/.env`. Credentials must not be committed to Git outside the evaluator-created `.env` file.

### Docker Network vs Host Network

The project uses a dedicated Docker bridge network named `inception`.

Docker networks provide isolation and internal DNS. Containers can reach each other by service name, for example `wordpress` can connect to `mariadb:3306`.

Host networking would remove this isolation and make containers share the host network stack directly. This project does not use `network: host`, `links`, or `--link`.

### Docker Volumes vs Bind Mounts

Docker named volumes are managed by Docker and can be inspected with Docker commands. This project declares named volumes for persistent data:

- `mariadb_data`
- `wordpress_data`
- `backup_data` for the bonus backup service

The subject requires the mandatory persistent data to be stored under `/home/<login>/data` on the host. This is configured through `DATA_PATH` in `srcs/.env`.

### Directory Structure

All configuration needed by Docker is inside `srcs/`, as required by the subject.

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
        |-- nginx/
        |-- wordpress/
        `-- bonus/
            |-- adminer/
            |-- backup/
            |-- ftp/
            |-- redis/
            `-- static-web/
```

## Services

### nginx

`nginx` is the only public web entrypoint for the mandatory stack. It listens on port `443`, uses a self-signed TLS certificate, serves WordPress through FastCGI, and reverse-proxies the bonus web routes.

Why it is useful:

- Centralizes HTTPS access.
- Keeps WordPress/PHP-FPM private inside the Docker network.
- Enforces the subject rule that the mandatory infrastructure is reachable only through port `443`.

Important files:

- `srcs/requirements/nginx/Dockerfile`
- `srcs/requirements/nginx/conf/default.conf`

### wordpress

`wordpress` runs WordPress with PHP-FPM only. It does not contain NGINX. Its startup script waits for MariaDB, creates `wp-config.php`, installs WordPress, creates the administrator user, creates a regular user, and configures Redis cache for the bonus part.

Why it is useful:

- Provides the CMS website.
- Separates PHP execution from the public web server.
- Stores website files in the persistent `wordpress_data` volume.

Important files:

- `srcs/requirements/wordpress/Dockerfile`
- `srcs/requirements/wordpress/tools/start.sh`

### mariadb

`mariadb` is the database service used by WordPress. It initializes the database, creates the configured database user, grants privileges, and stores data in the persistent `mariadb_data` volume.

Why it is useful:

- Keeps website data persistent and separate from application files.
- Allows WordPress to be recreated without losing database content.
- Provides a clear database backend for Adminer and the backup service.

Important files:

- `srcs/requirements/mariadb/Dockerfile`
- `srcs/requirements/mariadb/conf/mariadb-server.cnf`
- `srcs/requirements/mariadb/tools/start.sh`

### redis

`redis` is a bonus service used as a WordPress object cache.

Why it is useful:

- Reduces repeated database queries.
- Improves WordPress response time.
- Demonstrates an additional service connected through the Docker network.

Important files:

- `srcs/requirements/bonus/redis/Dockerfile`
- `srcs/requirements/bonus/redis/conf/redis.conf`

### ftp

`ftp` is a bonus service running `vsftpd`. It points to the WordPress files volume.

Why it is useful:

- Allows file transfer access to WordPress files.
- Demonstrates an extra service using an existing persistent volume.

Important files:

- `srcs/requirements/bonus/ftp/Dockerfile`
- `srcs/requirements/bonus/ftp/conf/vsftpd.conf`
- `srcs/requirements/bonus/ftp/tools/start.sh`

### static-web

`static-web` is a bonus static website generated with R and served by NGINX inside its own container. It is available through the main NGINX reverse proxy at `/web/`.

Why it is useful:

- Satisfies the static website bonus without using PHP.
- Demonstrates a multi-stage Docker build.
- Keeps the bonus site isolated from WordPress.

Important files:

- `srcs/requirements/bonus/static-web/Dockerfile`
- `srcs/requirements/bonus/static-web/site/index.Rmd`
- `srcs/requirements/bonus/static-web/tools/generate_web.R`

### adminer

`adminer` is a bonus database administration interface. It is available through the main NGINX reverse proxy at `/adminer/`.

Why it is useful:

- Makes it easier to inspect the MariaDB database during development and evaluation.
- Provides a simple web UI for database checks.

Important file:

- `srcs/requirements/bonus/adminer/Dockerfile`

### backup

`backup` is the free-choice bonus service. It periodically creates compressed backups of the MariaDB database and the WordPress files.

Why it is useful:

- Provides a recovery mechanism.
- Demonstrates a practical administrative service.
- Stores backup files in the `backup_data` volume.

Important files:

- `srcs/requirements/bonus/backup/Dockerfile`
- `srcs/requirements/bonus/backup/tools/start.sh`
- `srcs/requirements/bonus/backup/tools/backup.sh`

## Instructions

### 1. Prerequisites

Use a Linux virtual machine with:

- Docker Engine installed.
- Docker Compose plugin installed.
- `make` installed.
- Access to edit `/etc/hosts`.

### 2. Create `srcs/.env`

Create `srcs/.env` locally during evaluation. Do not commit real credentials.

Example:

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

The WordPress administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.

### 3. Configure the Local Domain

Add the project domain to `/etc/hosts`:

```sh
sudo sh -c 'echo "127.0.0.1 marcnava.42.fr" >> /etc/hosts'
```

### 4. Start the Project

```sh
make up
```

This command creates the host data directories, builds the images through Docker Compose, creates the network and volumes, and starts the containers.

### 5. Stop the Project

```sh
make down
```

### 6. Full Cleanup

```sh
make fclean
```

This removes Compose containers, volumes, orphan containers, and the persistent data directories configured by `DATA_PATH`.

### 7. Rebuild From Scratch

```sh
make re
```

## Makefile Commands

```sh
make up       # Build and start the complete stack
make build    # Build all Docker images
make down     # Stop and remove Compose containers
make restart  # Restart the project
make ps       # Show Compose service status
make logs     # Follow service logs
make clean    # Alias for down
make iclean   # Remove project images after stopping containers
make vclean   # Remove Compose containers and named volumes
make fclean   # Remove containers, volumes, orphans, and persistent data
make re       # Full cleanup and restart
```

## Evaluation Commands

The evaluation sheet asks for a clean Docker environment before running the project.
This command is destructive for all local Docker containers, images, volumes, and custom networks on the machine:

```sh
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

### Repository and File Checks

```sh
ls -la
ls -la srcs
find srcs -maxdepth 4 -type f | sort
find srcs/requirements -name Dockerfile -print
```

Expected:

- `Makefile` exists at repository root.
- `srcs/docker-compose.yml` exists.
- All Docker configuration is inside `srcs/`.
- Each service has a non-empty Dockerfile.

### Forbidden Configuration Checks

```sh
grep -R "network: host\|links:\|--link" -n Makefile srcs || true
grep -R "tail -f\|sleep infinity\|while true" -n srcs || true
grep -R "FROM .*:latest" -n srcs || true
```

Expected:

- No `network: host`.
- No `links:`.
- No `--link`.
- No infinite-loop process hacks.
- No `latest` tag in service Dockerfiles.

### Build and Status

```sh
make up
make ps
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env ps
```

Expected:

- All services are `Up`.
- Images are named like their services: `nginx:inception`, `wordpress:inception`, `mariadb:inception`, and bonus image names.

### Network Checks

```sh
docker network ls
docker network inspect inception_inception
```

Expected:

- A project network exists.
- Containers are attached to the project network.

### NGINX and TLS Checks

```sh
curl -I http://marcnava.42.fr
curl -k -I https://marcnava.42.fr
openssl s_client -connect marcnava.42.fr:443 -tls1_2 </dev/null
openssl s_client -connect marcnava.42.fr:443 -tls1_3 </dev/null
```

Expected:

- HTTP on port `80` must not serve the website.
- HTTPS on port `443` serves WordPress.
- TLSv1.2 or TLSv1.3 is available.
- A self-signed certificate warning is acceptable.

Open in a browser:

```text
https://marcnava.42.fr
https://marcnava.42.fr/wp-admin
```

The WordPress installation page must not appear.

### WordPress Checks

```sh
docker exec wordpress wp core is-installed --path=/var/www/html --allow-root
docker exec wordpress wp user list --path=/var/www/html --allow-root --fields=user_login,roles
docker exec wordpress wp option get siteurl --path=/var/www/html --allow-root
```

Expected:

- WordPress is installed.
- There are at least two users.
- The administrator username does not contain `admin`.

Manual browser checks:

- Log in with the regular WordPress user.
- Add a comment.
- Log in with the administrator account.
- Edit a page from the dashboard.
- Confirm the page changed on the website.

### WordPress Volume Checks

```sh
docker volume ls
docker volume inspect inception_wordpress_data
```

Expected:

- The volume exists.
- The inspect output contains `/home/marcnava/data/wordpress`.

### MariaDB Checks

```sh
set -a; . srcs/.env; set +a
docker exec mariadb mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -h 127.0.0.1 "$MYSQL_DATABASE" -e "SHOW TABLES;"
docker exec mariadb mariadb -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
```

Expected:

- The WordPress database exists.
- The database is not empty.
- WordPress tables are present.

### MariaDB Volume Checks

```sh
docker volume ls
docker volume inspect inception_mariadb_data
```

Expected:

- The volume exists.
- The inspect output contains `/home/marcnava/data/mariadb`.

### Persistence Check

1. Edit a WordPress page in the dashboard.
2. Reboot the virtual machine.
3. Start the project again:

```sh
make up
```

4. Open the website again:

```text
https://marcnava.42.fr
```

Expected:

- WordPress is still configured.
- MariaDB is still configured.
- The page edit made before reboot is still present.

## Bonus Validation

Bonus must be evaluated only if the mandatory part is fully correct.

### Redis

```sh
docker exec wordpress wp plugin is-active redis-cache --path=/var/www/html --allow-root
docker exec wordpress wp redis status --path=/var/www/html --allow-root
```

Expected:

- Redis plugin is active.
- Redis status is connected.

### FTP

```sh
set -a; . srcs/.env; set +a
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env ps ftp
curl --ftp-pasv -u "$FTP_USER:$FTP_PASSWORD" ftp://127.0.0.1/
```

Expected:

- FTP container is running.
- The WordPress files volume is reachable through FTP.

### Static Website

```sh
curl -k https://marcnava.42.fr/web/
```

Expected:

- The static R-generated website is served.

### Adminer

```sh
curl -k https://marcnava.42.fr/adminer/
```

Expected:

- Adminer login page is served.
- Use server `mariadb`, the configured database user, and the configured database password.

### Backup

```sh
docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env logs backup
docker exec backup ls -lh /backups
```

Expected:

- Database backups are created as `.sql.gz`.
- WordPress file backups are created as `.tar.gz`.

## Resources

- Docker documentation: https://docs.docker.com/
- Docker Compose documentation: https://docs.docker.com/compose/
- Dockerfile reference: https://docs.docker.com/reference/dockerfile/
- Docker volumes: https://docs.docker.com/engine/storage/volumes/
- Docker networking: https://docs.docker.com/engine/network/
- NGINX documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WordPress documentation: https://wordpress.org/documentation/
- WP-CLI documentation: https://wp-cli.org/
- Redis documentation: https://redis.io/docs/latest/
- Adminer documentation: https://www.adminer.org/
- vsftpd documentation: https://security.appspot.com/vsftpd.html
- Alpine Linux documentation: https://wiki.alpinelinux.org/

## AI Usage

AI was used as a productivity assistant to review the subject requirements, compare the repository structure with the evaluation checklist, and draft documentation.

All commands, explanations, and configuration descriptions were reviewed against the actual files in this repository. The implementation and final responsibility remain with the project author.
