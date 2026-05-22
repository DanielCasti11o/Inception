#!/bin/sh
set -e

# Solo inicializar si el datadir está vacío (primer arranque)
if [ ! -d "/var/lib/mysql/mysql" ]; then

mariadb-install-db --user=mysql --datadir=/var/lib/mysql
# Creamos un archivo sql para inyectar el usuario a la base  de datos lo primero
cat << EOF > /tmp/init.sql

USE mysql;
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD_FILE';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'wordpress.inception' IDENTIFIED BY '$MYSQL_PASSWORD_FILE';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'wordpress.inception';
FLUSH PRIVILEGES;

EOF

# /usr/bib/mysqld --> Ejecutamos el motor del deamon de MariaDB de la BBDD
# --user=mysql --> Con esto indicamos que no inicie con el usuario root
# --bootstrap --> Se enciende de forma aislada, temporal y silenciosa que únicamente lo que va a hacer es guardar los datos del init.sql en la BBDD
# < /tmp/init.sql --> Dice básicamente que el input que recibirá será el init.sql
/usr/bin/mysqld --user=mysql --bootstrap < /tmp/init.sql

# Una vez realizado el proceso del init, eliminamos el archivo innecesario.
rm -f /tmp/init.sql

fi

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld

# Arrancamos MariaDB de forma normal para mantener el contenedor vivo
exec /usr/bin/mysqld --user=mysql --console


