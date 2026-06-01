FROM alpine:3.19

RUN apk update && apk add --no-cache \
    php83 \
    netcat-openbsd \
    php83-phar \
    php83-fpm \
    mariadb-client \
    php83-mysqli \
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

RUN adduser -S -G www-data -H -D www-data

# WP-CLI — command-line tool for WordPress
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

RUN ln -s /usr/bin/php83 /usr/bin/php
RUN ln -s /etc/php83 /etc/php

RUN sed -i 's/memory_limit = 128M/memory_limit = 512M/g' /etc/php83/php.ini

# Site root — the volume is mounted here; all HTML files are created under this path
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# php-fpm pool configuration
COPY conf/www.conf /etc/php83/php-fpm.d/www.conf

# Entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# php-fpm listens on 9000 — only visible inside the Docker network
EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
