#!/bin/bash

# Para mostrar los comandos que se van ejecutando
set -ex

# Actualizamos los repositorios
apt update
apt upgrade -y

# Instalamos el servidor web Apache
apt install apache2 -y

# Habilitamos el modulo rewrite
a2enmod rewrite

# Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available

#Instalamos todo lo necesario de PHP para configurar Moodle
apt install php libapache2-mod-php php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-fpm -y

# Instalamos MySQL-server
apt install mysql-server -y

# Reiniciamos el servicio de Apache
systemctl restart apache2