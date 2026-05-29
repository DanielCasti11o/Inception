#!/bin/sh
set -e

echo " Initializing the script of configuration of WordPress..."


cd /var/www/html

MYSQL_PASSWORD=$(cat "$MYSQL_PASSWORD_FILE")
WP_ADMPASSWD=$(cat "$WP_ADMPASSWD_FILE")
WP_USPASSWD=$(cat "$WP_USPASSWD_FILE")

if [ ! -f "wp-config.php" ]; then
    echo "'wp-config.php' is not found. Starting fresh installation of WordPress..."

    wp core download --locale=es_ES --force --allow-root

    echo "Waiting for MariaDB to be ready..."
    while ! nc -z mariadb 3306; do
      sleep 1
    done
    echo "MariaDB is up! Proceeding with WordPress installation..."

    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost="mariadb" \
        --allow-root
fi

echo "Waiting for MariaDB to accept database queries..."
while ! wp db check --allow-root; do
    sleep 1
done
echo "MariaDB is fully ready!"

if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress is not installed. Installing..."

    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE:-Inception}" \
        --admin_user="${WP_ADMIN_USER:-admin}" \
        --admin_password="${WP_ADMPASSWD}" \
        --admin_email="${WP_ADMIN_EMAIL:-admin@42.fr}" \
        --skip-email \
        --allow-root

    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USPASSWD}" \
        --allow-root

    echo "WordPress installation complete!"
else
    echo "WordPress is already installed."
fi

chown -R www-data:www-data /var/www/html
echo "Starting PHP-FPM in background..."
exec php-fpm83 -F
