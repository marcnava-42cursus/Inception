# USER_DOC

## Provided services
This stack provides:
- `nginx`: HTTPS reverse proxy and public entrypoint on port `443`.
- `wordpress`: CMS application served through PHP-FPM.
- `mariadb`: database backend for WordPress.

## Start and stop the project
- Start/build everything:
  - `make up`
- Stop containers:
  - `make down`
- Restart:
  - `make restart`
- Remove containers and volumes:
  - `make fclean`

## Access the website and admin panel
1. Ensure your domain resolves locally (example):
   - Add `127.0.0.1 marcnava.42.fr` to `/etc/hosts`.
2. Open:
   - Website: `https://marcnava.42.fr`
   - Admin panel: `https://marcnava.42.fr/wp-admin`

## Credentials location and management
- Runtime variables are read from `srcs/.env`.
- Do not commit `srcs/.env` to Git.
- Start from the template:
  - `cp srcs/.env.example srcs/.env`
- Data persistence base path is controlled by `DATA_PATH` in `srcs/.env` (`../data` for project-root local tests, or `/home/<login>/data` for strict subject mode).
- Optional local secret files can be stored in `secrets/` (ignored by Git).

## How to check services are healthy
- Container status:
  - `make ps`
- Follow logs:
  - `make logs`
- Direct Docker check:
  - `docker compose -p inception -f srcs/docker-compose.yml --env-file srcs/.env ps`

If WordPress is not reachable, first verify `mariadb` is running and that DB credentials in `srcs/.env` are consistent.
