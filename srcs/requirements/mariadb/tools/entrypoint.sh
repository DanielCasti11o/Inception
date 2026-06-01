#!/bin/sh
set -e

# Only initialize if the datadir is empty (first boot)
if [ ! -d "/var/lib/mysql/mysql" ]; then

mariadb-install-db --user=mysql --datadir=/var/lib/mysql
# Create a temporary SQL file to initialize the database and users
cat << EOF > /tmp/init.sql

USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$(cat "$MYSQL_ROOT_PASSWORD_FILE")';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '$(cat "$MYSQL_PASSWORD_FILE")';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;

EOF

# /usr/bin/mysqld --user=mysql       → run the MariaDB engine as the mysql user
# --bootstrap                       → start in bootstrap mode (isolated, temporary) to apply init.sql
# < /tmp/init.sql                   → feed the SQL file as input
/usr/bin/mysqld --user=mysql --bootstrap < /tmp/init.sql

# Clean up the temporary SQL file
rm -f /tmp/init.sql

fi

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Start MariaDB normally to keep the container alive
exec /usr/bin/mysqld --user=mysql --console --bind-address=0.0.0.0 --port=3306 --skip-networking=0

