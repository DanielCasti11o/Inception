FROM alpine:3.19

# Instalamos MariaDB y limpiamos caché en la misma capa.
RUN apk update && \
	apk add --no-cache mariadb mariadb-client && \
	rm -rf /var/cache/apk/*

# Copiar el .conf
COPY conf/.conf /etc/my.cnf.d/.conf

# Copiar el script ENTRYPOINT.SH
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Volumenes de datos (VIVOS)

RUN mkdir -p /var/lib/mysql
    chown -R mysql:mysql /var/lib/mysql
# siendo /var/lib/mysql la ruta del directorio dónde estará el motor de la base
# de datos y dónde se guardaran las tablas y usuarios.

EXPOSE 3306

# Esto corre el script de entrypoint.sh dónde lo que haremos es
# inicializar la BD y lanza mysql y definir que solo se puede conectar
# a través del contenedor de WordPress.
ENTRYPOINT ["/entrypoint.sh"]

