#!/bin/bash

#Mostrar los comandos que se van ejecutando 
set -ex

# Importamos las variables de entorno
source .env

# Creamos la carpeta que va a hospedar la instalacion de Moodle
mkdir -p /var/www/html/moodle

#Eliminamos los archivos de instalaciones previas de Moodle de /var/www/html/moodle
rm -rf /var/www/html/*

# Clonamos el repositorio donde esta el codigo fuente de Moodle
git clone https://github.com/moodle/moodle.git $MOODLE_DIR

# Cambiamos el propietario de la carpeta para que sea propiedad del servidor y dar acceso al dueño de lectura, escritura y ejecución.
chown -R www-data:www-data $MOODLE_DIR
chmod -R 0755 $MOODLE_DIR

#Creamos la base de datos y el usuario para Moodle
mysql -u root <<< "DROP DATABASE IF EXISTS $MOODLE_DB_NAME"
mysql -u root <<< "CREATE DATABASE $MOODLE_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $MOODLE_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $MOODLE_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$MOODLE_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $MOODLE_DB_NAME.* TO $MOODLE_DB_USER@$IP_CLIENTE_MYSQL"

# Creamos un directorio fuera de la raíz web para mayor seguridad en /var/www/html/moodledata
mkdir -p $MOODLE_DATA_DIR

# Damos permisos a la carpeta /var/www/html/moodledata
chown -R www-data:www-data $MOODLE_DATA_DIR
chmod -R 777 $MOODLE_DATA_DIR

# Copiamos la configuracion del archivo config-dist.php a config.php
cp /var/www/html/moodle/config-dist.php /var/www/html/moodle/config.php 

#Cambiamos las variables que configuran la base de datos de Moodle 
sed -i "s/dbtype    = 'pgsql';/dbtype    = '$MOODLE_DB_TYPE';/" /var/www/html/moodle/config.php
sed -i "s/dbname    = 'moodle';/dbname    = '$MOODLE_DB_NAME';/" /var/www/html/moodle/config.php
sed -i "s/dbuser    = 'username';/dbuser    = '$MOODLE_DB_USER';/" /var/www/html/moodle/config.php
sed -i "s/dbpass    = 'password';/dbpass    = '$MOODLE_DB_PASSWORD';/" /var/www/html/moodle/config.php
sed -i "s#wwwroot   = 'http://example.com/moodle';#wwwroot    = '$MOODLE_URL';#" /var/www/html/moodle/config.php
sed -i "s#dataroot  = '/home/example/moodledata';#dataroot    = '$MOODLE_DATA_DIR';#" /var/www/html/moodle/config.php

#Cambiamos las variables del archivo de php.ini tanto en la carpeta /apache2 como en /cli
sed -i "s/;max_input_vars = 1000;/max_input_vars = 5000/" /etc/php/8.3/apache2/php.ini
sed -i "s/;extension=curl/extension=curl/" /etc/php/8.3/apache2/php.ini
sed -i "s/;extension=mysqli;/extension=mysqli/" /etc/php/8.3/apache2/php.ini
sed -i "s/;extension=openssl;/extension=openssl/" /etc/php/8.3/apache2/php.ini
sed -i "s/;extension=zip;/extension=zip/" /etc/php/8.3/apache2/php.ini

sed -i "s/;max_input_vars = 1000;/max_input_vars = 5000/" /etc/php/8.3/cli/php.ini
sed -i "s/;extension=curl/extension=curl/" /etc/php/8.3/cli/php.ini
sed -i "s/;extension=mysqli;/extension=mysqli/" /etc/php/8.3/cli/php.ini
sed -i "s/;extension=openssl;/extension=openssl/" /etc/php/8.3/cli/php.ini
sed -i "s/;extension=zip;/extension=zip/" /etc/php/8.3/cli/php.ini

# Reiniciamos apache para que todos los cambios que hemos hecho durante la configuracion se guarden
systemctl reload apache2