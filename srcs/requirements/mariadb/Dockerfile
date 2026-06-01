FROM alpine:3.19

# Install MariaDB and clean cache in the same layer
RUN apk update && \
	apk add --no-cache mariadb mariadb-client && \
	rm -rf /var/cache/apk/*

# Copy MariaDB configuration file
COPY conf/.conf /etc/my.cnf.d/.conf

# Copy entrypoint script
COPY tools/entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Data directory for the database engine and its tables/users

RUN mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/lib/mysql

EXPOSE 3306

# Run the entrypoint script: initializes the DB, starts MariaDB,
# and restricts connections to the WordPress container only
ENTRYPOINT ["/entrypoint.sh"]

