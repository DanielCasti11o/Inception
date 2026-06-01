# Inception — User Documentation

## Services Overview

The **Inception** stack provides three core services that run in dedicated Docker containers:

| Service | Role | Technology |
|---------|------|------------|
| **NGINX** | Reverse proxy and TLS termination | NGINX + OpenSSL (TLSv1.2 / TLSv1.3 only) |
| **WordPress** | Content management system | WordPress + PHP-FPM |
| **MariaDB** | Relational database | MariaDB |

- NGINX is the **only entry point** to the infrastructure, exposed on **port 443 (HTTPS)**.
- WordPress and MariaDB are **not exposed** to the host — they communicate internally through a dedicated Docker bridge network.
- Two named Docker volumes provide persistence: one for the WordPress site files and another for the MariaDB database.

## Starting and Stopping the Project

All interactions are done via the **Makefile** at the root of the repository.

### Start the project

```sh
make
```

This runs `make dirs`, `make build`, and `make up` in sequence:
1. Creates the host data directories (`/home/dacastil/data/wordpress` and `/home/dacastil/data/mariadb`).
2. Builds the three Docker images from the local Dockerfiles.
3. Launches all containers in the background.

Alternatively, run each step separately:

```sh
make dirs      # Create persistent data directories
make build     # Build the Docker images
make up        # Start all containers in detached mode
```

### Stop the project

```sh
make down
```

Stops and removes all containers while preserving the volumes (your data is kept).

### Restart from scratch

```sh
make re
```

Runs `make fclean` (removes all containers, images, and volumes) followed by `make all`.

### Clean everything

```sh
make fclean
```

Removes all stopped containers, unused images, and **all volumes** (data will be lost).

## Accessing the Website

Open your browser and go to:

```
https://dacastil.42.fr
```

> **Important:** Because the TLS certificate is self-signed, your browser will show a security warning. This is expected for a development/local environment. Proceed by accepting the risk / adding an exception.

### WordPress Administration Panel

Navigate to:

```
https://dacastil.42.fr/wp-admin
```

The **administrator** credentials are:
- **Username:** `webmaster`
- **Password:** stored in `srcs/secrets/wp_admin_passwd.txt`

> **Note:** The administrator username intentionally avoids the words `admin`, `Administrator`, or any variation thereof, as required by the project specification.

### WordPress Editor (Second User)

A second user with the **author** role is pre-created:
- **Username:** `editor`
- **Password:** stored in `srcs/secrets/wp_passwd.txt`

## Locating and Managing Credentials

Credentials are stored in two places:

### 1. Docker Secrets (runtime secrets)

| Secret file | Content |
|-------------|---------|
| `srcs/secrets/db_password.txt` | MariaDB application user password |
| `srcs/secrets/db_root_password.txt` | MariaDB root password |
| `srcs/secrets/wp_passwd.txt` | WordPress second user password |
| `srcs/secrets/wp_admin_passwd.txt` | WordPress administrator password |

These files are **not tracked by Git** (they are listed in `.gitignore`). They are mounted inside the containers at `/run/secrets/` at runtime.

### 2. Environment variables (non-sensitive configuration)

The file `srcs/.env` holds non-sensitive configuration such as the domain name, WordPress title, and usernames. This file is also git-ignored.

### How to change a password

1. Edit the corresponding file under `srcs/secrets/`.
2. Run `make down && make up` to restart the stack with the new credentials.

> **Note:** Changing the MariaDB passwords after the database has been initialized requires manual intervention inside the database.

## Checking Service Status

### Container status

```sh
make status
```

Shows the running state of all containers.

### Detailed container information

```sh
docker compose -f srcs/docker-compose.yml ps
```

### View logs

```sh
make logs
```

Follows the logs of all services in real time. Press `Ctrl+C` to stop following.

### Check specific container logs

```sh
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### Verify TLS

```sh
curl -vI https://dacastil.42.fr
```

### Verify MariaDB connectivity

```sh
docker compose -f srcs/docker-compose.yml exec mariadb mariadb -u pwuser -p
```

Enter the password from `srcs/secrets/db_password.txt` when prompted.
