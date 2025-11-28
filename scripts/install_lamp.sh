#!/bin/bash
set -ex
#Actualizamos los repositorios
apt update
#Actualizamos los paquetes del sistema
apt upgrade -y
#Instalación servidor apache
apt install apache2 -y
#Habilitaremos el módulo rewrite de Apache
a2enmod rewrite
#Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available
#Reiniciaremos apache2
systemctl restart apache2
#Instalamos PHP
sudo apt install php libapache2-mod-php php-mysql -y
#Copiamos archivo index.php a /var/www/html
cp ../php/index.php /var/www/html
#Cambiamos el propietario del directorio
chown -R www-data:www-data /var/www/html
#Reiniciaremos apache2
systemctl restart apache2
#Instalación de mysql server
sudo apt install mysql-server -y