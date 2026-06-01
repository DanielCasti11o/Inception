FROM alpine:3.19

# Install nginx and openssl (TLS certificates)
RUN apk update && apk add --no-cache \
    nginx \
    openssl && \
    rm -rf /var/cache/apk/*


# Directory for the TLS certificate
RUN mkdir -p /etc/nginx/ssl


# NGINX configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Entrypoint script — generates the certificate and starts nginx
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Only port exposed to the outside — HTTPS only
EXPOSE 443


ENTRYPOINT ["/entrypoint.sh"]

