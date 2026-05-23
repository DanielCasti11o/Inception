FROM alpine:3.19

#instalamos los paquetes de nginx(servidor) y openssl(Certificados SSL)
RUN apk update && apk add --no-cache \
    nginx \
    openssl && \
    rm -rf /var/cache/apk/*


# Directorio para el certificado TLS
RUN mkdir -p /etc/nginx/ssl


# Configuración de NGINX
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Script que genera el certificado y arranca nginx
COPY tools/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Único puerto expuesto al exterior — solo HTTPS
EXPOSE 443


ENTRYPOINT ["/entrypoint.sh"]

