# Inception — Developer Documentation

## Project Structure

```
.
├── Makefile                     # Build, run, and manage the project
├── USER_DOC.md                  # End-user documentation
├── DEV_DOC.md                   # Developer documentation
├── srcs/
│   ├── .env                     # Non-sensitive environment variables
│   ├── docker-compose.yml       # Service orchestration
│   ├── secrets/                 # Docker secret files (git-ignored)
│   │   ├── db_password.txt
│   │   ├── db_root_password.txt
│   │   ├── wp_admin_passwd.txt
│   │   └── wp_passwd.txt
│   └── requirements/
│       ├── nginx/               # NGINX + TLS
│       │   ├── Dockerfile
│       │   ├── conf/nginx.conf
│       │   └── tools/entrypoint.sh
│       ├── wordpress/           # WordPress + PHP-FPM
│       │   ├── Dockerfile
│       │   ├── conf/www.conf
│       │   └── tools/entrypoint.sh
│       └── mariadb/             # MariaDB database
│           ├── Dockerfile
│           ├── conf/.conf
│           └── tools/entrypoint.sh
```

## Prerequisites

- **Docker** and **Docker Compose** plugin (v2 or later)
- **Make**
- **Host data directories** are created automatically by `make dirs` at `/home/dacastil/data/`

### Verifying dependencies

```sh
docker --version
docker compose version
make --version
```

## Setting Up the Environment from Scratch

### 1. Clone the repository

```sh
git clone <repo-url> inception
cd inception
```

### 2. Configure environment variables

Edit `srcs/.env` to match your desired configuration:

```ini
DOMAIN_NAME=dacastil.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=pwuser
WP_TITLE=Dani_web
WP_ADMIN_USER=webmaster
WP_ADMIN_EMAIL=admin@dacastil.42.fr
WP_USER=editor
WP_USER_EMAIL=editor@dacastil.42.fr
```

### 3. Set up secrets

Create the secret files under `srcs/secrets/`:

```sh
mkdir -p srcs/secrets
echo "your_db_password"       > srcs/secrets/db_password.txt
echo "your_db_root_password"  > srcs/secrets/db_root_password.txt
echo "your_wp_admin_password" > srcs/secrets/wp_admin_passwd.txt
echo "your_wp_user_password"  > srcs/secrets/wp_passwd.txt
```

> **Security note:** The `srcs/secrets/` directory is listed in `.gitignore`. Never commit passwords to the repository. Use Docker secrets (mounted at `/run/secrets/` inside containers) rather than environment variables for sensitive data.

### 4. Update the domain name

If you change `DOMAIN_NAME` in `.env`, also update:
- `server_name` in `srcs/requirements/nginx/conf/nginx.conf`
- The `-subj` CN in `srcs/requirements/nginx/tools/entrypoint.sh`
- The `--url` parameter in `srcs/requirements/wordpress/tools/entrypoint.sh`

### 5. Update the data directory path

The host path for named volumes is defined in `srcs/docker-compose.yml`:

```yaml
volumes:
  wp-files:
    driver_opts:
      device: /home/dacastil/data/wordpress
  mariadb-data:
    driver_opts:
      device: /home/dacastil/data/mariadb
```

Change `dacastil` to your own login if you are not `dacastil`. Also update the `DATA_DIR` variable in the `Makefile`.

## Building and Launching

### Full build and start

```sh
make
```

This executes:
1. `make dirs` — creates `/home/dacastil/data/wordpress` and `/home/dacastil/data/mariadb` on the host.
2. `make build` — runs `docker compose build`, which reads each Dockerfile and builds the three images (`nginx`, `wordpress`, `mariadb`).
3. `make up` — runs `docker compose up -d` to start all containers in detached mode.

### Build only

```sh
make build
```

### Start only

```sh
make up
```

### Stop and remove containers (keep data)

```sh
make down
```

### Complete teardown (erase images and volumes)

```sh
make fclean
```

## Managing Containers and Volumes

### List running containers

```sh
docker compose -f srcs/docker-compose.yml ps
```

### Enter a container

```sh
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
```

### View logs

```sh
make logs                              # follow all logs
docker logs -f nginx                   # specific service
```

### Inspect volumes

```sh
docker volume ls
docker volume inspect inception_wp-files
docker volume inspect inception_mariadb-data
```

### View network

```sh
docker network ls
docker network inspect inception_inception
```

## Data Persistence

Two Docker **named volumes** provide persistent storage:

| Volume | Mount inside container | Host location |
|--------|----------------------|---------------|
| `inception_wp-files` | `/var/www/html` | `/home/dacastil/data/wordpress` |
| `inception_mariadb-data` | `/var/lib/mysql` | `/home/dacastil/data/mariadb` |

These are **bind-mounted** named volumes, which means the data lives directly on the host filesystem and survives container restarts, rebuilds, and removals. The volumes are created automatically by Docker Compose on first `make up`.

### Key design choices

- **Docker named volumes with bind propagation** are used instead of plain bind mounts to satisfy the requirement of storing data under `/home/login/data/` while keeping Docker volume semantics.
- The **bridge network** (`inception`) provides isolated communication between containers. Only NGINX is reachable from the host (port 443).
- **Secrets** are preferred over environment variables for passwords. They are stored in files and mounted at `/run/secrets/` inside containers, never exposed in the process list.
- Each service runs as a **non-root user** where possible (e.g., `www-data` for PHP-FPM, `mysql` for MariaDB).

## Useful Commands Reference

```sh
make                    # Build and start everything
make build              # Rebuild images
make up                 # Start containers
make down               # Stop and remove containers
make status             # Show container status
make logs               # Follow logs
make fclean             # Full cleanup (containers, images, volumes)
make re                 # Full rebuild (fclean + all)

docker compose -f srcs/docker-compose.yml config   # Validate compose file
docker compose -f srcs/docker-compose.yml images   # List built images
docker system df                                    # Show disk usage
```
