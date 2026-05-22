FROM alpine 3.19

RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-mysqli       # conexión con MariaDB
    php83-json \
    php83-curl \
    php83-dom \
    php83-exif \
    php83-fileinfo \
    php83-mbstring \
    php83-openssl \
    php83-xml \
    php83-zip \
    wget \
    unzip && \
    rm -rf /var/cache/apk/*

# WP-CLI — herramienta de línea de comandos para WordPress
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp


# Directorio raíz del sitio — el volumen se monta aquí
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Configuración de php-fpm
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

# Script de arranque
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# php-fpm escucha en 9000 — solo visible dentro de la red Docker
EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
