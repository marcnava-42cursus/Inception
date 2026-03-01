# DEV_DOC

## Environment setup from scratch

### Prerequisites
- Linux VM with Docker Engine and Docker Compose plugin installed.
- `make` installed.
- Your login domain mapped in `/etc/hosts` (for example `marcnava.42.fr`).

### Configuration files
1. Copy the template:
   - `cp srcs/.env.example srcs/.env`
2. Edit `srcs/.env` with real values:
   - Domain name.
   - MariaDB credentials.
   - WordPress admin/user credentials.
3. Optional: place local secret files in `secrets/` (ignored by Git).

## Build and launch workflow
- Build/start stack:
  - `make up`
- Stop stack:
  - `make down`
- Rebuild from scratch:
  - `make re`

Equivalent compose command:
- `docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env up -d --build`

## Useful management commands
- Show running services:
  - `make ps`
- Follow logs:
  - `make logs`
- Remove containers and orphan resources:
  - `make vclean`
- Full cleanup including volumes and persisted local data:
  - `make fclean`

## Data persistence and storage layout
- `mariadb_data` named volume -> `/var/lib/mysql` in the MariaDB container.
- `wordpress_data` named volume -> `/var/www/html` in WordPress container.
- For local testing, both volumes are configured to store data under project root:
  - `./data/mariadb`
  - `./data/wordpress`
- Host path base is controlled by `DATA_PATH` in `srcs/.env` (`../data` relative to `srcs/docker-compose.yml`).
- For defense in strict subject mode, set `DATA_PATH=/home/<login>/data` in `srcs/.env`.

This setup keeps persistent data outside container layers and survives container recreation.
