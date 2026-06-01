#!/bin/sh

set -e

# Keep the container alive by running nginx in the foreground
# CMD ["nginx", "-g", "daemon off;"]

if [ ! -f "/etc/nginx/ssl/nginx.crt" ]; then

	echo "-> Generating TLS certificates... "

	openssl req -x509 \
		-nodes \
		-days 365 \
		-newkey rsa:2048 \
		-keyout /etc/nginx/ssl/nginx.key \
		-out /etc/nginx/ssl/nginx.crt \
		-subj "/C=ES/ST=Madrid/L=Madrid/O=42/CN=${DOMAIN_NAME}"

	echo "-> Certificate generated for ${DOMAIN_NAME}"
else
	echo "The certificate already exists."

fi

exec nginx -g "daemon off;"
