*This project has been created as part of the 42 curriculum by marcnava*

# Inception

## Description
Inception is a system administration project where a small web infrastructure is deployed with Docker Compose.
The mandatory stack contains:
- `nginx` as the only public entrypoint on port `443` with TLS.
- `wordpress` running with `php-fpm` (without nginx inside the container).
- `mariadb` as the database service.
- Two persistent named volumes for database data and WordPress files.
- One dedicated Docker bridge network for service-to-service communication.

## Project Description

### Why Docker is used here
Docker packages each service with its own runtime and dependencies, making the stack reproducible and portable.
This project also forces explicit infrastructure definition (`docker-compose.yml`, Dockerfiles, env files), which mirrors real deployment practices.

### Sources included in this repository
- `Makefile`: lifecycle commands (`up`, `down`, `logs`, `fclean`, etc.).
- `srcs/docker-compose.yml`: services, network, volumes, restart policy.
- `srcs/requirements/mariadb`: MariaDB image, config and init script.
- `srcs/requirements/wordpress`: WordPress + PHP-FPM image and bootstrap script.
- `srcs/requirements/nginx`: NGINX image and TLS-enabled virtual host config.
- `srcs/.env.example`: safe template for runtime environment variables.

### Main design choices and comparisons

#### Virtual Machines vs Docker
- Virtual Machines virtualize full operating systems and are heavier in CPU/RAM/storage usage.
- Docker containers share the host kernel and are faster to start and lighter to run.
- For this project, Docker makes multi-service orchestration and reproducibility simpler than VM-per-service.

#### Secrets vs Environment Variables
- Environment variables are easy for non-sensitive runtime config (domain, DB host, feature toggles).
- Secrets are preferable for sensitive values (passwords, keys) because they are not baked into images and can be mounted as files.
- This project keeps `.env` out of Git and provides `.env.example` for safe sharing.

#### Docker Network vs Host Network
- Docker bridge networks isolate services and provide internal DNS by service name.
- Host networking removes isolation and can create conflicts with host ports/processes.
- The project uses an explicit bridge network so containers communicate privately (`mariadb`, `wordpress`, `nginx`).

#### Docker Volumes vs Bind Mounts
- Named volumes are managed by Docker and are portable and easier to back up/inspect through Docker tooling.
- Bind mounts directly expose host paths and couple runtime data to host filesystem layout.
- The project uses named volumes with explicit host storage under `./data` (local testing mode).

## Instructions
1. Create a runtime env file from the template:
   - `cp srcs/.env.example srcs/.env`
   - Fill all required values.
2. (Optional) Place secret files in `secrets/` for local use.
3. Build and start all services:
   - `make up`
4. Check status and logs:
   - `make ps`
   - `make logs`
5. Stop services:
   - `make down`

### Data path mode
- Local testing mode (current): `DATA_PATH=../data` in `srcs/.env` -> persists under `./data`.
- Subject strict mode: set `DATA_PATH=/home/marcnava/data` in `srcs/.env`.

### Domain setup for local validation
Add your login domain to `/etc/hosts`:
- `127.0.0.1 marcnava.42.fr`

## Resources
- Docker documentation: https://docs.docker.com/
- Docker Compose specification: https://docs.docker.com/compose/compose-file/
- NGINX docs: https://nginx.org/en/docs/
- MariaDB docs: https://mariadb.com/kb/en/documentation/
- WordPress + WP-CLI docs: https://developer.wordpress.org/ and https://wp-cli.org/
- Alpine Linux docs: https://wiki.alpinelinux.org/

### AI usage in this project
AI was used as a productivity assistant for:
- Reviewing compose/service consistency against the assignment requirements.
- Detecting configuration mismatches and missing mandatory documentation files.
- Drafting and refining technical documentation structure.

All generated suggestions were manually reviewed, adapted to project constraints, and validated through local checks.
