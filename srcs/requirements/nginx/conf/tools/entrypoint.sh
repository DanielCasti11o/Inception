#!/bin/sh

set -e

# Con este cmd no se apagará el contenedor
#CMD ["nginx", "-g", "daemon off;"]

if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then

	echo "-> Generating TLS certificates... "

	openssl req -x509 \
		-nodes \
		-days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=${DOMAIN_NAME}"

	echo "-> Certificate generate to ${DOMAIN_NAME}"
else
	echo "The certificate already exists."

exec nginx -g "daemon off;"
