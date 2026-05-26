#!/bin/sh
set -e

echo " Initializing the script of configuration of WordPress..."


cd /var/www/html

MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
WP_ADMPASSWD=$(cat "$WP_ADMPASSWD_FILE")
WP_USPASSWD=$(cat "$WP_USPASSWD_FILE")

if [ ! -f "wp-config.php" ]; then
    echo "'wp-config.php' is not found. Starting fresh installation of WordPress..."

    # 1. Descargar los archivos limpios de WordPress
    # Esto se conecta a internet y baja el código fuente (carpetas wp-admin, wp-content, etc.)
    wp core download --locale=es_ES --force --allow-root

    echo "Waiting for MariaDB to be ready..."
    while ! nc -z mariadb 3306; do
      sleep 1
    done
    echo "MariaDB is up! Proceeding with WordPress installation..."
    # 2. Crear el archivo 'wp-config.php' (El puente con la base de datos)
    # Aquí es donde vinculamos WordPress con MariaDB usando las contraseñas que leímos de los secretos
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root

    echo "Waiting for MariaDB to accept database queries..."
    while ! wp db check --allow-root; do
      sleep 1
    done
    echo "MariaDB is fully ready!"
    # 3. Ejecutar la instalación interna de la web
    # Esto crea las tablas dentro de MariaDB y configura al usuario administrador de WordPress
    if ! wp core install \
        --url="https://dacastil.42.fr" \
        --title="${WP_TITLE:-Inception}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMPASSWD}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@42.fr}" \
        --skip-email \
        --allow-root 2> /tmp/wp_error.log; then
            echo "❌ ERROR EN WP CORE INSTALL:"
            cat /tmp/wp_error.log
            exit 1
    fi

    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USPASSWD}" \
        --allow-root
	echo "¡WordPress installation complete!"
else
    echo "'wp-config.php' is already configured."
fi

chown -R www-data:www-data /var/www/html
echo "Starting PHP-FPM in background..."
exec php-fpm83 -F
