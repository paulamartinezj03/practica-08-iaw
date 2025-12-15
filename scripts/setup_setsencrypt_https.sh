#!/bin/bash
set -ex

#enlazamos con el fichero de variables de entorno
source .env

# Realizamos la instalación y actualización de snapd.
snap install core
snap refresh core

# copiamos la plantilla del archivo de configuración de apache
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf

# con el comando sed sustituimos el dominio en el archivo de configuración de apache
sed -i "s/PUT_YOUR_DOMAIN_HERE/$CERTBOT_DOMAIN/" /etc/apache2/sites-available/000-default.conf

# Eliminamos si existiese alguna instalación previa de certbot con apt.
apt remove certbot -y

# Instalamos el cliente de Certbot con snapd.
snap install --classic certbot

# Obtenemos el certificado y configuramos el servidor web Apache.
certbot --apache -m $CERTBOT_EMAIL --agree-tos --no-eff-email -d $CERTBOT_DOMAIN --non-interactive