*This project has been created as part of the 42 curriculum by dacastil.*

## Description

**Inception** is a system administration project that consists of setting up a small infrastructure of Dockerized services. The stack runs three interconnected services — NGINX, WordPress + PHP-FPM, and MariaDB — each in its own dedicated container, orchestrated with Docker Compose and built from custom Alpine-based Dockerfiles.

The goal is to gain hands-on experience with containerization, service isolation, secure communication via TLS, persistent data management with volumes, and the use of Docker secrets for credential management.

## Instructions

### Prerequisites

- Docker (with the Compose plugin v2 or later)
- Make

### Setup

1. Clone the repository:
   ```sh
   git clone <repo-url> inception
   cd inception
   ```

2. Configure the environment variables in `srcs/.env`:
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

3. Create the secret files under `srcs/secrets/`:
   ```sh
   mkdir -p srcs/secrets
   echo "your_db_password"       > srcs/secrets/db_password.txt
   echo "your_db_root_password"  > srcs/secrets/db_root_password.txt
   echo "your_wp_admin_password" > srcs/secrets/wp_admin_passwd.txt
   echo "your_wp_user_password"  > srcs/secrets/wp_passwd.txt
   ```

4. Build and start the stack:
   ```sh
   make
   ```

5. Access the website at `https://dacastil.42.fr` and the admin panel at `https://dacastil.42.fr/wp-admin`.

### Makefile targets

| Target | Description |
|--------|-------------|
| `make` | Full build and start |
| `make build` | Build the Docker images |
| `make up` | Start the containers |
| `make down` | Stop and remove containers (data persists) |
| `make status` | Show container status |
| `make logs` | Follow container logs |
| `make fclean` | Full cleanup (containers, images, volumes) |
| `make re` | Full rebuild from scratch |

## Project Description

### Architecture

The infrastructure is composed of three Docker containers connected through a dedicated bridge network:

- **NGINX** — Acts as the single entry point, terminating TLSv1.2/TLSv1.3 on port 443 and proxying PHP requests to WordPress.
- **WordPress + PHP-FPM** — Serves the CMS. PHP-FPM listens on port 9000 inside the Docker network. WordPress is installed and configured via WP-CLI at startup.
- **MariaDB** — Stores the WordPress database. Listens on port 3306, only accessible from within the Docker network.

All images are built **from Alpine 3.19** (penultimate stable version), and each image is named after its corresponding service. No pre-built images are pulled from Docker Hub except the base Alpine image.

### Directory structure

```
.
├── Makefile
├── srcs/
│   ├── .env
│   ├── docker-compose.yml
│   ├── secrets/
│   │   ├── db_password.txt
│   │   ├── db_root_password.txt
│   │   ├── wp_admin_passwd.txt
│   │   └── wp_passwd.txt
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── conf/nginx.conf
│       │   └── tools/entrypoint.sh
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── conf/www.conf
│       │   └── tools/entrypoint.sh
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/.conf
│           └── tools/entrypoint.sh
```

### Main design choices

- **Alpine Linux** as the base image for all containers, chosen for its small footprint and security surface.
- **Self-signed TLS certificates** generated at container startup via OpenSSL, suitable for a local/development environment.
- **Docker secrets** for all passwords, mounted at `/run/secrets/` inside containers, never exposed in environment variables or process listings.
- **Entrypoint scripts** that initialize services on first run (generate TLS certs, install WordPress, bootstrap the MariaDB database) and then hand off to the main process using `exec`.
- **Restart policy** set to `always` so containers recover automatically from crashes.
- The **WordPress admin username** (`webmaster`) avoids the words `admin`, `administrator`, or any variation thereof, as required by the project specification.
- The **`latest` tag is never used** — images are referenced by their build context.

### Virtual Machines vs Docker

| Aspect | Virtual Machine | Docker Container |
|--------|----------------|------------------|
| OS | Full guest OS with its own kernel | Shares the host kernel |
| Isolation | Hardware-level via hypervisor | Process-level via kernel namespaces |
| Boot time | Minutes | Seconds |
| Image size | Gigabytes | Megabytes |
| Resource usage | Higher (full OS overhead) | Lower (only the application and its dependencies) |
| Portability | Hypervisor-dependent | Runs on any system with Docker |

Docker containers are more lightweight and faster to start, making them ideal for microservices architectures. Virtual machines provide stronger isolation boundaries by running a separate kernel, which is better suited for multi-tenant environments with untrusted workloads.

### Secrets vs Environment Variables

| Aspect | Environment Variables | Docker Secrets |
|--------|----------------------|----------------|
| Visibility | Visible in `docker inspect`, process listings, and logs | Only accessible inside the container via `/run/secrets/` |
| Persistence | Stored in the container config (can leak in images) | Stored in the Docker Swarm / Compose encrypted store |
| Security | Lower — can be read by any process inside the container | Higher — mounted as a tmpfs, never stored in environment |
| Use case | Non-sensitive configuration (domain name, usernames) | Sensitive data (passwords, API keys) |

In this project, environment variables are used for non-sensitive configuration (e.g., `DOMAIN_NAME`, `WP_TITLE`, `MYSQL_USER`), while all passwords are stored as Docker secrets and passed to containers via secret files (mounted at `/run/secrets/`).

### Docker Network vs Host Network

| Aspect | Docker Bridge Network (default) | Host Network |
|--------|--------------------------------|--------------|
| Isolation | Containers have isolated network stack | Containers share the host network stack |
| Port mapping | Explicit `ports:` mapping required | Ports are exposed directly on the host |
| Security | Higher — services are isolated from the host and from each other | Lower — no network isolation |
| Flexibility | Custom DNS, network policies, and inter-container communication | Simpler but no network isolation |
| Requirement | Required by the project specification | Forbidden by the project (`network: host` is not allowed) |

This project uses a user-defined **bridge network** (`inception`) that provides DNS-based service discovery (containers can reach each other by service name, e.g., `wordpress:9000`). Only the NGINX container is exposed to the host (port 443). WordPress and MariaDB are internal-only.

### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|---------------|-------------|
| Management | Fully managed by Docker (`docker volume` commands) | Managed by the user on the host filesystem |
| Backup | `docker run --volumes-from` or volume drivers | Standard filesystem backup tools |
| Portability | Can be shared across containers and hosts with drivers | Path-dependent, less portable |
| Performance | Native performance | Native performance (same filesystem) |
| Project requirement | Named volumes **must** be used | Bind mounts (plain) are **not allowed** for the two persistent storages |

This project uses **Docker named volumes** with a bind-mount device option (`driver_opts`) pointing to `/home/dacastil/data/`. This fulfills the requirement of using named volumes while storing data at the specified host path. Two volumes are defined:
- `wp-files` — stores the WordPress site files at `/home/dacastil/data/wordpress`
- `mariadb-data` — stores the MariaDB database at `/home/dacastil/data/mariadb`

Both volumes persist across container restarts, rebuilds, and removals.

## Resources

### Official documentation

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose overview](https://docs.docker.com/compose/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [WordPress documentation](https://wordpress.org/documentation/)
- [WP-CLI handbook](https://make.wordpress.org/cli/handbook/)
- [MariaDB documentation](https://mariadb.com/kb/en/)
- [OpenSSL documentation](https://www.openssl.org/docs/)
- [Alpine Linux documentation](https://wiki.alpinelinux.org/)

### Tutorials and articles

- [Docker networking overview](https://docs.docker.com/network/)
- [Docker storage: volumes vs bind mounts](https://docs.docker.com/storage/)
- [Manage sensitive data with Docker secrets](https://docs.docker.com/compose/use-secrets/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [PID 1 and the init process in Docker](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#pid-1-and-the-init-process)

### How AI was used

AI (GitHub Copilot / Claude) was used as a support tool during the development of this project:
- **Dockerfile syntax and optimization** — verifying best practices for multi-layer builds and Alpine package selection.
- **Entrypoint script logic** — refining the MariaDB bootstrap and WordPress installation scripts.
- **Configuration files** — generating the initial NGINX config template and php-fpm pool configuration.
- **Documentation** — drafting and structuring the README, USER_DOC, and DEV_DOC files.
- **Troubleshooting** — debugging container startup issues, network connectivity between services, and secret mounting problems.

All AI-generated code was reviewed, tested, and adapted before being included in the project.
