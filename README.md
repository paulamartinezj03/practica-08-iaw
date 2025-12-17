# practica-08-iaw
practica 08
# Configuramos el archivo de deploy_moodle.sh
## #!/bin/bash

## Mostrar los comandos que se van ejecutando 
set -ex

## Importamos las variables de entorno
source .env


## Eliminamos los archivos de instalaciones previas de Moodle de /var/www/html/moodle
rm -rf $MOODLE_DIR
rm -rf $MOODLE_DATA_DIR

## volvemos a crear
mkdir -p $MOODLE_DIR

mkdir -p $MOODLE_DATA_DIR


## Cambiamos el propietario de la carpeta para que sea propiedad del servidor y dar acceso al dueño de lectura, escritura y ejecución.
chown -R www-data:www-data $MOODLE_DIR


## Creamos la base de datos y el usuario para Moodle
mysql -u root <<< "DROP DATABASE IF EXISTS $MOODLE_DB_NAME"
mysql -u root <<< "CREATE DATABASE $MOODLE_DB_NAME"
mysql -u root <<< "DROP USER IF EXISTS $MOODLE_DB_USER@$IP_CLIENTE_MYSQL"
mysql -u root <<< "CREATE USER $MOODLE_DB_USER@$IP_CLIENTE_MYSQL IDENTIFIED BY '$MOODLE_DB_PASSWORD'"
mysql -u root <<< "GRANT ALL PRIVILEGES ON $MOODLE_DB_NAME.* TO $MOODLE_DB_USER@$IP_CLIENTE_MYSQL"


## Cambiamos las variables del archivo de php.ini tanto en la carpeta /apache2
## Configuración de max_input_vars necesaria para Moodle
echo "max_input_vars = 5000" | sudo tee -a /etc/php/8.3/apache2/php.ini
echo "max_input_vars = 5000" | sudo tee -a /etc/php/8.3/cli/php.ini

## Si la línea no existe, la añadimos
grep -q "max_input_vars" /etc/php/8.3/apache2/php.ini || echo "max_input_vars = 5000" | sudo tee -a /etc/php/8.3/apache2/php.ini

## Reiniciamos apache para que todos los cambios que hemos hecho durante la configuracion se guarden
systemctl reload apache2

## Clonamos el repositorio donde esta el codigo fuente de Moodle
git clone --branch MOODLE_405_STABLE --depth 1 https://github.com/moodle/moodle.git $MOODLE_DIR 

sudo chown -R www-data:www-data $MOODLE_DATA_DIR
sudo chmod -R 770 $MOODLE_DATA_DIR


sudo chown -R www-data:www-data $MOODLE_DIR
sudo find $MOODLE_DIR -type d -exec chmod 755 {} \;
sudo find $MOODLE_DIR -type f -exec chmod 644 {} \;


sudo -u www-data /usr/bin/php /var/www/html/admin/cli/install.php \
    --lang="es" \
    --wwwroot=$MOODLE_URL \
    --dataroot=$MOODLE_DATA_DIR \
    --dbtype=$MOODLE_DB_TYPE \
    --dbhost=$MOODLE_DB_HOST \
    --dbname=$MOODLE_DB_NAME \
    --dbuser=$MOODLE_DB_USER \
    --dbpass=$MOODLE_DB_PASSWORD \
    --non-interactive \
    --agree-license \
    --adminuser=$MOODLE_ADMIN_USER \
    --adminpass=$MOODLE_ADMIN_PASSWORD \
    --adminemail=$MOODLE_ADMIN_EMAIL \
    --fullname=$MOODLE_FULL \
    --shortname=$MOODLE_SHORT
\
# Configuramos install_lamp.sh
#!/bin/bash

## Para mostrar los comandos que se van ejecutando
set -ex

## Actualizamos los repositorios
apt update
apt upgrade -y

## Instalamos el servidor web Apache
apt install apache2 -y

## Habilitamos el modulo rewrite
a2enmod rewrite

## Copiamos el archivo de configuración de Apache
cp ../conf/000-default.conf /etc/apache2/sites-available

## Instalamos todo lo necesario de PHP para configurar Moodle
apt install php libapache2-mod-php php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-fpm -y

## Instalamos MySQL-server
apt install mysql-server -y

## Reiniciamos el servicio de Apache
systemctl restart apache2

# Configuramos setup_letsencrypt_https.sh
#!/bin/bash
set -ex

## Enlazamos con el fichero de variables de entorno
source .env

## Realizamos la instalación y actualización de snapd.
snap install core
snap refresh core

## Copiamos la plantilla del archivo de configuración de apache
cp ../conf/000-default.conf /etc/apache2/sites-available/000-default.conf

## Con el comando sed sustituimos el dominio en el archivo de configuración de apache
sed -i "s/PUT_YOUR_DOMAIN_HERE/$CERTBOT_DOMAIN/" /etc/apache2/sites-available/000-default.conf

## Eliminamos si existiese alguna instalación previa de certbot con apt.
apt remove certbot -y

## Instalamos el cliente de Certbot con snapd.
snap install --classic certbot

## Obtenemos el certificado y configuramos el servidor web Apache.
certbot --apache -m $CERTBOT_EMAIL --agree-tos --no-eff-email -d $CERTBOT_DOMAIN --non-interactive
